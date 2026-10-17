import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final categories = context.watch<CategoryProvider>().items;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search title or notes',
              ),
              onChanged: (value) => context.read<TransactionProvider>().setFilters(searchText: value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: tx.typeFilter == null,
                  onSelected: (_) => context.read<TransactionProvider>().setFilters(clearType: true),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Income'),
                  selected: tx.typeFilter == 'income',
                  onSelected: (_) => context.read<TransactionProvider>().setFilters(type: 'income'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Expense'),
                  selected: tx.typeFilter == 'expense',
                  onSelected: (_) => context.read<TransactionProvider>().setFilters(type: 'expense'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    tx.startDate == null
                        ? 'Date'
                        : '${tx.startDate!.day}/${tx.startDate!.month} - ${tx.endDate?.day ?? ''}/${tx.endDate?.month ?? ''}',
                  ),
                  onPressed: () => _pickDates(context, tx),
                ),
                const SizedBox(width: 8),
                if (categories.isNotEmpty)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: tx.categoryFilter,
                      hint: const Text('Category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All categories')),
                        ...categories.map(
                          (CategoryModel category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          context.read<TransactionProvider>().setFilters(clearCategory: true);
                        } else {
                          context.read<TransactionProvider>().setFilters(categoryId: value);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tx.loading
                ? const Center(child: CircularProgressIndicator())
                : tx.items.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching transactions',
                        subtitle: 'Try a different search or clear the filters.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<TransactionProvider>().refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                          itemCount: tx.items.length,
                          itemBuilder: (context, index) {
                            final item = tx.items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Theme.of(context).colorScheme.error,
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              confirmDismiss: (_) => _confirmDelete(context),
                              onDismissed: (_) => context.read<TransactionProvider>().remove(item.id),
                              child: TransactionTile(
                                transaction: item,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TransactionFormScreen(existing: item),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates(BuildContext context, TransactionProvider tx) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: tx.startDate != null && tx.endDate != null
          ? DateTimeRange(start: tx.startDate!, end: tx.endDate!)
          : null,
    );
    if (range == null || !context.mounted) return;
    context.read<TransactionProvider>().setFilters(from: range.start, to: range.end);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
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
    return result ?? false;
  }
}
