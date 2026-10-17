import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () => _editCategory(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories',
                  subtitle: 'Create income and expense categories to classify your money.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...provider.ofType('expense').map((item) => _tile(context, item)),
                    const SizedBox(height: 20),
                    Text('Income', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...provider.ofType('income').map((item) => _tile(context, item)),
                  ],
                ),
    );
  }

  Widget _tile(BuildContext context, CategoryModel category) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: parseHexColor(category.color).withValues(alpha: 0.18),
          foregroundColor: parseHexColor(category.color),
          child: Icon(iconFromName(category.icon)),
        ),
        title: Text(category.name),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editCategory(context, category: category);
            } else if (value == 'delete') {
              _delete(context, category);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategory(BuildContext context, {CategoryModel? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? 'expense';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(category == null ? 'New category' : 'Rename category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  if (category == null) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'expense', label: Text('Expense')),
                        ButtonSegment(value: 'income', label: Text('Income')),
                      ],
                      selected: {type},
                      onSelectionChanged: (value) => setState(() => type = value.first),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    final name = nameController.text.trim();
    nameController.dispose();
    if (saved != true || name.isEmpty || !context.mounted) return;
    final provider = context.read<CategoryProvider>();
    final ok = category == null
        ? await provider.create(name: name, type: type)
        : await provider.rename(category, name);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save category')),
      );
    }
  }

  Future<void> _delete(BuildContext context, CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: const Text('You can only delete a category that has no transactions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<CategoryProvider>();
    final ok = await provider.remove(category);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Category deleted' : provider.error ?? 'Could not delete category')),
    );
  }
}
