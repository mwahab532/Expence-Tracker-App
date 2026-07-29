import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/screens/expenses/expence%20_controller.dart';
import 'package:provider/provider.dart';
import '../../data/models/category_model.dart';
import '../../data/models/expense_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

/// Handles both create and edit: pass an existing [expense] to edit it,
/// or omit it to create a new one.
class AddEditExpenseScreen extends StatelessWidget {
  final ExpenseModel? expense;
  const AddEditExpenseScreen({super.key, this.expense});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AddEditExpenseController(
        expenseProvider: ctx.read<ExpenseProvider>(),
        existing: expense,
      ),
      child: const _AddEditExpenseForm(),
    );
  }
}

class _AddEditExpenseForm extends StatefulWidget {
  const _AddEditExpenseForm();

  @override
  State<_AddEditExpenseForm> createState() => _AddEditExpenseFormState();
}

class _AddEditExpenseFormState extends State<_AddEditExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: context.read<AddEditExpenseController>().existing?.title,
  );
  late final _amountController = TextEditingController(
    text: context.read<AddEditExpenseController>().existing?.amount.toString(),
  );
  late final _notesController = TextEditingController(
    text: context.read<AddEditExpenseController>().existing?.notes,
  );

  Future<void> _submit(AddEditExpenseController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.submit(
      title: _titleController.text,
      amountText: _amountController.text,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.isEditing ? 'Expense updated' : 'Expense added',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to save expense'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddEditExpenseController>();
    final categories = context.watch<CategoryProvider>().categories;
    controller.resolveInitialCategory(categories);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\Rs ',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryModel>(
              initialValue: controller.selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: controller.setCategory,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text('${controller.date.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.setDate(picked);
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
              onPressed: controller.isSaving ? null : () => _submit(controller),
              child: controller.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(controller.isEditing ? 'Save Changes' : 'Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
