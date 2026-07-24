class PortfolioTransaction {
  final String? id;
  final String userId;
  final String fundId;
  final double units;
  final double purchasePrice;
  final DateTime transactionDate;

  // We'll also store the fund's current details if joined from the db
  final String? fundNameAr;
  final String? fundNameEn;

  PortfolioTransaction({
    this.id,
    required this.userId,
    required this.fundId,
    required this.units,
    required this.purchasePrice,
    required this.transactionDate,
    this.fundNameAr,
    this.fundNameEn,
  });

  factory PortfolioTransaction.fromJson(Map<String, dynamic> json) {
    return PortfolioTransaction(
      id: json['id'],
      userId: json['user_id'],
      fundId: json['fund_id'],
      units: (json['units'] as num).toDouble(),
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transaction_date']),
      fundNameAr: json['funds']?['name_ar'],
      fundNameEn: json['funds']?['name_en'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'fund_id': fundId,
      'units': units,
      'purchase_price': purchasePrice,
      'transaction_date': transactionDate.toIso8601String(),
    };
  }
}
