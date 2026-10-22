import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../screens/add_expense_screen.dart';
import '../utils/format.dart';

/// One expense row. Swipe left to delete (with undo), tap to edit.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final category = expense.category;
    final hasNote = expense.note.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) {
        final store = StoreScope.read(context);
        final messenger = ScaffoldMessenger.of(context);
        store.delete(expense.id);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('Expense deleted'),
            persist: false,
            action: SnackBarAction(
                label: 'Undo', onPressed: () => store.add(expense)),
          ));
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.15),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(hasNote ? expense.note : category.label,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: hasNote ? Text(category.label) : null,
        trailing: Text(aed(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddExpenseScreen(existing: expense))),
      ),
    );
  }
}
