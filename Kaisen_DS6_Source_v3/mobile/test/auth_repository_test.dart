import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/models/usuario.dart';
import 'package:kaisen/services/auth_repository.dart';

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    this.signUpFailure,
    this.signInFailure,
    Usuario? profile,
  }) : profile = profile ??
            const Usuario(
              nombreUsuario: 'Ana',
              authUserId: 'user-1',
              nombreUsuarioNormalizado: 'ana',
            );

  final StreamController<AuthSession?> _authEvents =
      StreamController<AuthSession?>.broadcast();
  final Object? signUpFailure;
  final Object? signInFailure;
  final Usuario profile;

  AuthSession? session;
  String? signUpEmail;
  String? signUpPassword;
  Map<String, dynamic>? signUpData;
  String? signInEmail;
  String? signInPassword;
  String? profileUserId;

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSession?> get authStateChanges => _authEvents.stream;

  @override
  Future<AuthIdentity> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    signUpEmail = email;
    signUpPassword = password;
    signUpData = data;
    final failure = signUpFailure;
    if (failure != null) throw failure;
    session = const AuthSession(userId: 'user-1');
    return const AuthIdentity(userId: 'user-1', hasSession: true);
  }

  @override
  Future<AuthIdentity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInEmail = email;
    signInPassword = password;
    final failure = signInFailure;
    if (failure != null) throw failure;
    session = const AuthSession(userId: 'user-1');
    return const AuthIdentity(userId: 'user-1', hasSession: true);
  }

  @override
  Future<Usuario> loadProfile(String userId) async {
    profileUserId = userId;
    return profile;
  }

  @override
  Future<void> signOut() async {
    session = null;
    _authEvents.add(null);
  }

  Future<void> close() => _authEvents.close();
}

void main() {
  test('normaliza usernames y genera alias deterministas', () {
    expect(normalizeUsername('  Alice  '), 'alice');
    expect(
      buildInternalEmailAlias('  Alice  '),
      'u-2bd806c97f0e00af1a1fc3328fa763a9269723c8db8fac4f93af71db186d6e90'
      '@auth.kaisen.invalid',
    );
    expect(buildInternalEmailAlias('Alice'), buildInternalEmailAlias('alice'));
  });

  test('registro usa alias interno, contraseña real y metadata del username',
      () async {
    final gateway = _FakeAuthGateway();
    addTearDown(gateway.close);
    final repository = SupabaseAuthRepository(gateway: gateway);

    final profile = await repository.register('  Ana  ', 'password-real');

    expect(gateway.signUpEmail, buildInternalEmailAlias('ana'));
    expect(gateway.signUpPassword, 'password-real');
    expect(gateway.signUpData, {'username': 'Ana'});
    expect(gateway.profileUserId, 'user-1');
    expect(profile.nombreUsuario, 'Ana');
  });

  test('login deriva el mismo alias y carga el perfil autenticado', () async {
    final gateway = _FakeAuthGateway();
    addTearDown(gateway.close);
    final repository = SupabaseAuthRepository(gateway: gateway);

    final profile = await repository.login(' Ana ', 'password-real');

    expect(gateway.signInEmail, buildInternalEmailAlias('ana'));
    expect(gateway.signInPassword, 'password-real');
    expect(profile.authUserId, 'user-1');
  });

  test('credenciales inválidas de Supabase se mapean a español', () async {
    final gateway = _FakeAuthGateway(
      signInFailure: StateError('Invalid login credentials'),
    );
    addTearDown(gateway.close);
    final repository = SupabaseAuthRepository(gateway: gateway);

    final error = await _captureError(
      () => repository.login('Ana', 'incorrecta'),
    );

    expect(error.failure, AuthFailure.invalidCredentials);
    expect(error.userMessage, 'Usuario o contraseña incorrectos.');
  });

  test('username inválido se mapea a un error seguro', () async {
    final repository = SupabaseAuthRepository(gateway: _FakeAuthGateway());

    expect(
      () => repository.login(' a ', 'password-real'),
      throwsA(
        isA<AuthRepositoryException>().having(
          (error) => error.failure,
          'failure',
          AuthFailure.invalidUsername,
        ),
      ),
    );
  });

  test('registro duplicado se mapea sin exponer detalles de Supabase', () async {
    final gateway = _FakeAuthGateway(signUpFailure: StateError('User already registered'));
    addTearDown(gateway.close);
    final repository = SupabaseAuthRepository(gateway: gateway);

    final error = await _captureError(
      () => repository.register('Ana', 'password-real'),
    );

    expect(error.failure, AuthFailure.usernameAlreadyRegistered);
    expect(error.userMessage, 'Ese nombre de usuario ya está registrado.');
    expect(error.toString(), isNot(contains('already registered')));
  });
}

Future<AuthRepositoryException> _captureError(
  Future<Object?> Function() operation,
) async {
  try {
    await operation();
  } on AuthRepositoryException catch (error) {
    return error;
  }
  throw StateError('Expected AuthRepositoryException');
}
