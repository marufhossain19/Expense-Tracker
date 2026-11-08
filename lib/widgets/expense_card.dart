import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/expense.dart';
import '../screens/transaction_details_screen.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Reusable expense card displaying:
/// - Transaction Title
/// - Amount (green for income, red for expense)
/// - Category
/// - Date
/// - Transaction Type (Income / Expense badge)
/// - Delete action with confirmation AlertDialog
/// - Tap to view Transaction Details
class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final int index;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${widget.expense.title}"? This action cannot be undone.',
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

    if (shouldDelete == true) {
      widget.onDelete?.call();
    }
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(expense: widget.expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final e = widget.expense;
    final color = Color(e.categoryColor);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (widget.index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Slidable(
        key: ValueKey(e.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _confirmDelete(context),
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _openDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: _buildCardContent(isDark, e, color),
        ),
      ),
    );
  }

  Widget _buildCardContent(bool isDark, Expense e, Color color) {
    final isIncome = e.isIncome;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Category Icon ──────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              // ignore: non_const_argument_for_const_parameter
              IconData(e.categoryIcon, fontFamily: 'MaterialIcons'),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // ── Title + Category • Date • Type Badge ──────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Transaction Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Category label
                    Flexible(
                      flex: 0,
                      child: Text(
                        e.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Date
                    Expanded(
                      child: Text(
                        Formatters.relativeDateWithTime(e.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Amount (Different colors for income and expenses) ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              '${isIncome ? '+' : '-'}${Formatters.currency(e.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: typeColor,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
