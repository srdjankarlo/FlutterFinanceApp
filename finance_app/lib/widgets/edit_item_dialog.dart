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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.item.amount.toString());
    _categoryController = TextEditingController(text: widget.item.category);
    _currency = widget.item.currency;
    _flow = widget.item.flow;
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_amountController.text.replaceAll(',', ''));
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
          TextFormField(controller: _amountController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 8),
          TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 8),
          DropdownButton<String>(value: _currency, onChanged: (v){ if(v!=null) setState(()=>_currency=v); }, items: ['RSD','USD','EUR','GBP'].map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList()),
          const SizedBox(height: 8),
          DropdownButton<String>(value: _flow, onChanged: (v){ if(v!=null) setState(()=>_flow=v); }, items: ['Expense','Income'].map((f)=>DropdownMenuItem(value:f,child:Text(f))).toList()),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: _delete, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
