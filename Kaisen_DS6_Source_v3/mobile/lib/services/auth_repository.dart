import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usuario.dart';

enum AuthFailure {
  invalidCredentials,
  usernameAlreadyRegistered,
  invalidUsername,
  noConnection,
  configurationMissing,
  unexpected,
}

extension AuthFailureMessages on AuthFailure {
  String get userMessage => switch (this) {
        AuthFailure.invalidCredentials => 'Usuario o contraseña incorrectos.',
        AuthFailure.usernameAlreadyRegistered =>
          'Ese nombre de usuario ya está registrado.',
        AuthFailure.invalidUsername => 'El nombre de usuario no es válido.',
        AuthFailure.noConnection =>
          'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        AuthFailure.configurationMissing =>
          'Falta la configuración de Supabase.',
        AuthFailure.unexpected =>
          'Ocurrió un error de autenticación. Intenta de nuevo.',
      };
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.failure);

  final AuthFailure failure;

  String get userMessage => failure.userMessage;

  @override
  String toString() => 'AuthRepositoryException(${failure.name})';
}

class AuthSession {
  const AuthSession({required this.userId});

  final String userId;
}

class AuthIdentity {
  const AuthIdentity({required this.userId, required this.hasSession});

  final String userId;
  final bool hasSession;
}

abstract interface class AuthGateway {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<AuthIdentity> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });

  Future<AuthIdentity> signInWithPassword({
    required String email,
    required String password,
  });

  Future<Usuario> loadProfile(String userId);

  Future<void> signOut();
}

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<Usuario> register(String username, String password);

  Future<Usuario> login(String username, String password);

  Future<Usuario> loadProfile(String userId);

  Future<void> logout();
}

String normalizeUsername(String username) => username.trim().toLowerCase();

String buildInternalEmailAlias(String username) {
  final normalizedUsername = normalizeUsername(username);
  final digest = sha256.convert(utf8.encode(normalizedUsername)).toString();
  return 'u-$digest@auth.kaisen.invalid';
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    final override = _clientOverride;
    if (override != null) return override;

    try {
      return Supabase.instance.client;
    } on Object {
      throw StateError('Supabase is not initialized.');
    }
  }

  @override
  AuthSession? get currentSession {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return AuthSession(userId: session.user.id);
  }

  @override
  Stream<AuthSession?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((state) {
      final session = state.session;
      if (session == null) return null;
      return AuthSession(userId: session.user.id);
    });
  }

  @override
  Future<AuthIdentity> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Supabase did not return an authenticated user.');
    }
    return AuthIdentity(
      userId: user.id,
      hasSession: response.session != null,
    );
  }

  @override
  Future<AuthIdentity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Supabase did not return an authenticated user.');
    }
    return AuthIdentity(
      userId: user.id,
      hasSession: response.session != null,
    );
  }

  @override
  Future<Usuario> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, username, username_normalized')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Authenticated profile was not found.');
    }

    return Usuario.fromProfileMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({AuthGateway? gateway})
      : _gateway = gateway ?? SupabaseAuthGateway();

  final AuthGateway _gateway;

  @override
  AuthSession? get currentSession => _gateway.currentSession;

  @override
  Stream<AuthSession?> get authStateChanges => _gateway.authStateChanges;

  @override
  Future<Usuario> register(String username, String password) async {
    final visibleUsername = username.trim();
    _validateUsername(visibleUsername);

    try {
      final identity = await _gateway.signUp(
        email: buildInternalEmailAlias(visibleUsername),
        password: password,
        data: {'username': visibleUsername},
      );

      if (!identity.hasSession) {
        throw const AuthRepositoryException(AuthFailure.unexpected);
      }

      return await _gateway.loadProfile(identity.userId);
    } catch (error) {
      throw _mapError(error, duringLogin: false);
    }
  }

  @override
  Future<Usuario> login(String username, String password) async {
    final visibleUsername = username.trim();
    _validateUsername(visibleUsername);

    try {
      final identity = await _gateway.signInWithPassword(
        email: buildInternalEmailAlias(visibleUsername),
        password: password,
      );

      if (!identity.hasSession) {
        throw const AuthRepositoryException(AuthFailure.unexpected);
      }

      return await _gateway.loadProfile(identity.userId);
    } catch (error) {
      throw _mapError(error, duringLogin: true);
    }
  }

  @override
  Future<Usuario> loadProfile(String userId) async {
    try {
      return await _gateway.loadProfile(userId);
    } catch (error) {
      throw _mapError(error, duringLogin: true);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _gateway.signOut();
    } catch (error) {
      throw _mapError(error, duringLogin: true);
    }
  }

  void _validateUsername(String username) {
    final normalizedUsername = normalizeUsername(username);
    if (normalizedUsername.length < 3 || normalizedUsername.length > 128) {
      throw const AuthRepositoryException(AuthFailure.invalidUsername);
    }
  }

  AuthRepositoryException _mapError(
    Object error, {
    required bool duringLogin,
  }) {
    if (error is AuthRepositoryException) return error;

    final details = error.toString().toLowerCase();

    if (_containsAny(details, [
      'not initialized',
      'configuration',
      'missing supabase',
    ])) {
      return const AuthRepositoryException(AuthFailure.configurationMissing);
    }

    if (_containsAny(details, [
      'network',
      'connection',
      'failed host lookup',
      'socket',
      'timed out',
      'timeout',
      'fetch failed',
      'clientexception',
    ])) {
      return const AuthRepositoryException(AuthFailure.noConnection);
    }

    if (!duringLogin &&
        _containsAny(details, [
          'already registered',
          'already exists',
          'duplicate key',
          '23505',
        ])) {
      return const AuthRepositoryException(
        AuthFailure.usernameAlreadyRegistered,
      );
    }

    if (duringLogin &&
        _containsAny(details, [
          'invalid login credentials',
          'invalid credentials',
          'invalid_grant',
          'invalid password',
        ])) {
      return const AuthRepositoryException(AuthFailure.invalidCredentials);
    }

    return const AuthRepositoryException(AuthFailure.unexpected);
  }

  bool _containsAny(String value, List<String> fragments) {
    return fragments.any(value.contains);
  }
}
