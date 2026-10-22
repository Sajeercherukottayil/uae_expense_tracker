import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_expense_tracker/data/expense_store.dart';
import 'package:uae_expense_tracker/main.dart';
import 'package:uae_expense_tracker/models/expense.dart';

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
