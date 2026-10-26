import 'package:flutter/material.dart';

import '../data/expense_store.dart';
import '../models/expense.dart';
import '../utils/format.dart';

/// Monthly totals and a breakdown by category.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final total = store.spentInMonth(_month);
    final count = store.inMonth(_month).length;
    final byCategory = store.byCategory(_month);
    final days = _isCurrentMonth
        ? DateTime.now().day
        : DateUtils.getDaysInMonth(_month.year, _month.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () => _shiftMonth(-1),
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left)),
              Text(monthFormat.format(_month), style: theme.textTheme.titleMedium),
              IconButton(
                  onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total spent', style: theme.textTheme.labelLarge),
                  Text(store.currency.format(total),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '$count ${count == 1 ? 'expense' : 'expenses'} · '
                      'avg ${store.currency.format(total / days)} / day',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('By category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (byCategory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('No expenses this month', textAlign: TextAlign.center),
            )
          else
            for (final entry in byCategory.entries)
              _CategoryBar(
                  category: entry.key,
                  amount: entry.value,
                  fraction: entry.value / total),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar(
      {required this.category, required this.amount, required this.fraction});

  final ExpenseCategory category;
  final double amount;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(category.label)),
              Text(StoreScope.of(context).currency.format(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: category.color,
              backgroundColor: category.color.withValues(alpha: 0.15),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(fraction * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
