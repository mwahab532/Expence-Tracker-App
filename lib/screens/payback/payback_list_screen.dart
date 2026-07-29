import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum PaybackFilter { all, received, given }

class PaybackListScreen extends StatefulWidget {
  const PaybackListScreen({super.key});

  @override
  State<PaybackListScreen> createState() => _PaybackListScreenState();
}

class _PaybackListScreenState extends State<PaybackListScreen> {
  PaybackFilter _selectedFilter = PaybackFilter.all;

  Future<void> _delete(
    BuildContext context,
    PaybackProvider provider,
    PaybackModel payback,
  ) async {
    final success = await provider.deletePayback(payback.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${payback.personName}" removed'
              : (provider.errorMessage ?? 'Failed to delete'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaybackProvider>();

    final currency = NumberFormat.currency(
      symbol: 'Rs ',
      decimalDigits: 2,
    );

    // Apply filter
    List<PaybackModel> paybacks = List.from(provider.paybacks);

    switch (_selectedFilter) {
      case PaybackFilter.received:
        paybacks = paybacks
            .where((e) => e.type == PaybackType.received)
            .toList();
        break;

      case PaybackFilter.given:
        paybacks = paybacks
            .where((e) => e.type == PaybackType.given)
            .toList();
        break;

      case PaybackFilter.all:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paybacks"),
        actions: [
          PopupMenuButton<PaybackFilter>(
            initialValue: _selectedFilter,
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: PaybackFilter.all,
                child: Text("All"),
              ),
              PopupMenuItem(
                value: PaybackFilter.received,
                child: Text("Received"),
              ),
              PopupMenuItem(
                value: PaybackFilter.given,
                child: Text("Given"),
              ),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : paybacks.isEmpty
              ? const Center(
                  child: Text(
                    "No paybacks found.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: paybacks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = paybacks[index];

                    final isReceived =
                        p.type == PaybackType.received;

                    return Dismissible(
                      key: ValueKey(p.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        _delete(context, provider, p);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isReceived
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isReceived
                                  ? Icons.call_received
                                  : Icons.call_made,
                              color: isReceived
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(
                            p.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().format(p.date),
                              ),
                              if (p.notes != null &&
                                  p.notes!.isNotEmpty)
                                Text(
                                  p.notes!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            "${isReceived ? '+' : '-'}${currency.format(p.amount)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isReceived
                                  ? Colors.green
                                  : Colors.red,
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