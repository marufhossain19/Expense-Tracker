import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Dashboard summary widget displaying three distinct summary cards:
/// 1. Current Balance
/// 2. Total Income
/// 3. Total Expense
class DashboardSummary extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const DashboardSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Card 1: Current Balance ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: balance),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            Formatters.currency(value),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Card 2 & Card 3: Total Income & Total Expense ─────
          Row(
            children: [
              // Total Income Card
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  isDark: isDark,
                  title: 'Total Income',
                  amount: income,
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.income,
                  backgroundColor: AppColors.income.withValues(alpha: isDark ? 0.15 : 0.08),
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),

              // Total Expense Card
              Expanded(
                child: _buildSummaryCard(
                  context: context,
                  isDark: isDark,
                  title: 'Total Expense',
                  amount: expense,
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.expense,
                  backgroundColor: AppColors.expense.withValues(alpha: isDark ? 0.15 : 0.08),
                  isPositive: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required double amount,
    required IconData icon,
    required Color accentColor,
    required Color backgroundColor,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                Formatters.currency(value),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ],
      ),
    );
  }
}
