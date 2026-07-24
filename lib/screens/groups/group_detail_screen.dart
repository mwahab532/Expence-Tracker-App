import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import 'package:flutter_expence_tracker/providers/group_member_provider.dart';
import 'package:flutter_expence_tracker/screens/groups/add_member_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String ownerUid;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.ownerUid,
  });

  @override
  Widget build(BuildContext context) {
    // Scoped locally to this group/screen — mirrors the pattern used by
    // AddEditExpenseController: this provider only makes sense for the
    // lifetime of viewing one specific group, not app-wide.
    return ChangeNotifierProvider(
      create: (ctx) => GroupMemberProvider(
        memberRepository: ctx.read<GroupMemberRepository>(),
        userDirectoryRepository: ctx.read<UserDirectoryRepository>(),
        ownerUid: ownerUid,
        groupId: groupId,
      ),
      child: _GroupDetailBody(groupName: groupName),
    );
  }
}

class _GroupDetailBody extends StatelessWidget {
  final String groupName;
  const _GroupDetailBody({required this.groupName});

  Future<void> _openAddMember(BuildContext context) async {
    final memberProvider = context.read<GroupMemberProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: memberProvider,
          child: const AddMemberScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroupMemberProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMember(context),
        tooltip: 'Add Member',
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.members.isEmpty
              ? const Center(child: Text('No members yet. Tap + to add someone.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = provider.members[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(m.displayName.isNotEmpty ? m.displayName : m.email),
                        subtitle: Text(m.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: 'Remove from group',
                          onPressed: () async {
                            final success = await provider.removeMember(m.uid);
                            if (!context.mounted) return;
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Failed to remove member')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
