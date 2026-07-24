import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/screens/expenses/expence_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository_imp.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

class ExpenseListScreen extends StatefulWidget {
  final bool embedded;
  const ExpenseListScreen({super.key, this.embedded = false});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currency = NumberFormat.currency(symbol: '\Rs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by title',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (q) => provider.updateFilter(
                      ExpenseFilter(
                        categoryId: provider.filter.categoryId,
                        startDate: provider.filter.startDate,
                        endDate: provider.filter.endDate,
                        sortBy: provider.filter.sortBy,
                        searchQuery: q,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onPressed: () => _showSortSheet(context, provider),
                ),
              ],
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.expenses.isEmpty
          ? const Center(child: Text('No expenses yet. Tap + to add one.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = provider.expenses[i];
                return Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context, e.title),
                  onDismissed: (_) => _deleteExpense(context, provider, e),
                  child: Card(
                    child: ListTile(
                      title: Text(e.title),
                      subtitle: Text(
                        '${e.categoryName} • ${DateFormat.yMMMd().format(e.date)}',
                      ),
                      trailing: Text(
                        currency.format(e.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () {
                        final categoryProvider = context
                            .read<CategoryProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(value: provider),
                                ChangeNotifierProvider.value(
                                  value: categoryProvider,
                                ),
                              ],
                              child: ExpenseDetailScreen(expense: e),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "$title"? This can\'t be undone once confirmed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteExpense(
    BuildContext context,
    ExpenseProvider provider,
    ExpenseModel e,
  ) async {
    final success = await provider.deleteExpense(
      e.id,
      receiptImageUrl: e.receiptImageUrl,
    );
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${e.title}" deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to delete expense'),
        ),
      );
    }
  }

  void _showSortSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            for (final entry in {
              SortBy.dateDesc: 'Newest first',
              SortBy.dateAsc: 'Oldest first',
              SortBy.amountDesc: 'Amount: high to low',
              SortBy.amountAsc: 'Amount: low to high',
            }.entries)
              ListTile(
                title: Text(entry.value),
                trailing: provider.filter.sortBy == entry.key
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  provider.updateFilter(
                    ExpenseFilter(
                      categoryId: provider.filter.categoryId,
                      startDate: provider.filter.startDate,
                      endDate: provider.filter.endDate,
                      searchQuery: provider.filter.searchQuery,
                      sortBy: entry.key,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
