import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/data/models/app_user_model.dart';
import 'package:flutter_expence_tracker/providers/group_member_provider.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _emailController = TextEditingController();
  AppUserModel? _found;
  bool _searched = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search(GroupMemberProvider provider) async {
    final result = await provider.searchByEmail(_emailController.text);
    if (!mounted) return;
    setState(() {
      _found = result;
      _searched = true;
    });
  }

  Future<void> _add(GroupMemberProvider provider) async {
    if (_found == null) return;
    final success = await provider.addMember(_found!);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_found!.displayName.isNotEmpty ? _found!.displayName : _found!.email} added')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to add member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupMemberProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search for a registered user by their account email.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    onSubmitted: (_) => _search(provider),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: provider.isSearching ? null : () => _search(provider),
                  child: provider.isSearching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_searched)
              _found == null
                  ? const Text('No registered user found with that email.')
                  : Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              _found!.photoUrl != null ? NetworkImage(_found!.photoUrl!) : null,
                          child: _found!.photoUrl == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(
                          _found!.displayName.isNotEmpty ? _found!.displayName : _found!.email,
                        ),
                        subtitle: Text(_found!.email),
                        trailing: FilledButton(
                          onPressed: provider.isAdding ? null : () => _add(provider),
                          child: provider.isAdding
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Add'),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
