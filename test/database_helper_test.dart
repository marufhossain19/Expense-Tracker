import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/models/expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SQLite DatabaseHelper & Expense Model Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      await dbHelper.clearTransactions();
    });

    tearDown(() async {
      await dbHelper.clearTransactions();
    });

    test('Insert transaction into transactions table and retrieve it', () async {
      final row = {
        'title': 'Salary Payment',
        'amount': 2500.0,
        'category': 'Salary',
        'type': 'Income',
        'date': DateTime.now().toIso8601String(),
      };

      final id = await dbHelper.insertTransaction(row);
      expect(id, isPositive);

      final transactions = await dbHelper.getTransactions();
      expect(transactions.length, 1);
      expect(transactions.first['id'], id);
      expect(transactions.first['title'], 'Salary Payment');
      expect(transactions.first['amount'], 2500.0);
      expect(transactions.first['category'], 'Salary');
      expect(transactions.first['type'], 'Income');
    });

    test('Update transaction in SQLite database', () async {
      final row = {
        'title': 'Coffee',
        'amount': 5.0,
        'category': 'Food',
        'type': 'Expense',
        'date': DateTime.now().toIso8601String(),
      };

      final id = await dbHelper.insertTransaction(row);

      final updatedRow = {
        'id': id,
        'title': 'Specialty Coffee',
        'amount': 7.5,
        'category': 'Food',
        'type': 'Expense',
        'date': DateTime.now().toIso8601String(),
      };

      final count = await dbHelper.updateTransaction(updatedRow);
      expect(count, 1);

      final transactions = await dbHelper.getTransactions();
      expect(transactions.length, 1);
      expect(transactions.first['title'], 'Specialty Coffee');
      expect(transactions.first['amount'], 7.5);
    });

    test('Delete transaction from SQLite database', () async {
      final id = await dbHelper.insertTransaction({
        'title': 'Movie Ticket',
        'amount': 15.0,
        'category': 'Entertainment',
        'type': 'Expense',
        'date': DateTime.now().toIso8601String(),
      });

      var transactions = await dbHelper.getTransactions();
      expect(transactions.length, 1);

      final deleteCount = await dbHelper.deleteTransaction(id);
      expect(deleteCount, 1);

      transactions = await dbHelper.getTransactions();
      expect(transactions.isEmpty, isTrue);
    });

    test('Expense model toMap and fromMap conversion', () {
      final expense = Expense(
        id: 42,
        title: 'Freelance Project',
        amount: 800.0,
        category: 'Work',
        categoryIcon: 0xe0af,
        categoryColor: 0xFF6C5CE7,
        date: DateTime(2026, 11, 8),
        isIncome: true,
      );

      final map = expense.toMap();
      expect(map['id'], 42);
      expect(map['title'], 'Freelance Project');
      expect(map['amount'], 800.0);
      expect(map['category'], 'Work');
      expect(map['type'], 'Income');

      final fromMapExpense = Expense.fromMap(map);
      expect(fromMapExpense.id, 42);
      expect(fromMapExpense.title, 'Freelance Project');
      expect(fromMapExpense.amount, 800.0);
      expect(fromMapExpense.isIncome, isTrue);
      expect(fromMapExpense.type, 'Income');
    });
  });
}

