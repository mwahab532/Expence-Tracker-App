import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/data/models/payback_model.dart';
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

    setState(() => _saving = true);
    final provider = context.read<PaybackProvider>();
    final now = DateTime.now();

    final payback = PaybackModel(
      id: '',
      personName: _personController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      type: _type,
      date: _date,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: now,
    );

    final success = await provider.addPayback(payback);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == PaybackType.received
                ? 'Payback received — added to your budget'
                : 'Payback given — deducted from your budget',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save payback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _type == PaybackType.received
                  ? 'Someone is paying you back — this adds to your remaining budget.'
                  : 'You are paying someone back — this reduces your remaining budget.',
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
