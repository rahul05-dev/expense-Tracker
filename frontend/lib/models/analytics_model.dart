import '../utils/formatters.dart';

class SummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  SummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      totalIncome: parseAmount(json['total_income']),
      totalExpense: parseAmount(json['total_expense']),
      balance: parseAmount(json['balance']),
    );
  }

  static SummaryModel empty() =>
      SummaryModel(totalIncome: 0, totalExpense: 0, balance: 0);
}

class MonthlyPoint {
  final int month;
  final String monthName;
  final double income;
  final double expense;

  MonthlyPoint({
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
  });

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyPoint(
      month: json['month'] as int,
      monthName: json['month_name'] as String,
      income: parseAmount(json['income']),
      expense: parseAmount(json['expense']),
    );
  }
}

class CategorySpend {
  final String categoryId;
  final String categoryName;
  final String? color;
  final double amount;

  CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.amount,
  });

  factory CategorySpend.fromJson(Map<String, dynamic> json) {
    return CategorySpend(
      categoryId: json['category_id'].toString(),
      categoryName: json['category_name'] as String,
      color: json['color'] as String?,
      amount: parseAmount(json['amount']),
    );
  }
}
