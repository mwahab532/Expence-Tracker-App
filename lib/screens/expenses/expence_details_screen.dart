import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import 'add_edit_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<ExpenseProvider>();
    final success = await provider.deleteExpense(expense.id, receiptImageUrl: expense.receiptImageUrl);
    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context); // back to the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${expense.title}" deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete expense')),
      );
    }
  }

  Future<void> _edit(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: expenseProvider),
            ChangeNotifierProvider.value(value: categoryProvider),
          ],
          child: AddEditExpenseScreen(expense: expense),
        ),
      ),
    );
    // The edited expense flows back through the live Firestore stream, so
    // there's nothing to manually refresh here — just close this stale
    // detail view once the edit succeeds, since `expense` is now outdated.
    if (updated == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(expense.amount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Category'),
                  trailing: Text(expense.categoryName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  trailing: Text(DateFormat.yMMMMd().format(expense.date)),
                ),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notes_outlined),
                    title: const Text('Notes'),
                    subtitle: Text(expense.notes!),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time_outlined),
                  title: const Text('Added'),
                  trailing: Text(DateFormat.yMMMd().add_jm().format(expense.createdAt)),
                ),
              ],
            ),
          ),
          if (expense.receiptImageUrl != null) ...[
            const SizedBox(height: 16),
            Text('Receipt', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: expense.receiptImageUrl!,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 120,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}