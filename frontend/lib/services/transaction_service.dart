import '../models/analytics_model.dart';
import '../models/transaction_model.dart';
import 'api_client.dart';

class TransactionService {
  TransactionService(this._api);

  final ApiClient _api;

  Future<List<TransactionModel>> list({
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final data = await _api.get(
      '/transactions',
      query: {
        'type': type,
        'category_id': categoryId,
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'search': search,
      },
    );
    return (data as List)
        .map((item) => TransactionModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<TransactionModel> create(Map<String, dynamic> body) async {
    final data = await _api.post('/transactions', body: body);
    return TransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<TransactionModel> update(String id, Map<String, dynamic> body) async {
    final data = await _api.put('/transactions/$id', body: body);
    return TransactionModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> delete(String id) async {
    await _api.delete('/transactions/$id');
  }

  Future<SummaryModel> summary() async {
    final data = await _api.get('/analytics/summary');
    return SummaryModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<MonthlyPoint>> monthly(int year) async {
    final data = await _api.get('/analytics/monthly', query: {'year': year});
    return (data as List)
        .map((item) => MonthlyPoint.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<CategorySpend>> byCategory({required int year, int? month}) async {
    final data = await _api.get(
      '/analytics/by-category',
      query: {'year': year, 'month': month},
    );
    return (data as List)
        .map((item) => CategorySpend.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
