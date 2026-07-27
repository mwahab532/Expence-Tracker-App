import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import 'package:flutter_expence_tracker/providers/Buget_provider.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';
import 'package:flutter_expence_tracker/providers/group_provider.dart';
import 'package:flutter_expence_tracker/screens/dashboard/dashboard_shell.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';



/// Wraps the tabbed shell in the providers that depend on the signed-in
/// uid, so they're (re)created exactly once per session and torn down
/// cleanly on sign-out.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => ExpenseProvider(expenseRepository: ctx.read<ExpenseRepository>(), uid: uid),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CategoryProvider(categoryRepository: ctx.read<CategoryRepository>(), uid: uid),
        ),
             ChangeNotifierProvider(
          create: (ctx) => BudgetProvider(budgetRepository: ctx.read<BudgetRepository>(), uid: uid),
        ),
             ChangeNotifierProvider(
          create: (ctx) => PaybackProvider(paybackRepository: ctx.read<PaybackRepository>(), uid: uid),
        ),
             ChangeNotifierProvider(
          create: (ctx) => GroupProvider(groupRepository: ctx.read<GroupRepository>(), uid: uid),
        ),
      ],
      child: const DashboardShell(),
    );
  }
}



