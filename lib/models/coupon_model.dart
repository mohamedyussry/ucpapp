class Coupon {
  final int id;
  final String code;
  final String amount;
  final String discountType;
  final String? dateExpires;
  final String minimumAmount;
  final String maximumAmount;

  final List<int> productIds;
  final List<int> excludedProductIds;
  final List<int> productCategories;
  final List<int> excludedProductCategories;

  final int? usageLimitPerUser;
  final List<String> usedBy;

  Coupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.discountType,
    this.dateExpires,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.productIds,
    required this.excludedProductIds,
    required this.productCategories,
    required this.excludedProductCategories,
    this.usageLimitPerUser,
    required this.usedBy,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int,
      code: json['code'] as String,
      amount: json['amount'] as String,
      discountType: json['discount_type'] as String,
      dateExpires: json['date_expires_gmt'] as String?,
      minimumAmount: json['minimum_amount'] as String,
      maximumAmount: json['maximum_amount'] as String,
      productIds: List<int>.from(json['product_ids'] ?? []),
      excludedProductIds: List<int>.from(json['excluded_product_ids'] ?? []),
      productCategories: List<int>.from(json['product_categories'] ?? []),
      excludedProductCategories: List<int>.from(
        json['excluded_product_categories'] ?? [],
      ),
      usageLimitPerUser: json['usage_limit_per_user'] as int?,
      usedBy: List<String>.from(
        (json['used_by'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
    );
  }
}
