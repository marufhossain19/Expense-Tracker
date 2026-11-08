import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';

/// Screen to edit an existing transaction.
/// Pre-fills previously saved details and updates the local SQLite database.
class EditTransactionScreen extends StatefulWidget {
  final Expense expense;

  const EditTransactionScreen({super.key, required this.expense});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late String _selectedType;
  String? _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _noteController = TextEditingController(text: widget.expense.note ?? '');
    _selectedType = widget.expense.isIncome ? 'Income' : 'Expense';
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());
    final isIncome = _selectedType == 'Income';
    final note =
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    await provider.updateExpense(
      id: widget.expense.id,
      title: title,
      amount: amount,
      category: _selectedCategory!,
      date: _selectedDate,
      isIncome: isIncome,
      note: note,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction updated successfully'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Return the updated expense so caller can refresh immediately
    final updated = widget.expense.copyWith(
      title: title,
      amount: amount,
      category: _selectedCategory,
      categoryIcon: provider.getCategoryIcon(_selectedCategory!),
      categoryColor: provider.getCategoryColor(_selectedCategory!),
      date: _selectedDate,
      isIncome: isIncome,
      note: note,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<ExpenseProvider>(context);

    // Ensure list of categories includes the currently selected category
    final categoryNames = provider.categories.map((c) => c.name).toSet().toList();
    if (_selectedCategory != null && !categoryNames.contains(_selectedCategory)) {
      categoryNames.add(_selectedCategory!);
    }
    if (categoryNames.isEmpty) {
      categoryNames.addAll(['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Salary', 'Other']);
    }

    final isIncome = _selectedType == 'Income';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Transaction Type Selector ────────────────────
                Text(
                  'Transaction Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Expense',
                      child: Text('Expense', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
                    ),
                    DropdownMenuItem(
                      value: 'Income',
                      child: Text('Income', style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Select transaction type' : null,
                ),
                const SizedBox(height: 18),

                // ── Title Field ──────────────────────────────────
                Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Grocery Shopping, Monthly Salary',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Amount Field ─────────────────────────────────
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount cannot be empty.';
                    }
                    final num = double.tryParse(v);
                    if (num == null) {
                      return 'Amount must be a valid number.';
                    }
                    if (num <= 0) {
                      return 'Amount must be a valid positive number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Category DropdownButton ──────────────────────
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded),
                    hintText: 'Select Category',
                  ),
                  items: categoryNames.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Category must be selected.' : null,
                ),
                const SizedBox(height: 18),

                // ── Date Picker ──────────────────────────────────
                Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Note Field ───────────────────────────────────
                Text(
                  'Note (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add an optional note...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Save Button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isIncome ? AppColors.income : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
