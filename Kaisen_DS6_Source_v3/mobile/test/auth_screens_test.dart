import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/main.dart';
import 'package:kaisen/models/usuario.dart';
import 'package:kaisen/providers/auth_provider.dart';
import 'package:kaisen/screens/login_screen.dart';
import 'package:kaisen/screens/register_screen.dart';
import 'package:kaisen/services/auth_repository.dart';
import 'package:kaisen/theme/kaisen_theme.dart';
import 'package:kaisen/widgets/auth/kaisen_auth_layout.dart';
import 'package:kaisen/widgets/auth/kaisen_auth_primary_button.dart';
import 'package:kaisen/widgets/auth/kaisen_auth_sheet.dart';
import 'package:kaisen/widgets/auth/kaisen_auth_tokens.dart';
import 'package:kaisen/widgets/auth/kaisen_inventory_hero.dart';
import 'package:kaisen/widgets/auth/kaisen_operational_label.dart';
import 'package:kaisen/widgets/kaisen_loading_indicator.dart';
import 'package:kaisen/widgets/kaisen_logo_mark.dart';
import 'package:kaisen/widgets/kaisen_surface.dart';
import 'package:provider/provider.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('Login recreates the approved two-zone authentication concept', (
    WidgetTester tester,
  ) async {
    await _pumpAuthApp(tester, FakeAuthRepository());

    expect(find.byType(KaisenAuthLayout), findsOneWidget);
    expect(find.byType(KaisenOperationalLabel), findsOneWidget);
    expect(find.byType(KaisenInventoryHero), findsOneWidget);
    expect(find.byType(KaisenAuthSheet), findsOneWidget);
    expect(find.byType(KaisenLogoMark), findsOneWidget);
    expect(find.text('Control operativo'), findsOneWidget);
    expect(find.text('Kaisen'), findsOneWidget);
    expect(find.text('Sistema operativo de inventario'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNWidgets(2));
    expect(
      find.text('Accede a tu cuenta para continuar gestionando tu inventario.'),
      findsOneWidget,
    );
    expect(find.byType(KaisenSurface), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, KaisenAuthTokens.heroBackground);

    final heroHeight = tester
        .getSize(find.byKey(const ValueKey('kaisen-auth-hero-zone')))
        .height;
    final screenHeight = tester.view.physicalSize.height;
    expect(heroHeight / screenHeight, inInclusiveRange(0.40, 0.44));

    final sheet = tester.widget<Container>(
      find.byKey(const ValueKey('kaisen-auth-sheet')),
    );
    final decoration = sheet.decoration! as BoxDecoration;
    expect(decoration.color, KaisenAuthTokens.sheet);
    expect(decoration.borderRadius, isNotNull);
    expect(tester.getSize(find.byType(KaisenAuthPrimaryButton)).height, 56);
    expect(
      tester.getSize(find.widgetWithText(TextFormField, 'Usuario')).height,
      greaterThanOrEqualTo(54),
    );

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Authentication identity and controls keep useful semantics', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpAuthApp(tester, FakeAuthRepository());

    expect(find.bySemanticsLabel('Control operativo'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Representación operativa de módulos de inventario',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'Login fields, validation, and password visibility remain intact',
    (WidgetTester tester) async {
      await _pumpAuthApp(tester, FakeAuthRepository());

      final usernameField = find.widgetWithText(TextFormField, 'Usuario');
      final passwordField = find.widgetWithText(TextFormField, 'Contraseña');
      expect(usernameField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(_obscureTextFor(tester, passwordField), isTrue);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(_obscureTextFor(tester, passwordField), isFalse);
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);

      await tester.tap(_loginAction);
      await tester.pump();
      expect(find.text('Ingresa tu usuario'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    },
  );

  testWidgets('Successful login preserves the AuthGate flow and values', (
    WidgetTester tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpAuthApp(
      tester,
      repository,
      home: const AuthGate(
        authenticatedBuilder: _authenticatedDestination,
        unauthenticatedBuilder: _loginDestination,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      '  Ana  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password-real',
    );
    await tester.tap(_loginAction);
    await tester.pumpAndSettle();

    expect(repository.lastLoggedInUsername, 'Ana');
    expect(repository.lastLoggedInPassword, 'password-real');
    expect(find.text('authenticated-destination'), findsOneWidget);
  });

  for (final scenario in <(AuthFailure, String)>[
    (AuthFailure.invalidCredentials, 'Usuario o contraseña incorrectos.'),
    (
      AuthFailure.noConnection,
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
    ),
  ]) {
    testWidgets('Login preserves ${scenario.$1.name} safe feedback', (
      WidgetTester tester,
    ) async {
      final repository = FakeAuthRepository(
        loginFailure: AuthRepositoryException(scenario.$1),
      );
      await _pumpAuthApp(tester, repository);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usuario'),
        'Ana',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'incorrecta',
      );
      await tester.tap(_loginAction);
      await tester.pumpAndSettle();

      expect(find.text(scenario.$2), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  }

  testWidgets('Login loading remains visible without changing action height', (
    WidgetTester tester,
  ) async {
    final repository = _DeferredAuthRepository();
    await _pumpAuthApp(tester, repository);
    final initialHeight = tester
        .getSize(find.byType(KaisenAuthPrimaryButton))
        .height;

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Usuario'),
      'Ana',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'password-real',
    );
    await tester.tap(_loginAction);
    await tester.pump();

    expect(find.byType(KaisenLoadingIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Iniciando sesión'), findsOneWidget);
    expect(
      tester.getSize(find.byType(KaisenAuthPrimaryButton)).height,
      initialHeight,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    repository.loginCompleter.complete(repository.profile);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Login navigates to registration and the secondary link pops back',
    (WidgetTester tester) async {
      await _pumpAuthApp(tester, FakeAuthRepository());

      await _openRegistration(tester);
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(
        find.text('Completa la información para crear tu cuenta.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Volver al inicio de sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    },
  );

  testWidgets('Registration fields, validation, and visibility remain intact', (
    WidgetTester tester,
  ) async {
    await _pumpAuthApp(tester, FakeAuthRepository());
    await _openRegistration(tester);

    expect(find.byType(KaisenInventoryHero), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Usuario'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Confirmar contraseña'),
      findsOneWidget,
    );
    expect(find.byTooltip('Mostrar contraseña'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ab');
    await tester.enterText(fields.at(1), '123');
    await tester.enterText(fields.at(2), '456');
    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.text('Mínimo 3 caracteres'), findsOneWidget);
    expect(find.text('Mínimo 4 caracteres'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();
    expect(_obscureTextFor(tester, fields.at(1)), isFalse);
    expect(_obscureTextFor(tester, fields.at(2)), isTrue);
  });

  testWidgets('Registration success preserves pop and submitted values', (
    WidgetTester tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpAuthApp(tester, repository);
    await _openRegistration(tester);

    await _fillRegistration(tester, username: '  Ana  ');
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();

    expect(repository.lastRegisteredUsername, 'Ana');
    expect(repository.lastRegisteredPassword, 'password-real');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('Registration preserves duplicate-user safe feedback', (
    WidgetTester tester,
  ) async {
    final repository = FakeAuthRepository(
      registrationFailure: const AuthRepositoryException(
        AuthFailure.usernameAlreadyRegistered,
      ),
    );
    await _pumpAuthApp(tester, repository);
    await _openRegistration(tester);

    await _fillRegistration(tester);
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ese nombre de usuario ya está registrado.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('Registration keeps its blocking loading state visible', (
    WidgetTester tester,
  ) async {
    final repository = _DeferredAuthRepository();
    await _pumpAuthApp(tester, repository);
    await _openRegistration(tester);
    await _fillRegistration(tester);

    await tester.tap(find.text('Registrarme'));
    await tester.pump();

    expect(find.bySemanticsLabel('Creando cuenta'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    repository.registrationCompleter.complete(repository.profile);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'Small screens remain overflow-free and controls stay reachable',
    (WidgetTester tester) async {
      await _pumpAuthApp(
        tester,
        FakeAuthRepository(),
        size: const Size(320, 568),
        textScale: 1.3,
      );

      await tester.ensureVisible(find.text('¿No tienes cuenta? Regístrate'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Registrarme'));
      await tester.pump();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FilledButton)).height, 56);
    },
  );

  testWidgets('Keyboard insets keep login and registration actions reachable', (
    WidgetTester tester,
  ) async {
    await _pumpAuthApp(
      tester,
      FakeAuthRepository(),
      size: const Size(320, 568),
      viewInsets: const EdgeInsets.only(bottom: 220),
    );

    await tester.ensureVisible(_loginAction);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('¿No tienes cuenta? Regístrate'));
    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registrarme'));
    await tester.pump();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('Registrarme'), findsOneWidget);
  });

  testWidgets('Landscape uses the compact composition without overflow', (
    WidgetTester tester,
  ) async {
    await _pumpAuthApp(
      tester,
      FakeAuthRepository(),
      size: const Size(844, 390),
    );

    await tester.ensureVisible(_loginAction);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(KaisenAuthSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).height, 56);
  });
}

Widget _authenticatedDestination(BuildContext context) =>
    const Text('authenticated-destination');

Finder get _loginAction =>
    find.widgetWithText(KaisenAuthPrimaryButton, 'Iniciar sesión');

Widget _loginDestination(BuildContext context) => const LoginScreen();

Future<AuthProvider> _pumpAuthApp(
  WidgetTester tester,
  FakeAuthRepository repository, {
  Widget home = const LoginScreen(),
  Size size = const Size(390, 844),
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = AuthProvider(repository: repository);
  addTearDown(() async {
    auth.dispose();
    await repository.close();
  });

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: KaisenTheme.dark,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(textScale),
              viewInsets: viewInsets,
            ),
            child: child!,
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pump();
  return auth;
}

Future<void> _openRegistration(WidgetTester tester) async {
  await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
  await tester.pumpAndSettle();
  expect(find.byType(RegisterScreen), findsOneWidget);
}

Future<void> _fillRegistration(
  WidgetTester tester, {
  String username = 'Ana',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), username);
  await tester.enterText(fields.at(1), 'password-real');
  await tester.enterText(fields.at(2), 'password-real');
}

bool _obscureTextFor(WidgetTester tester, Finder field) {
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).obscureText;
}

class _DeferredAuthRepository extends FakeAuthRepository {
  final Completer<Usuario> loginCompleter = Completer<Usuario>();
  final Completer<Usuario> registrationCompleter = Completer<Usuario>();

  @override
  Future<Usuario> login(String username, String password) {
    lastLoggedInUsername = username;
    lastLoggedInPassword = password;
    return loginCompleter.future;
  }

  @override
  Future<Usuario> register(String username, String password) {
    lastRegisteredUsername = username;
    lastRegisteredPassword = password;
    return registrationCompleter.future;
  }
}
