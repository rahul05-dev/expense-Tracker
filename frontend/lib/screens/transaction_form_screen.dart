import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.existing});

  final TransactionModel? existing;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String _type = 'expense';
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _amount.text = existing.amount.toStringAsFixed(2);
      _description.text = existing.description ?? '';
      _type = existing.type;
      _categoryId = existing.categoryId;
      _date = existing.date;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a category')),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await context.read<TransactionProvider>().save(
      {
        'title': _title.text.trim(),
        'amount': double.parse(_amount.text.trim()),
        'type': _type,
        'category_id': _categoryId,
        'date': _date.toIso8601String().split('T').first,
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      },
      id: widget.existing?.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      final message = context.read<TransactionProvider>().error ?? 'Could not save transaction';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.existing == null ? 'Transaction added' : 'Transaction updated')),
    );
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<TransactionProvider>().remove(widget.existing!.id);
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context
        .watch<CategoryProvider>()
        .ofType(_type);
    if (_categoryId != null && categories.every((item) => item.id != _categoryId)) {
      _categoryId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add transaction' : 'Edit transaction'),
        actions: [
          if (widget.existing != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                    ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) {
                    setState(() {
                      _type = value.first;
                      _categoryId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) return 'Enter a valid amount greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_type),
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(dateFormat.format(_date)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existing == null ? 'Save' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
