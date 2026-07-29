import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import 'package:flutter_expence_tracker/data/models/group_expense_model.dart';
import 'package:flutter_expence_tracker/data/models/group_member_model.dart';
import 'package:flutter_expence_tracker/providers/group_member_provider.dart';
import 'package:flutter_expence_tracker/providers/group_expense_provider.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/screens/groups/add_member_screen.dart';
import 'package:flutter_expence_tracker/screens/groups/group_Expence.dart';

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
    // Scoped locally to this group/screen — these providers only make
    // sense for the lifetime of viewing one specific group, not app-wide.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => GroupMemberProvider(
            memberRepository: ctx.read<GroupMemberRepository>(),
            userDirectoryRepository: ctx.read<UserDirectoryRepository>(),
            ownerUid: ownerUid,
            groupId: groupId,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => GroupExpenseProvider(
            groupExpenseRepository: ctx.read<GroupExpenseRepository>(),
            ownerUid: ownerUid,
            groupId: groupId,
          ),
        ),
      ],
      child: _GroupDetailBody(groupName: groupName),
    );
  }
}

class _GroupDetailBody extends StatefulWidget {
  final String groupName;
  const _GroupDetailBody({required this.groupName});

  @override
  State<_GroupDetailBody> createState() => _GroupDetailBodyState();
}

class _GroupDetailBodyState extends State<_GroupDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Future<void> _openAddGroupExpense(
    BuildContext context, {
    GroupExpenseModel? expense,
  }) async {
    final expenseProvider = context.read<GroupExpenseProvider>();
    final memberProvider = context.read<GroupMemberProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: expenseProvider),
            ChangeNotifierProvider.value(value: memberProvider),
            ChangeNotifierProvider.value(value: categoryProvider),
          ],
          child: GroupAddEditExpenseScreen(expense: expense),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<GroupMemberProvider>();
    final expenseProvider = context.watch<GroupExpenseProvider>();
    final currency = NumberFormat.currency(symbol: '\$');
    final isMembersTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Expenses'),
          ],
        ),
        actions: [
          if (isMembersTab)
            IconButton(
              onPressed: () => _openAddMember(context),
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add Member',
            ),
        ],
      ),
      floatingActionButton: isMembersTab
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddGroupExpense(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          memberProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : memberProvider.members.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 40),
                    const Center(
                      child: Text(
                        'No members yet. Tap the person icon to add someone.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: memberProvider.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final m = memberProvider.members[i];
                    final owed = expenseProvider.totalsByMember[m.uid] ?? 0;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          m.displayName.isNotEmpty ? m.displayName : m.email,
                        ),
                        subtitle: Text(m.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (owed > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  currency.format(owed),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: 'Remove from group',
                              onPressed: () async {
                                final success = await memberProvider
                                    .removeMember(m.uid);
                                if (!context.mounted) return;
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        memberProvider.errorMessage ??
                                            'Failed to remove member',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // --- Expenses tab ---
          expenseProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : expenseProvider.expenses.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 50),
                    const Center(
                      child: Text('No group expenses yet. Tap + to add one.'),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenseProvider.expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = expenseProvider.expenses[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => expenseProvider.deleteExpense(e.id),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          title: Text(e.title),
                          subtitle: Text(
                            '${e.categoryName} • ${DateFormat.yMMMd().format(e.date)} • '
                            '${e.splitType == SplitType.custom ? "custom split" : "split ${e.contributorUids.length} ways"}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(e.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (e.splitType == SplitType.equal)
                                    Text(
                                      '${currency.format(e.perPersonAmount)} each',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () =>
                                    _openAddGroupExpense(context, expense: e),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Text(
                              'Contributors',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            for (final uid in e.contributorUids)
                              _ContributorRow(
                                uid: uid,
                                owedAmount: e.amountOwedBy(uid),
                                members: memberProvider.members,
                                currency: currency,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

/// Resolves a contributor's uid to their name/email from the current
/// member list and shows what they owe for one expense. Falls back
/// gracefully if the member was later removed from the group — the
/// expense still remembers who was a contributor at the time even if
/// they're no longer listed under the Members tab.
class _ContributorRow extends StatelessWidget {
  final String uid;
  final double owedAmount;
  final List<GroupMemberModel> members;
  final NumberFormat currency;

  const _ContributorRow({
    required this.uid,
    required this.owedAmount,
    required this.members,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final member = members.where((m) => m.uid == uid).firstOrNull;
    final label = member == null
        ? 'Former member'
        : (member.displayName.isNotEmpty ? member.displayName : member.email);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          Text(
            currency.format(owedAmount),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
