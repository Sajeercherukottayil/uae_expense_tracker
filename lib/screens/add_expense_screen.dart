import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../utils/format.dart';

/// Adds a new expense, or edits [existing] when given.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.existing});

  final Expense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory _category;
  late DateTime _date;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(text: e == null ? '' : _formatAmount(e.amount));
    _note = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? ExpenseCategory.food;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _formatAmount(double a) =>
      a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(2);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Keep the original time so ordering within a day stays stable.
      setState(() => _date = DateTime(picked.year, picked.month, picked.day,
          _date.hour, _date.minute, _date.second));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final store = StoreScope.read(context);
    final expense = Expense(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      amount: double.parse(_amount.text),
      category: _category,
      date: _date,
      note: _note.text.trim(),
    );
    if (_isEdit) {
      await store.update(expense);
    } else {
      await store.add(expense);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await StoreScope.read(context).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit expense' : 'Add expense'),
        actions: [
          if (_isEdit)
            IconButton(
                onPressed: _delete,
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: StoreScope.of(context).currency.prefix,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final amount = double.tryParse(v ?? '');
                if (amount == null || amount <= 0) return 'Enter an amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Category', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(dayFormat.format(_date)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Nol card top-up',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
