import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 0)
class Order extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  late List<String> productNames;

  @HiveField(2)
  late double totalPrice;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  late String status;

  @HiveField(5)
  late String currency;

  @HiveField(6)
  late List<int> productIds;

  Order();

  factory Order.fromJson(Map<String, dynamic> json) {
    final order = Order();
    order.id = json['id'];
    order.status = json['status'] ?? 'unknown';
    order.totalPrice =
        double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0;
    order.date =
        DateTime.tryParse(json['date_created']?.toString() ?? '') ??
        DateTime.now();
    order.currency = json['currency']?.toString() ?? '';

    if (json['line_items'] != null && json['line_items'] is List) {
      final List<dynamic> items = json['line_items'];
      order.productNames = items
          .map((item) => item['name']?.toString() ?? 'Unnamed Product')
          .toList();
      order.productIds = items
          .map(
            (item) => int.tryParse(item['product_id']?.toString() ?? '0') ?? 0,
          )
          .where((id) => id > 0)
          .toList();
    } else {
      order.productNames = ['Unknown Products'];
      order.productIds = [];
    }

    return order;
  }
}
