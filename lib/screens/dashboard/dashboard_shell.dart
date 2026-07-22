import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/providers/expense_provider.dart';
import 'package:flutter_expence_tracker/screens/categories/categories_screen.dart';
import 'package:flutter_expence_tracker/screens/dashboard/dashboard_home.dart';
import 'package:flutter_expence_tracker/screens/expenses/add_edit_expense_screen.dart';
import 'package:flutter_expence_tracker/screens/expenses/expense_list_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _index == 0 || _index == 1
          ? ClipOval(
              child: FloatingActionButton(
                backgroundColor: Colors.green.shade900,
                onPressed: () async {
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
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: Colors.green.shade900,
        indicatorShape:CircleBorder() ,
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
