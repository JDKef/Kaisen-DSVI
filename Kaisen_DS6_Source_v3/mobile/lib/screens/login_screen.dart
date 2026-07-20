import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/kaisen_colors.dart';
import '../theme/kaisen_radius.dart';
import '../theme/kaisen_spacing.dart';
import '../widgets/auth/kaisen_auth_field.dart';
import '../widgets/auth/kaisen_auth_layout.dart';
import '../widgets/auth/kaisen_auth_primary_button.dart';
import '../widgets/auth/kaisen_auth_tokens.dart';
import '../widgets/auth/kaisen_inventory_hero.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final exito = await auth.iniciarSesion(
      _usuarioController.text.trim(),
      _passwordController.text,
    );
    if (!exito && mounted) {
      _showAuthError(auth.errorMessage ?? 'Error al iniciar sesión');
    }
  }

  void _showAuthError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: KaisenColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KaisenRadius.panel),
          side: const BorderSide(color: KaisenColors.dangerBorder),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: KaisenColors.danger),
            const SizedBox(width: KaisenSpacing.space3),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: KaisenAuthTokens.heroBackground,
      resizeToAvoidBottomInset: true,
      body: KaisenAuthLayout(
        heroVariant: KaisenInventoryHeroVariant.storageStack,
        sheetChild: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Iniciar sesión',
                style: TextStyle(
                  color: KaisenAuthTokens.sheetText,
                  fontSize: 28,
                  height: 32 / 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: KaisenSpacing.space2),
              const Text(
                'Accede a tu cuenta para continuar gestionando tu inventario.',
                style: TextStyle(
                  color: KaisenAuthTokens.sheetSecondary,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: KaisenSpacing.space6),
              KaisenAuthField(
                controller: _usuarioController,
                label: 'Usuario',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa tu usuario'
                    : null,
              ),
              const SizedBox(height: KaisenSpacing.space3),
              KaisenAuthField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Ingresa tu contraseña'
                    : null,
              ),
              const SizedBox(height: KaisenSpacing.space5),
              KaisenAuthPrimaryButton(
                label: 'Iniciar sesión',
                onPressed: _submit,
                busy: auth.cargando,
                loadingLabel: 'Iniciando sesión',
              ),
              const SizedBox(height: KaisenSpacing.space2),
              SizedBox(
                height: KaisenSpacing.minimumTouchTarget,
                child: TextButton(
                  onPressed: auth.cargando
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: KaisenAuthTokens.sheetText,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
