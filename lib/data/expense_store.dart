import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

/// Holds all expenses and settings, persisted on the device.
class ExpenseStore extends ChangeNotifier {
  ExpenseStore._(this._prefs) {
    final raw = _prefs.getString(_kExpenses);
    if (raw != null) {
      _expenses = (jsonDecode(raw) as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _startingFunds = _prefs.getDouble(_kFunds) ?? 0;
    final visa = _prefs.getString(_kVisa);
    _visaExpiry = visa == null ? null : DateTime.parse(visa);
    _sort();
  }

  static const _kExpenses = 'expenses';
  static const _kFunds = 'starting_funds';
  static const _kVisa = 'visa_expiry';

  static Future<ExpenseStore> load() async =>
      ExpenseStore._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  List<Expense> _expenses = [];
  double _startingFunds = 0;
  DateTime? _visaExpiry;

  /// Newest first.
  List<Expense> get expenses => List.unmodifiable(_expenses);
  double get startingFunds => _startingFunds;
  DateTime? get visaExpiry => _visaExpiry;

  Future<void> add(Expense expense) async {
    _expenses.add(expense);
    _sort();
    await _saveExpenses();
  }

  Future<void> update(Expense expense) async {
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i == -1) return;
    _expenses[i] = expense;
    _sort();
    await _saveExpenses();
  }

  Future<void> delete(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _saveExpenses();
  }

  Future<void> setStartingFunds(double value) async {
    _startingFunds = value;
    notifyListeners();
    await _prefs.setDouble(_kFunds, value);
  }

  Future<void> setVisaExpiry(DateTime? date) async {
    _visaExpiry = date;
    notifyListeners();
    if (date == null) {
      await _prefs.remove(_kVisa);
    } else {
      await _prefs.setString(_kVisa, date.toIso8601String());
    }
  }

  Future<void> clearAll() async {
    _expenses.clear();
    _startingFunds = 0;
    _visaExpiry = null;
    notifyListeners();
    await Future.wait([
      _prefs.remove(_kExpenses),
      _prefs.remove(_kFunds),
      _prefs.remove(_kVisa),
    ]);
  }

  // ---- Calculations ----

  double get totalSpent => _sum(_expenses);

  double get remainingFunds => _startingFunds - totalSpent;

  double spentOn(DateTime day) =>
      _sum(_expenses.where((e) => DateUtils.isSameDay(e.date, day)));

  List<Expense> inMonth(DateTime month) => _expenses
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();

  double spentInMonth(DateTime month) => _sum(inMonth(month));

  /// Category totals for a month, largest first.
  Map<ExpenseCategory, double> byCategory(DateTime month) {
    final totals = <ExpenseCategory, double>{};
    for (final e in inMonth(month)) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Average spend per day since the first recorded expense.
  double get dailyAverage {
    if (_expenses.isEmpty) return 0;
    final first = DateUtils.dateOnly(_expenses.last.date);
    final days =
        DateUtils.dateOnly(DateTime.now()).difference(first).inDays + 1;
    return totalSpent / (days < 1 ? 1 : days);
  }

  /// How many more days the remaining funds last at the current pace.
  int? get daysFundsLast {
    if (_startingFunds <= 0 || dailyAverage <= 0) return null;
    if (remainingFunds <= 0) return 0;
    return (remainingFunds / dailyAverage).floor();
  }

  int? get visaDaysLeft => _visaExpiry == null
      ? null
      : DateUtils.dateOnly(_visaExpiry!)
          .difference(DateUtils.dateOnly(DateTime.now()))
          .inDays;

  void _sort() => _expenses.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _saveExpenses() async {
    notifyListeners();
    await _prefs.setString(
        _kExpenses, jsonEncode(_expenses.map((e) => e.toJson()).toList()));
  }

  static double _sum(Iterable<Expense> list) =>
      list.fold(0, (sum, e) => sum + e.amount);
}

/// Makes the store available to the widget tree and rebuilds on changes.
class StoreScope extends InheritedNotifier<ExpenseStore> {
  const StoreScope({super.key, required ExpenseStore store, required super.child})
      : super(notifier: store);

  /// Use in build methods: rebuilds when data changes.
  static ExpenseStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Use in callbacks: no rebuild subscription.
  static ExpenseStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
