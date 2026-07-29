import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/core/widgets/summary_card.dart';
import 'package:flutter_expence_tracker/providers/Buget_provider.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/providers/expense_provider.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';
import 'package:flutter_expence_tracker/providers/group_provider.dart';
import 'package:flutter_expence_tracker/providers/auth_provider.dart';
import 'package:flutter_expence_tracker/screens/groups/group_detail_screen.dart';
import 'package:flutter_expence_tracker/screens/payback/payback_list_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome();

  Future<void> _showSetBudgetDialog(
    BuildContext context,
    BudgetProvider budgetProvider,
  ) async {
    final controller = TextEditingController(
      text: budgetProvider.monthlyBudget > 0
          ? budgetProvider.monthlyBudget.toStringAsFixed(2)
          : '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\Rs ',
          ),
          autofocus: true,
        ),
        actions: [
          if (budgetProvider.isSet)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('Clear Budget?'),
                    content: const Text(
                      'This removes your monthly budget. You can set a new one anytime.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final success = await budgetProvider.clearBudget();
                if (ctx.mounted) Navigator.pop(ctx);
                if (!success && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        budgetProvider.errorMessage ?? 'Failed to clear budget',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Clear Budget',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount < 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              final success = await budgetProvider.setMonthlyBudget(amount);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      budgetProvider.errorMessage ?? 'Failed to save budget',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final paybackProvider = context.watch<PaybackProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final currency = NumberFormat.currency(symbol: '\Rs');
    final remaining = budgetProvider.remainingWithPaybacks(
      expenseProvider.thisMonthExpenses,
      paybackProvider.thisMonthNet,
    );
    final overBudget = budgetProvider.isOverBudgetWithPaybacks(
      expenseProvider.thisMonthExpenses,
      paybackProvider.thisMonthNet,
    );
    return RefreshIndicator(
      onRefresh: () => Future.wait([
        expenseProvider.refresh(),
        budgetProvider.refresh(),
        context.read<CategoryProvider>().refresh(),
        groupProvider.refresh(),
      ]),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Dashboard'),
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.green.shade900,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_alt),
                tooltip: 'Paybacks',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: paybackProvider,
                      child: const PaybackListScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (expenseProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (budgetProvider.isSet)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    color: overBudget
                        ? Colors.red.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            overBudget
                                ? Icons.warning_amber_rounded
                                : Icons.savings_outlined,
                            color: overBudget ? Colors.red : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  overBudget
                                      ? 'Over Budget'
                                      : 'Remaining Budget',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                Text(
                                  currency.format(remaining.abs()),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: overBudget ? Colors.red : null,
                                      ),
                                ),
                                Text(
                                  'of ${currency.format(budgetProvider.monthlyBudget)} monthly budget',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear Budget',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (confirmCtx) => AlertDialog(
                                  title: const Text('Clear Budget?'),
                                  content: const Text(
                                    'This removes your monthly budget. You can set a new one anytime.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(confirmCtx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(confirmCtx, true),
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) return;
                              final success = await budgetProvider
                                  .clearBudget();
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      budgetProvider.errorMessage ??
                                          'Failed to clear budget',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          TextButton(
                            onPressed: () =>
                                _showSetBudgetDialog(context, budgetProvider),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      title: const Text('No budget set'),
                      subtitle: const Text('Tap to set a monthly budget'),
                      onTap: () =>
                          _showSetBudgetDialog(context, budgetProvider),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  SummaryCard(
                    label: 'Total Expenses',
                    value: currency.format(expenseProvider.totalExpenses),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.indigo,
                  ),
                  SummaryCard(
                    label: "Today's Expenses",
                    value: currency.format(expenseProvider.todayExpenses),
                    icon: Icons.today_outlined,
                    color: Colors.teal,
                  ),
                  SummaryCard(
                    label: "This Month",
                    value: currency.format(expenseProvider.thisMonthExpenses),
                    icon: Icons.calendar_month_outlined,
                    color: Colors.orange,
                  ),
                  SummaryCard(
                    label: 'Transactions',
                    value: '${expenseProvider.totalTransactions}',
                    icon: Icons.receipt_outlined,
                    color: Colors.purple,
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Groups',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (groupProvider.groups.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 70,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Groups Yet",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first expense group to split bills and track shared expenses with friends and family.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),

            if (groupProvider.groups.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    childCount: groupProvider.groups.length,
                    (context, i) {
                      final g = groupProvider.groups[i];
                      const groupColors = [
                        Colors.indigo,
                        Colors.teal,
                        Colors.orange,
                        Colors.purple,
                      ];
                      return GestureDetector(
                        onTap: () {
                          final ownerUid = context
                              .read<AuthProvider>()
                              .user!
                              .uid;
                          final categoryProvider = context
                              .read<CategoryProvider>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: categoryProvider,
                                child: GroupDetailScreen(
                                  groupId: g.id,
                                  groupName: g.name,
                                  ownerUid: ownerUid,
                                ),
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Group?'),
                              content: Text('Remove "${g.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            groupProvider.deleteGroup(g.id);
                          }
                        },
                        child: SummaryCard(
                          label: 'Group',
                          value: g.name,
                          icon: Icons.group,
                          color: groupColors[i % groupColors.length],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
