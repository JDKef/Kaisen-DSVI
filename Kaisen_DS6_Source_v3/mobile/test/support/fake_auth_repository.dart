import 'dart:async';

import 'package:kaisen/models/usuario.dart';
import 'package:kaisen/services/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSession? session,
    Usuario? profile,
    this.loginFailure,
    this.registrationFailure,
    this.logoutFailure,
    this.profileFailure,
  })  : _session = session,
        profile = profile ??
            const Usuario(
              nombreUsuario: 'Usuario de prueba',
              authUserId: 'test-user-id',
              nombreUsuarioNormalizado: 'usuario de prueba',
            );

  AuthSession? _session;
  final StreamController<AuthSession?> _authEvents =
      StreamController<AuthSession?>.broadcast();

  final Usuario profile;
  final Object? loginFailure;
  final Object? registrationFailure;
  final Object? logoutFailure;
  final Object? profileFailure;

  String? lastRegisteredUsername;
  String? lastRegisteredPassword;
  String? lastLoggedInUsername;
  String? lastLoggedInPassword;
  int logoutCalls = 0;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> get authStateChanges => _authEvents.stream;

  @override
  Future<Usuario> register(String username, String password) async {
    lastRegisteredUsername = username;
    lastRegisteredPassword = password;
    final failure = registrationFailure;
    if (failure != null) throw failure;
    _session = const AuthSession(userId: 'test-user-id');
    return profile;
  }

  @override
  Future<Usuario> login(String username, String password) async {
    lastLoggedInUsername = username;
    lastLoggedInPassword = password;
    final failure = loginFailure;
    if (failure != null) throw failure;
    _session = const AuthSession(userId: 'test-user-id');
    return profile;
  }

  @override
  Future<Usuario> loadProfile(String userId) async {
    final failure = profileFailure;
    if (failure != null) throw failure;
    return profile;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    final failure = logoutFailure;
    if (failure != null) throw failure;
    _session = null;
    _authEvents.add(null);
  }

  void emitSession(AuthSession? session) {
    _session = session;
    _authEvents.add(session);
  }

  Future<void> close() => _authEvents.close();
}
