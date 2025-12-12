import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'change_password_view.dart';
import 'delete_account_view.dart';

class AccountProfileView extends StatelessWidget {
  const AccountProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.user?.email ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ChangePasswordView(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account and data'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const DeleteAccountView(),
              ));
            },
          ),
        ],
      ),
    );
  }
}
