import 'package:flutter/material.dart';

import '../models/analytics_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._service);

  final TransactionService _service;

  List<TransactionModel> items = [];
  SummaryModel summary = SummaryModel.empty();
  List<MonthlyPoint> monthly = [];
  List<CategorySpend> categorySpend = [];
  bool loading = false;
  bool analyticsLoading = false;
  String? error;

  String search = '';
  String? typeFilter;
  String? categoryFilter;
  DateTime? startDate;
  DateTime? endDate;
  int analyticsYear = DateTime.now().year;
  int? analyticsMonth;

  List<TransactionModel> get recent => items.take(5).toList();

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.list(
          type: typeFilter,
          categoryId: categoryFilter,
          startDate: startDate,
          endDate: endDate,
          search: search.isEmpty ? null : search,
        ),
        _service.summary(),
      ]);
      items = results[0] as List<TransactionModel>;
      summary = results[1] as SummaryModel;
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalytics() async {
    analyticsLoading = true;
    notifyListeners();
    try {
      monthly = await _service.monthly(analyticsYear);
      categorySpend = await _service.byCategory(
        year: analyticsYear,
        month: analyticsMonth,
      );
    } catch (e) {
      error = friendlyError(e);
    } finally {
      analyticsLoading = false;
      notifyListeners();
    }
  }

  void setFilters({
    String? searchText,
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    bool clearType = false,
    bool clearCategory = false,
    bool clearDates = false,
  }) {
    if (searchText != null) search = searchText;
    if (clearType) {
      typeFilter = null;
    } else if (type != null) {
      typeFilter = type;
    }
    if (clearCategory) {
      categoryFilter = null;
    } else if (categoryId != null) {
      categoryFilter = categoryId;
    }
    if (clearDates) {
      startDate = null;
      endDate = null;
    } else {
      if (from != null) startDate = from;
      if (to != null) endDate = to;
    }
    refresh();
  }

  Future<bool> save(Map<String, dynamic> body, {String? id}) async {
    try {
      if (id == null) {
        await _service.create(body);
      } else {
        await _service.update(id, body);
      }
      await refresh();
      return true;
    } catch (e) {
      error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _service.delete(id);
      await refresh();
      return true;
    } catch (e) {
      error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }
}
