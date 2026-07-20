import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisen/main.dart';
import 'package:kaisen/providers/auth_provider.dart';
import 'package:kaisen/services/auth_repository.dart';
import 'package:kaisen/widgets/auth/kaisen_auth_primary_button.dart';
import 'package:provider/provider.dart';

import 'support/fake_auth_repository.dart';

void main() {
  testWidgets('AuthGate muestra login sin sesión', (WidgetTester tester) async {
    final repository = FakeAuthRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(KaisenApp(authRepository: repository));

    expect(find.text('Kaisen'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Usuario'), findsOneWidget);
    expect(
      find.widgetWithText(KaisenAuthPrimaryButton, 'Iniciar sesión'),
      findsOneWidget,
    );
  });

  testWidgets('AuthGate muestra Dashboard con sesión restaurada', (
    WidgetTester tester,
  ) async {
    final repository = FakeAuthRepository(
      session: const AuthSession(userId: 'test-user-id'),
    );
    final auth = AuthProvider(repository: repository);
    addTearDown(auth.dispose);
    addTearDown(repository.close);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: auth,
          child: AuthGate(
            authenticatedBuilder: (_) => const Text('dashboard-route'),
            unauthenticatedBuilder: (_) => const Text('login-route'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('dashboard-route'), findsOneWidget);
  });
}
