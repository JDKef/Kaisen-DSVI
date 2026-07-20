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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final exito = await auth.registrar(
      _usuarioController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (exito) {
      Navigator.of(context).pop();
    } else {
      _showAuthError(auth.errorMessage ?? 'Error al registrar');
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
        registration: true,
        heroVariant: KaisenInventoryHeroVariant.zoneModules,
        sheetChild: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crear cuenta',
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
                'Completa la información para crear tu cuenta.',
                style: TextStyle(
                  color: KaisenAuthTokens.sheetSecondary,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: KaisenSpacing.space5),
              KaisenAuthField(
                controller: _usuarioController,
                label: 'Usuario',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                validator: (value) => (value == null || value.trim().length < 3)
                    ? 'Mínimo 3 caracteres'
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => (value == null || value.length < 4)
                    ? 'Mínimo 4 caracteres'
                    : null,
              ),
              const SizedBox(height: KaisenSpacing.space3),
              KaisenAuthField(
                controller: _confirmarController,
                label: 'Confirmar contraseña',
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmation,
                onToggleVisibility: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => value != _passwordController.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
              const SizedBox(height: KaisenSpacing.space5),
              KaisenAuthPrimaryButton(
                label: 'Registrarme',
                onPressed: _submit,
                busy: auth.cargando,
                loadingLabel: 'Creando cuenta',
              ),
              const SizedBox(height: KaisenSpacing.space2),
              SizedBox(
                height: KaisenSpacing.minimumTouchTarget,
                child: TextButton.icon(
                  onPressed: auth.cargando
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: KaisenAuthTokens.sheetText,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: const Text('Volver al inicio de sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
