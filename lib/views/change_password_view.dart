import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newPassword = _newController.text.trim();
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (!auth.isDirectSignIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password managed by external provider.')),
        );
        return;
      }
      await auth.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!auth.isDirectSignIn) ...[
                const Text(
                  'Your account is managed by an external provider. Use that provider to change your password.',
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _newController,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 8) return 'Password should be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm your password';
                  if (v != _newController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading || !auth.isDirectSignIn ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
