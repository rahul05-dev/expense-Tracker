import '../utils/formatters.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String? description;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.description,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      amount: parseAmount(json['amount']),
      type: json['type'] as String,
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
    );
  }

  bool get isIncome => type == 'income';
}
