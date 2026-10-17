import '../models/category_model.dart';
import 'api_client.dart';

class CategoryService {
  CategoryService(this._api);

  final ApiClient _api;

  Future<List<CategoryModel>> list({String? type}) async {
    final data = await _api.get('/categories', query: {'type': type});
    return (data as List)
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<CategoryModel> create({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final data = await _api.post(
      '/categories',
      body: {'name': name, 'type': type, 'icon': icon, 'color': color},
    );
    return CategoryModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<CategoryModel> update(String id, {String? name, String? icon, String? color}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (color != null) body['color'] = color;

    final data = await _api.put('/categories/$id', body: body);
    return CategoryModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> delete(String id) async {
    await _api.delete('/categories/$id');
  }
}
