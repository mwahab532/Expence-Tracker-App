import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/screens/statistics/Statistics_body.dart';
import 'package:provider/provider.dart';
import 'expense_statistics.dart';
import '../../providers/expense_provider.dart';

class StatisticsScreen extends StatelessWidget {
  final bool embedded;
  const StatisticsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final stats = ExpenseStatistics.fromExpenses(expenses);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: stats == null
          ? const Center(
              child: Column(
                spacing: 15,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_sharp, size: 60),
                  Text('Add some expenses to see statistics.'),
                ],
              ),
            )
          : StatisticsBody(stats: stats),
    );
  }
}
