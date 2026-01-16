
class Coupon {
  final int id;
  final String code;
  final String amount;
  final String discountType;
  final String? dateExpires;
  final String minimumAmount;
  final String maximumAmount;

  Coupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.discountType,
    this.dateExpires,
    required this.minimumAmount,
    required this.maximumAmount,
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
    );
  }
}
