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

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'محفظة استثمارية',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
