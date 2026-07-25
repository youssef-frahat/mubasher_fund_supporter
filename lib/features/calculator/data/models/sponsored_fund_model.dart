class SponsoredFundModel {
  final String id;
  final String categoryType;
  final String sponsorName;
  final String badgeLabel;
  final bool isActive;

  SponsoredFundModel({
    required this.id,
    required this.categoryType,
    required this.sponsorName,
    required this.badgeLabel,
    required this.isActive,
  });

  factory SponsoredFundModel.fromJson(Map<String, dynamic> json) {
    return SponsoredFundModel(
      id: json['id'] ?? '',
      categoryType: json['category_type'] ?? '',
      sponsorName: json['sponsor_name'] ?? 'صندوق مميز',
      badgeLabel: json['badge_label'] ?? 'موصى به',
      isActive: json['is_active'] ?? true,
    );
  }
}
