import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tx = context.watch<TransactionProvider>();
    final firstName = (auth.user?.name ?? 'there').split(' ').first;

    return RefreshIndicator(
      onRefresh: () => context.read<TransactionProvider>().refresh(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Hi, $firstName'),
          ),
          if (tx.loading && tx.items.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current balance', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          formatMoney(tx.summary.balance),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        label: 'Income',
                        value: formatMoney(tx.summary.totalIncome),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        label: 'Expenses',
                        value: formatMoney(tx.summary.totalExpense),
                        icon: Icons.trending_down_rounded,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            if (tx.recent.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  subtitle: 'Add your first income or expense to see your balance update.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                sliver: SliverList.builder(
                  itemCount: tx.recent.length,
                  itemBuilder: (context, index) {
                    final item = tx.recent[index];
                    return TransactionTile(
                      transaction: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TransactionFormScreen(existing: item)),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
