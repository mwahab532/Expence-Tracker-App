import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/screens/statistics/expense_statistics.dart';
import 'package:intl/intl.dart';

class StatisticsBody extends StatelessWidget {
  final ExpenseStatistics stats;
  const StatisticsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Expenses by Category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              sections: [
                for (final entry in stats.totalsByCategory.entries)
                  PieChartSectionData(
                    color: Colors.green.shade900,
                    value: entry.value,
                    title: entry.key,
                    radius: 90,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
              ],
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.green.shade900,
          child: Column(
            children: [
              ListTile(
                title: const Text('Highest Expense'),
                trailing: Text(currency.format(stats.highest.amount)),
              ),
              ListTile(
                title: const Text('Lowest Expense'),
                trailing: Text(currency.format(stats.lowest.amount)),
              ),
              ListTile(
                title: const Text('Average Daily Spending'),
                trailing: Text(currency.format(stats.averageDailySpending)),
              ),
              ListTile(
                title: const Text('This Month'),
                trailing: Text(currency.format(stats.monthlyTotal)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
