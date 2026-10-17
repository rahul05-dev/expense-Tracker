import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = amountColor(transaction.type);
    final prefix = transaction.isIncome ? '+' : '-';
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(transaction.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded),
      ),
      title: Text(transaction.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${transaction.categoryName} • ${dateFormat.format(transaction.date)}'),
      trailing: Text(
        '$prefix${formatMoney(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
