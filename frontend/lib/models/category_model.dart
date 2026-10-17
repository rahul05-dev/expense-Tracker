class CategoryModel {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final String? color;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }
}
