import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';

class PaybackListScreen extends StatelessWidget {
  const PaybackListScreen({super.key});

  Future<void> _delete(BuildContext context, PaybackProvider provider, PaybackModel p) async {
    final success = await provider.deletePayback(p.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '"${p.personName}" removed' : (provider.errorMessage ?? 'Failed to delete')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaybackProvider>();
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Paybacks')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.paybacks.isEmpty
              ? const Center(child: Text('No paybacks recorded yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.paybacks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = provider.paybacks[i];
                    final isReceived = p.type == PaybackType.received;
                    return Dismissible(
                      key: ValueKey(p.id),
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
                      onDismissed: (_) => _delete(context, provider, p),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            isReceived ? Icons.call_received : Icons.call_made,
                            color: isReceived ? Colors.green : Colors.red,
                          ),
                          title: Text(p.personName),
                          subtitle: Text(DateFormat.yMMMd().format(p.date)),
                          trailing: Text(
                            '${isReceived ? '+' : '-'}${currency.format(p.amount)}',
                            style: TextStyle(
                              color: isReceived ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
