import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/dashboard_summary.dart';
import 'package:expense_tracker/widgets/expense_card.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  group('Widget Tests - Personal Expense Tracker', () {
    testWidgets('DashboardSummary renders 3 summary cards with correct labels',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSummary(
              income: 5000.0,
              expense: 1500.0,
              balance: 3500.0,
            ),
          ),
        ),
      );

      // Verify the 3 summary cards exist
      expect(find.text('Current Balance'), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('Total Expense'), findsOneWidget);
    });

    testWidgets('ExpenseCard displays title, category, and transaction type badge',
        (tester) async {
      final expense = Expense(
        id: 1,
        title: 'Lunch at Cafe',
        amount: 25.50,
        category: 'Food',
        categoryIcon: Icons.restaurant.codePoint,
        categoryColor: 0xFFFF5722,
        date: DateTime.now(),
        isIncome: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(expense: expense),
          ),
        ),
      );

      // Verify transaction details are rendered on the card
      expect(find.text('Lunch at Cafe'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('ExpenseCard for income shows Income badge', (tester) async {
      final income = Expense(
        id: 2,
        title: 'Monthly Salary',
        amount: 3000.0,
        category: 'Salary',
        categoryIcon: Icons.attach_money.codePoint,
        categoryColor: 0xFF4CAF50,
        date: DateTime.now(),
        isIncome: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseCard(expense: income),
          ),
        ),
      );

      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
    });
  });
}
