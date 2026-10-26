import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/expense_store.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('expense survives JSON round trip', () {
    final e = Expense(
        id: '1',
        amount: 12.5,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 10, 1),
        note: 'Metro');
    final copy = Expense.fromJson(e.toJson());
    expect(copy.amount, 12.5);
    expect(copy.category, ExpenseCategory.transport);
    expect(copy.note, 'Metro');
  });

  test('store calculates totals and persists', () async {
    final store = await ExpenseStore.load();
    await store.setStartingFunds(1000);
    final now = DateTime.now();
    await store.add(Expense(
        id: 'a', amount: 100, category: ExpenseCategory.rent, date: now));
    await store.add(Expense(
        id: 'b', amount: 50, category: ExpenseCategory.food, date: now));

    expect(store.totalSpent, 150);
    expect(store.remainingFunds, 850);
    expect(store.byCategory(now).keys.first, ExpenseCategory.rent);
    expect(store.daysFundsLast, 5);

    final reloaded = await ExpenseStore.load();
    expect(reloaded.expenses.length, 2);
    expect(reloaded.startingFunds, 1000);
  });

  test('existing data without a saved currency stays in AED', () async {
    SharedPreferences.setMockInitialValues({'starting_funds': 500.0});
    final store = await ExpenseStore.load();
    expect(store.currency.code, 'AED');

    await store.setCurrency(Currency.byCode('INR')!);
    final reloaded = await ExpenseStore.load();
    expect(reloaded.currency.code, 'INR');
    expect(reloaded.currency.format(1234.5), 'INR 1,234.50');
  });

  test('currency follows the device locale and its decimals', () {
    expect(Currency.fromLocale('en_IN').code, 'INR');
    expect(Currency.fromLocale('xx_YY').code, 'USD');
    expect(Currency.byCode('JPY')!.format(1500), 'JPY 1,500');
  });

  testWidgets('add an expense from the home screen', (tester) async {
    final store = await ExpenseStore.load();
    await tester.pumpWidget(ExpenseApp(store: store));

    expect(find.textContaining('No expenses yet'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.expenses.single.amount, 25);
    expect(find.textContaining('No expenses yet'), findsNothing);
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
  });
}
