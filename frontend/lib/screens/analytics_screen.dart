import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final year = tx.analyticsYear;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: () => _changeYear(context, year, -1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
            onPressed: () => _changeYear(context, year, 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      body: tx.analyticsLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text('Monthly income vs expenses', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          maxY: _maxY(tx),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                                  final i = value.toInt();
                                  if (i < 1 || i > 12) return const SizedBox.shrink();
                                  return Text(labels[i - 1], style: const TextStyle(fontSize: 11));
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (final point in tx.monthly)
                              BarChartGroupData(
                                x: point.month,
                                barRods: [
                                  BarChartRodData(toY: point.income, color: AppColors.income, width: 6),
                                  BarChartRodData(toY: point.expense, color: AppColors.expense, width: 6),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legend(AppColors.income, 'Income'),
                    const SizedBox(width: 16),
                    _legend(AppColors.expense, 'Expense'),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text('Spending by category', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    DropdownButton<int?>(
                      value: tx.analyticsMonth,
                      hint: const Text('All year'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All year')),
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(value: month, child: Text(_monthName(month))),
                      ],
                      onChanged: (value) {
                        final provider = context.read<TransactionProvider>();
                        provider.analyticsMonth = value;
                        provider.loadAnalytics();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tx.categorySpend.isEmpty)
                  const EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'No expense data',
                    subtitle: 'Add some expenses to see a category breakdown.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: [
                                  for (final item in tx.categorySpend)
                                    PieChartSectionData(
                                      value: item.amount,
                                      color: parseHexColor(item.color),
                                      title: '',
                                      radius: 52,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...tx.categorySpend.map(
                            (item) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 8,
                                backgroundColor: parseHexColor(item.color),
                              ),
                              title: Text(item.categoryName),
                              trailing: Text(formatMoney(item.amount)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  double _maxY(TransactionProvider tx) {
    var max = 0.0;
    for (final point in tx.monthly) {
      if (point.income > max) max = point.income;
      if (point.expense > max) max = point.expense;
    }
    return max == 0 ? 100 : max * 1.2;
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  void _changeYear(BuildContext context, int year, int delta) {
    final provider = context.read<TransactionProvider>();
    provider.analyticsYear = year + delta;
    provider.loadAnalytics();
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}
