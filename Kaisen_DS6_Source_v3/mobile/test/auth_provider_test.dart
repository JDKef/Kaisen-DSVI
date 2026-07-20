import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/providers/auth_provider.dart';
import 'package:kaisen/services/auth_repository.dart';

import 'support/fake_auth_repository.dart';

void main() {
  test('login exitoso actualiza el estado autenticado', () async {
    final repository = FakeAuthRepository();
    final auth = AuthProvider(repository: repository);
    addTearDown(() async {
      auth.dispose();
      await repository.close();
    });

    final result = await auth.iniciarSesion('Ana', 'password-real');

    expect(result, isTrue);
    expect(auth.estaAutenticado, isTrue);
    expect(auth.usuarioActual?.nombreUsuario, 'Usuario de prueba');
    expect(repository.lastLoggedInUsername, 'Ana');
    expect(repository.lastLoggedInPassword, 'password-real');
  });

  test('login fallido muestra un mensaje seguro y no autentica', () async {
    final repository = FakeAuthRepository(
      loginFailure: const AuthRepositoryException(
        AuthFailure.invalidCredentials,
      ),
    );
    final auth = AuthProvider(repository: repository);
    addTearDown(() async {
      auth.dispose();
      await repository.close();
    });

    final result = await auth.iniciarSesion('Ana', 'incorrecta');

    expect(result, isFalse);
    expect(auth.estaAutenticado, isFalse);
    expect(auth.errorMessage, 'Usuario o contraseña incorrectos.');
  });

  test('logout usa el repositorio y limpia el estado local', () async {
    final repository = FakeAuthRepository();
    final auth = AuthProvider(repository: repository);
    addTearDown(() async {
      auth.dispose();
      await repository.close();
    });

    await auth.iniciarSesion('Ana', 'password-real');
    await auth.cerrarSesion();

    expect(repository.logoutCalls, 1);
    expect(auth.estaAutenticado, isFalse);
    expect(auth.usuarioActual, isNull);
  });

  test('restaura el perfil cuando existe una sesión actual', () async {
    final repository = FakeAuthRepository(
      session: const AuthSession(userId: 'test-user-id'),
    );
    final auth = AuthProvider(repository: repository);
    addTearDown(() async {
      auth.dispose();
      await repository.close();
    });

    await Future<void>.delayed(Duration.zero);

    expect(auth.estaAutenticado, isTrue);
    expect(auth.usuarioActual?.authUserId, 'test-user-id');
  });
}
