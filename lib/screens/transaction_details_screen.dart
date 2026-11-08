import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'edit_transaction_screen.dart';

/// Screen displaying complete transaction information with Edit and Delete options.
class TransactionDetailsScreen extends StatefulWidget {
  final Expense expense;

  const TransactionDetailsScreen({super.key, required this.expense});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late Expense _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _editTransaction() async {
    final result = await Navigator.of(context).push<Expense>(
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(expense: _expense),
      ),
    );

    if (result != null && mounted) {
      setState(() => _expense = result);
    }
  }

  Future<void> _deleteTransaction() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${_expense.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.deleteExpense(_expense.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = Color(_expense.categoryColor);
    final isIncome = _expense.isIncome;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;
    final fullDate = DateFormat('EEEE, dd MMMM yyyy').format(_expense.date);
    final fullTime = DateFormat('hh:mm a').format(_expense.date);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Transaction',
            onPressed: _editTransaction,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete Transaction',
            color: AppColors.expense,
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Category Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: catColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  // ignore: non_const_argument_for_const_parameter
                  IconData(_expense.categoryIcon, fontFamily: 'MaterialIcons'),
                  color: catColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _expense.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Type badge (Income / Expense)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 15,
                      color: typeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expense.type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount
              Text(
                '${isIncome ? '+' : '-'}${Formatters.currency(_expense.amount)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: _expense.category,
                      valueColor: catColor,
                      isDark: isDark,
                    ),
                    const Divider(height: 28),
                    _buildDetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: fullDate,
                      isDark: isDark,
                    ),
                    const Divider(height: 28),
                    _buildDetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: fullTime,
                      isDark: isDark,
                    ),
                    if (_expense.note != null && _expense.note!.trim().isNotEmpty) ...[
                      const Divider(height: 28),
                      _buildDetailRow(
                        icon: Icons.notes_rounded,
                        label: 'Note',
                        value: _expense.note!,
                        isDark: isDark,
                      ),
                    ],
                    if (_expense.id != null) ...[
                      const Divider(height: 28),
                      _buildDetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Record ID',
                        value: '#${_expense.id}',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Bottom Action Buttons: Edit and Delete
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteTransaction,
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                      label: const Text('Delete', style: TextStyle(color: AppColors.expense)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.expense, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _editTransaction,
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      label: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
