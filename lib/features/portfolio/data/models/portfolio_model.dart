import 'portfolio_item_model.dart';

class PortfolioModel {
  final String id;
  final String name;
  final List<PortfolioItem> items;
  final DateTime createdAt;

  PortfolioModel({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['portfolio_items'] ?? json['items'];
    return PortfolioModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'محفظة استثمارية',
      items: (rawItems as List<dynamic>?)
              ?.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
