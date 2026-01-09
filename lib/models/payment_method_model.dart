
class PaymentMethod {
  final String id;
  final String title;
  final String description;
  final bool enabled;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }
}
