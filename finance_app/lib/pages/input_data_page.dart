import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';
import '../models/finance_item_model.dart';

class InputDataPage extends StatefulWidget {
  const InputDataPage({super.key});

  @override
  State<InputDataPage> createState() => _InputDataPageState();
}

class _InputDataPageState extends State<InputDataPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String _currency = 'RSD';
  String _flow = 'Expense';
  bool _isSaving = false;
  bool _formValid = false;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await AppDatabase.instance.getCategories();
    setState(() {
      _categories = cats;
    });
  }

  void _validateForm() {
    final amountText = _amountController.text.replaceAll(r'[, ]', '');
    final categoryText = _categoryController.text.trim();

    bool amountValid = false;
    if (amountText.isNotEmpty) {
      final parsed = double.tryParse(amountText);
      if (parsed != null && parsed > 0) amountValid = true;
    }

    final categoryValid = categoryText.isNotEmpty;

    final newValid = amountValid && categoryValid;
    if (newValid != _formValid) setState(() => _formValid = newValid);
  }

  double? _parseAmount() {
    final cleaned = _amountController.text.replaceAll(RegExp(r'[, ]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _saveToDB() async {
    FocusScope.of(context).unfocus();
    final parsedAmount = _parseAmount();
    final categoryText = _categoryController.text.trim();

    if (parsedAmount == null || parsedAmount <= 0 || categoryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the inputs before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final item = FinanceItemModel(
      currency: _currency,
      amount: parsedAmount,
      flow: _flow,
      category: categoryText,
      timestamp: DateTime.now(),
    );

    try {
      await AppDatabase.instance.insertItem(item);
      await AppDatabase.instance.insertCategory(categoryText);
      await _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Item saved')),
      );

      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Input Finance Data')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          onChanged: _validateForm,
          child: Column(
            children: [
              // Currency
              Card(
                color: primaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Currency', style: TextStyle(fontSize: 20, color: onPrimary)),
                      ),
                      DropdownButton<String>(
                        value: _currency,
                        dropdownColor: primaryColor,
                        style: TextStyle(fontSize: 20, color: onPrimary),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                        items: ['RSD', 'EUR', 'USD', 'GBP']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Amount card
              Card(
                color: primaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('Amount', style: TextStyle(fontSize: 20, color: Colors.white))),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                          ],
                          style: const TextStyle(fontSize: 20, color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: onPrimary,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: '0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter amount';
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed <= 0) return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Flow
              Card(
                color: primaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('Flow', style: TextStyle(fontSize: 20, color: onPrimary))),
                      DropdownButton<String>(
                        value: _flow,
                        dropdownColor: primaryColor,
                        style: TextStyle(fontSize: 20, color: onPrimary),
                        onChanged: (v) {
                          if (v != null) setState(() => _flow = v);
                        },
                        items: ['Expense', 'Income']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Category
              Card(
                color: primaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Category', style: TextStyle(fontSize: 20, color: Colors.white))),
                      SizedBox(
                        width: 200,
                        child: RawAutocomplete<String>(
                          textEditingController: _categoryController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            // Show all categories if field focused and empty
                            if (textEditingValue.text.isEmpty) return _categories;
                            final q = textEditingValue.text.toLowerCase();
                            return _categories.where((c) => c.toLowerCase().contains(q));
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: onPrimary,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                hintText: 'e.g. Food',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Category cannot be empty';
                                return null;
                              },
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topRight,
                              child: Material(
                                elevation: 4,
                                child: SizedBox(
                                  width: 200,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        dense: true,
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (selection) {
                            _categoryController.text = selection;
                            _validateForm();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Input button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!_formValid || _isSaving) ? null : _saveToDB,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Text('INPUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
