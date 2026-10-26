import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../utils/format.dart';
import '../widgets/expense_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final expenses = store.expenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _SummaryCard(store: store),
          const SizedBox(height: 12),
          _InsightCard(store: store),
          const SizedBox(height: 20),
          Text('Recent expenses', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (expenses.isEmpty)
            const _EmptyState()
          else
            ..._groupedByDay(context, expenses),
        ],
      ),
    );
  }

  List<Widget> _groupedByDay(BuildContext context, List<Expense> expenses) {
    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final e in expenses) {
      if (currentDay == null || !DateUtils.isSameDay(currentDay, e.date)) {
        currentDay = e.date;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(_dayLabel(e.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ));
      }
      widgets.add(ExpenseTile(expense: e));
    }
    return widgets;
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();
    if (DateUtils.isSameDay(date, today)) return 'Today';
    if (DateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return dayFormat.format(date);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.store});

  final ExpenseStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final hasFunds = store.startingFunds > 0;
    final monthSpent = store.spentInMonth(now);
    final visaDays = store.visaDaysLeft;
    final headline = hasFunds ? store.remainingFunds : monthSpent;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hasFunds ? 'Remaining funds' : 'Spent this month',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              store.currency.format(headline),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasFunds && headline < 0 ? scheme.error : null,
              ),
            ),
            if (hasFunds)
              Text('of ${store.currency.format(store.startingFunds)} available',
                  style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(label: 'Today', value: store.currency.format(store.spentOn(now))),
                _Stat(label: 'This month', value: store.currency.format(monthSpent)),
                _Stat(
                  label: 'Visa left',
                  value: visaDays == null
                      ? '—'
                      : visaDays < 0
                          ? 'Expired'
                          : '$visaDays days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Tells the user how long their money lasts compared to their visa.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.store});

  final ExpenseStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final daysLast = store.daysFundsLast;
    final visaDays = store.visaDaysLeft;

    final String message;
    var warning = false;
    if (store.startingFunds <= 0) {
      message = 'Set your available funds and visa expiry in Settings to see '
          'how long your money will last.';
    } else if (daysLast == null) {
      message = 'Add your expenses to see how long your money will last.';
    } else {
      warning = visaDays != null && visaDays >= 0 && daysLast < visaDays;
      message = 'At about ${store.currency.format(store.dailyAverage)} a day, your money lasts '
          '$daysLast more days.'
          '${warning ? ' That is less than your $visaDays visa days left, so try to cut back.' : ''}';
    }

    return Card(
      color: warning ? scheme.errorContainer : scheme.secondaryContainer,
      child: ListTile(
        leading: Icon(warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
            color: warning ? scheme.onErrorContainer : scheme.onSecondaryContainer),
        title: Text(message,
            style: TextStyle(
                color: warning
                    ? scheme.onErrorContainer
                    : scheme.onSecondaryContainer)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: color),
          const SizedBox(height: 12),
          Text('No expenses yet.\nTap "Add expense" to record your first one.',
              textAlign: TextAlign.center, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
