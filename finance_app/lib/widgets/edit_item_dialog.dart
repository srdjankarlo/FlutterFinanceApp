import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/finance_item_model.dart';

class EditFinanceItemDialog extends StatefulWidget {
  final FinanceItemModel item;
  const EditFinanceItemDialog({required this.item, super.key});

  @override
  State<EditFinanceItemDialog> createState() => _EditFinanceItemDialogState();
}

class _EditFinanceItemDialogState extends State<EditFinanceItemDialog> {
  late TextEditingController _amountController;
  late TextEditingController _categoryController;

  late String _currency;
  late String _flow;

  bool _saving = false;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();

    _amountController =
        TextEditingController(text: widget.item.amount.toString());
    _categoryController =
        TextEditingController(text: widget.item.category);

    _currency = widget.item.currency;
    _flow = widget.item.flow;

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await AppDatabase.instance.getCategories();
    setState(() => _categories = cats);
  }

  Future<void> _save() async {
    final parsed =
    double.tryParse(_amountController.text.replaceAll(',', ''));

    final category = _categoryController.text.trim();

    if (parsed == null || parsed <= 0 || category.isEmpty) return;

    setState(() => _saving = true);

    final updated = FinanceItemModel(
      id: widget.item.id,
      currency: _currency,
      amount: parsed,
      flow: _flow,
      category: category,
      timestamp: widget.item.timestamp,
    );

    await AppDatabase.instance.updateItem(updated);
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    await AppDatabase.instance.deleteItem(widget.item.id!);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 8),

          // Category (autocomplete)
          RawAutocomplete<String>(
            textEditingController: _categoryController,
            focusNode: FocusNode(),
            optionsBuilder: (TextEditingValue value) {
              if (value.text.isEmpty) return _categories;

              final q = value.text.toLowerCase();
              return _categories
                  .where((c) => c.toLowerCase().contains(q));
            },
            fieldViewBuilder:
                (context, controller, focusNode, onSubmitted) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration:
                const InputDecoration(labelText: 'Category'),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final list = options.toList();

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return ListTile(
                          dense: true,
                          title: Text(item),
                          onTap: () => onSelected(item),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (sel) {
              _categoryController.text = sel;
            },
          ),
          const SizedBox(height: 8),

          // Currency dropdown
          DropdownButton<String>(
            value: _currency,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) setState(() => _currency = v);
            },
            items: ['RSD', 'USD', 'EUR', 'GBP']
                .map((c) =>
                DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Flow dropdown
          DropdownButton<String>(
            value: _flow,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) setState(() => _flow = v);
            },
            items: ['Expense', 'Income']
                .map((f) =>
                DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _delete,
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
