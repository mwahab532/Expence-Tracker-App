import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_expence_tracker/data/models/category_model.dart';
import 'package:flutter_expence_tracker/data/models/group_expense_model.dart';
import 'package:flutter_expence_tracker/providers/category_provider.dart';
import 'package:flutter_expence_tracker/providers/group_expense_provider.dart';
import 'package:flutter_expence_tracker/providers/group_member_provider.dart';

/// Add/Edit a group expense. Mirrors add_edit_expense_screen.dart's field
/// layout (Title, Amount, Date, Notes) with one addition right after
/// Amount: a Contributors multi-select, defaulting to all current group
/// members, used to split the amount equally among only the people
/// selected.
class GroupAddEditExpenseScreen extends StatefulWidget {
  final GroupExpenseModel? expense;
  const GroupAddEditExpenseScreen({super.key, this.expense});

  @override
  State<GroupAddEditExpenseScreen> createState() =>
      _GroupAddEditExpenseScreenState();
}

class _GroupAddEditExpenseScreenState extends State<GroupAddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.expense?.title,
  );
  late final _amountController = TextEditingController(
    text: widget.expense?.amount.toString(),
  );
  late final _notesController = TextEditingController(
    text: widget.expense?.notes,
  );
  DateTime _date = DateTime.now();
  Set<String> _selectedContributorUids = {};
  bool _initializedContributors = false;
  CategoryModel? _selectedCategory;
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Defaults to all current members selected (for a new expense), or the
  /// expense's originally-saved contributors (when editing). Only runs
  /// once — after that the user's own checkbox choices take over.
  void _initContributorsIfNeeded(List<String> allMemberUids) {
    if (_initializedContributors) return;
    _selectedContributorUids = widget.expense != null
        ? widget.expense!.contributorUids.toSet()
        : allMemberUids.toSet();
    _initializedContributors = true;
  }

  void _resolveInitialCategory(List<CategoryModel> categories) {
    if (_selectedCategory != null || widget.expense == null) return;
    for (final c in categories) {
      if (c.id == widget.expense!.categoryId) {
        _selectedCategory = c;
        break;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedContributorUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one contributor')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<GroupExpenseProvider>();
    final now = DateTime.now();

    final expense = GroupExpenseModel(
      id: widget.expense?.id ?? '',
      title: _titleController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      contributorUids: _selectedContributorUids.toList(),
      date: _date,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.expense?.createdAt ?? now,
    );

    final success = _isEditing
        ? await provider.updateExpense(expense)
        : await provider.addExpense(expense);

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Group expense updated' : 'Group expense added',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Failed to save group expense',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<GroupMemberProvider>().members;
    _initContributorsIfNeeded(members.map((m) => m.uid).toList());

    final categories = context.watch<CategoryProvider>().categories;
    _resolveInitialCategory(categories);

    final amount = double.tryParse(_amountController.text) ?? 0;
    final perPerson = _selectedContributorUids.isEmpty
        ? 0
        : amount / _selectedContributorUids.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group Expense' : 'Add Group Expense'),
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
                prefixText: '\Rs',
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              onChanged: (_) =>
                  setState(() {}), // live-updates the per-person preview below
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryModel>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: 20),

            // --- Contributors field (converted to a dropdown) ---
              DropdownButtonFormField<String>(

                initialValue: null,
                decoration: const InputDecoration(
                  labelText: 'contributors',
                ),
                hint: Text(
                  _selectedContributorUids.isEmpty
                      ? 'No contributors selected'
                      : '${_selectedContributorUids.length} selected',
                ),
                selectedItemBuilder: (context) => members
                    .map(
                      (_) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedContributorUids.isEmpty
                              ? 'No contributors selected'
                              : '${_selectedContributorUids.length} selected',
                        ),
                      ),
                    )
                    .toList(),
                items: members.map((m) {
                  final selected = _selectedContributorUids.contains(m.uid);
                  return DropdownMenuItem<String>(
                    value: m.uid,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.displayName.isNotEmpty ? m.displayName : m.email,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (uid) {
                  if (uid == null) return;
                  setState(() {
                    if (_selectedContributorUids.contains(uid)) {
                      _selectedContributorUids.remove(uid);
                    } else {
                      _selectedContributorUids.add(uid);
                    }
                  });
                },
              ),
            if (_selectedContributorUids.isNotEmpty && amount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '\$${perPerson.toStringAsFixed(2)} each × ${_selectedContributorUids.length} ${_selectedContributorUids.length == 1 ? 'person' : 'people'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 20),

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
                  : Text(_isEditing ? 'Save Changes' : 'Add Group Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
