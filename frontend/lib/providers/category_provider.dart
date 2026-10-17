import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/formatters.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._service);

  final CategoryService _service;

  List<CategoryModel> items = [];
  bool loading = false;
  String? error;

  List<CategoryModel> ofType(String type) =>
      items.where((category) => category.type == type).toList();

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _service.list();
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({required String name, required String type}) async {
    try {
      final created = await _service.create(name: name, type: type);
      items = [...items, created];
      notifyListeners();
      return true;
    } catch (e) {
      error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> rename(CategoryModel category, String name) async {
    try {
      final updated = await _service.update(category.id, name: name);
      items = [for (final item in items) item.id == category.id ? updated : item];
      notifyListeners();
      return true;
    } catch (e) {
      error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(CategoryModel category) async {
    try {
      await _service.delete(category.id);
      items = items.where((item) => item.id != category.id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }
}
