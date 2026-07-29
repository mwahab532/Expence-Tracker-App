import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/data/models/category_model.dart';
import 'package:flutter_expence_tracker/data/models/expense_model.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/providers/expense_provider.dart';
import 'package:flutter_expence_tracker/providers/payback_provider.dart';

class AddPaybackScreen extends StatefulWidget {
  const AddPaybackScreen({super.key});

  @override
  State<AddPaybackScreen> createState() => _AddPaybackScreenState();
}

class _AddPaybackScreenState extends State<AddPaybackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  PaybackType _type = PaybackType.received;
  CategoryModel? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // A "Given" payback is real money leaving your pocket, so it also
    // needs a category — same requirement as any regular expense.
    if (_type == PaybackType.given && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category for this expense')),
      );
      return;
    }

    setState(() => _saving = true);
    final paybackProvider = context.read<PaybackProvider>();
    final now = DateTime.now();
    final personName = _personController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final payback = PaybackModel(
      id: '',
      personName: personName,
      amount: amount,
      type: _type,
      date: _date,
      notes: notes,
      createdAt: now,
    );

    final paybackSuccess = await paybackProvider.addPayback(payback);
    if (!paybackSuccess) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(paybackProvider.errorMessage ?? 'Failed to save payback')),
      );
      return;
    }

    // Money given back to someone is a real expense — record it in the
    // regular expense list too, so it shows up in Statistics, the
    // dashboard's "This Month" total, and the Expenses tab like any other
    // spend. (Money "received" is NOT recorded as an expense — nothing
    // was spent, it just tops up available budget directly.)
    bool expenseSuccess = true;
    if (_type == PaybackType.given) {
      final expenseProvider = context.read<ExpenseProvider>();
      final expense = ExpenseModel(
        id: '',
        title: 'Payback to $personName',
        amount: amount,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        date: _date,
        notes: notes,
        receiptImageUrl: null,
        createdAt: now,
        updatedAt: now,
      );
      expenseSuccess = await expenseProvider.addExpense(expense);
      if (!expenseSuccess && mounted) {
        // The payback record was already saved successfully above — only
        // the linked expense failed. Tell the user plainly rather than
        // silently leaving the two out of sync.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              expenseProvider.errorMessage ??
                  'Payback saved, but failed to add it to your expenses',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (expenseSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == PaybackType.received
                ? 'Payback received — added to your budget'
                : 'Payback given — added to your expenses',
          ),
        ),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isGiven = _type == PaybackType.given;
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Individual Payback')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<PaybackType>(
              segments: const [
                ButtonSegment(
                  value: PaybackType.received,
                  label: Text('Received'),
                  icon: Icon(Icons.call_received),
                ),
                ButtonSegment(
                  value: PaybackType.given,
                  label: Text('Given'),
                  icon: Icon(Icons.call_made),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 8),
            Text(
              isGiven
                  ? 'You are paying someone back — this is added to your regular expenses.'
                  : 'Someone is paying you back — this adds to your remaining budget.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _personController,
              decoration: const InputDecoration(labelText: 'Person'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Person name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            if (isGiven) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selectedCategory = c),
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Payback'),
            ),
          ],
        ),
      ),
    );
  }
}
