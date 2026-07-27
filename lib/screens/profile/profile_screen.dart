import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  Future<void> _showEditDisplayNameDialog(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final controller = TextEditingController(
      text: auth.user?.displayName ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool saving = false;
          return AlertDialog(
            title: const Text('Edit Display Name'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    // ignore: dead_code
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        final success = await auth.updateDisplayName(
                          controller.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!success && ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ?? 'Failed to update name',
                              ),
                            ),
                          );
                        } else if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Display name updated'),
                            ),
                          );
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool saving = false;
          bool obscure = true;
          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Minimum 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    validator: (v) => v != newController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Show passwords'),
                    value: !obscure,
                    onChanged: (v) =>
                        setDialogState(() => obscure = !(v ?? false)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    // ignore: dead_code
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        final success = await auth.changePassword(
                          currentController.text,
                          newController.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!success && ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.errorMessage ??
                                    'Failed to change password',
                              ),
                            ),
                          );
                        } else if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated')),
                          );
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.displayName ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Display Name'),
            onTap: () => _showEditDisplayNameDialog(context, auth),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            onTap: () => _showChangePasswordDialog(context, auth),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: theme.themeMode == ThemeMode.dark,
            onChanged: (v) => theme.toggleTheme(v),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}
