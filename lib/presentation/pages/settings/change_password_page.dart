import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Sécurisez votre compte avec un nouveau mot de passe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Mot de passe actuel',
                hideValue: _hideCurrent,
                onToggleVisibility: () {
                  setState(() => _hideCurrent = !_hideCurrent);
                },
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Saisissez votre mot de passe actuel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Nouveau mot de passe',
                hideValue: _hideNew,
                onToggleVisibility: () {
                  setState(() => _hideNew = !_hideNew);
                },
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Saisissez un nouveau mot de passe';
                  }
                  if (text.length < 8) {
                    return 'Minimum 8 caractères';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(text) ||
                      !RegExp(r'[a-z]').hasMatch(text) ||
                      !RegExp(r'\d').hasMatch(text)) {
                    return 'Utilisez au moins une majuscule, une minuscule et un chiffre';
                  }
                  if (text == _currentPasswordController.text.trim()) {
                    return 'Le nouveau mot de passe doit être différent';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmer le nouveau mot de passe',
                hideValue: _hideConfirm,
                onToggleVisibility: () {
                  setState(() => _hideConfirm = !_hideConfirm);
                },
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Confirmez le nouveau mot de passe';
                  }
                  if (value!.trim() != _newPasswordController.text.trim()) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (authController.error != null &&
                  authController.error!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authController.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: authController.isLoading ? null : _submit,
                  icon: authController.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset),
                  label: Text(
                    authController.isLoading
                        ? 'Mise à jour...'
                        : 'Mettre à jour le mot de passe',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool hideValue,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hideValue,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(hideValue ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final success = await authController.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
