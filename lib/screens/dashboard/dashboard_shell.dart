import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/providers/expense_provider.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';
import 'package:flutter_expence_tracker/providers/group_provider.dart';
import 'package:flutter_expence_tracker/screens/categories/categories_screen.dart';
import 'package:flutter_expence_tracker/screens/dashboard/dashboard_home.dart';
import 'package:flutter_expence_tracker/screens/expenses/add_edit_expense_screen.dart';
import 'package:flutter_expence_tracker/screens/expenses/expense_list_screen.dart';
import 'package:flutter_expence_tracker/screens/payback/add_payback_screen.dart';
import 'package:flutter_expence_tracker/screens/profile/profile_screen.dart';
import 'package:flutter_expence_tracker/screens/statistics/statistics_screen.dart';
import 'package:provider/provider.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell();

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  final _pages = const [
    DashboardHome(),
    ExpenseListScreen(embedded: true),
    StatisticsScreen(embedded: true),
    CategoriesScreen(embedded: true),
    ProfileScreen(embedded: true),
  ];

  Future<void> _showAddOptionsSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Add Expense'),
              subtitle: const Text('Log a purchase or bill'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openAddExpense(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text('Individual Payback'),
              subtitle: const Text(
                'Money received back, or given back to someone',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _openAddPayback(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Create group'),
              subtitle: const Text('Add multiple persons in a group'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateGroupDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: expenseProvider),
            ChangeNotifierProvider.value(value: categoryProvider),
          ],
          child: const AddEditExpenseScreen(),
        ),
      ),
    );
    if (added == true && mounted) {
      setState(() => _index = 0);
    }
  }

  Future<void> _openAddPayback(BuildContext context) async {
    final paybackProvider = context.read<PaybackProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: paybackProvider),
            ChangeNotifierProvider.value(value: expenseProvider),
            ChangeNotifierProvider.value(value: categoryProvider),
          ],
          child: const AddPaybackScreen(),
        ),
      ),
    );
    if (added == true && mounted) {
      setState(() => _index = 0);
    }
  }

  /// Captures GroupProvider from the OUTER context (this widget's own
  /// build context) BEFORE opening the dialog. showDialog's own builder
  /// context sits in the app's overlay, above this route's local
  /// MultiProvider in the InheritedWidget lookup chain — the same
  /// scoping issue we hit with Navigator.push, just for dialogs instead.
  /// Reading the provider here and using that captured instance directly
  /// (instead of calling context.read again inside the dialog) sidesteps
  /// it entirely.
  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final groupProvider = context.read<GroupProvider>();
    final rootMessenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          bool saving = false;
          return AlertDialog(
            title: const Text('Create Group'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Group name is required' : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    // ignore: dead_code
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        final success = await groupProvider.addGroup(controller.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (success) {
                          rootMessenger.showSnackBar(
                            SnackBar(content: Text('Group "${controller.text.trim()}" created')),
                          );
                        } else {
                          rootMessenger.showSnackBar(
                            SnackBar(content: Text(groupProvider.errorMessage ?? 'Failed to create group')),
                          );
                        }
                      },
                child: const Text('Create Group'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton(
              onPressed: () => _showAddOptionsSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}