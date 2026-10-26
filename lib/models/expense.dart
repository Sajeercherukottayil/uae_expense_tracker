import 'package:flutter/material.dart';

/// Categories tuned for living abroad on a visit visa while job hunting.
enum ExpenseCategory {
  rent('Rent / Housing', Icons.bed_outlined, Color(0xFF5C6BC0)),
  food('Food & Groceries', Icons.restaurant_outlined, Color(0xFFEF6C00)),
  transport('Transport', Icons.directions_bus_outlined, Color(0xFF00897B)),
  visa('Visa & Documents', Icons.badge_outlined, Color(0xFFC62828)),
  mobile('Mobile & Internet', Icons.sim_card_outlined, Color(0xFF6D4C41)),
  jobSearch('Job Search', Icons.work_outline, Color(0xFF1E88E5)),
  health('Health', Icons.local_hospital_outlined, Color(0xFFD81B60)),
  shopping('Shopping', Icons.shopping_bag_outlined, Color(0xFF8E24AA)),
  sentHome('Sent Home', Icons.send_outlined, Color(0xFF43A047)),
  other('Other', Icons.more_horiz, Color(0xFF757575));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: ExpenseCategory.values.asNameMap()[json['category']] ??
            ExpenseCategory.other,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );
}
