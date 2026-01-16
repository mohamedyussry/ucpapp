
import 'line_item_model.dart';

class OrderPayload {
  final String paymentMethod;
  final String paymentMethodTitle;
  final bool setPaid;
  final BillingInfo billing;
  final ShippingInfo shipping;
  final List<LineItem> lineItems;
  final List<ShippingLine> shippingLines;
  final String? customerNote;
  final String? transactionId;
  final int? customerId;
  final String? status; // Add this line

  OrderPayload({
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.setPaid,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    this.shippingLines = const [],
    this.customerNote,
    this.transactionId,
    this.customerId,
    this.status, // Add this line
  });

  Map<String, dynamic> toJson() => {
        'payment_method': paymentMethod,
        'payment_method_title': paymentMethodTitle,
        'set_paid': setPaid,
        'billing': billing.toJson(),
        'shipping': shipping.toJson(),
        'line_items': lineItems.map((item) => item.toJson()).toList(),
        'shipping_lines': shippingLines.map((line) => line.toJson()).toList(),
        if (customerNote != null && customerNote!.isNotEmpty) 'customer_note': customerNote,
        if (transactionId != null) 'transaction_id': transactionId,
        if (customerId != null) 'customer_id': customerId,
        if (status != null) 'status': status, // Add this line
      };
}

class BillingInfo {
  final String firstName;
  final String lastName;
  final String address1;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  BillingInfo({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address1,
        'city': city,
        'state': state,
        'postcode': postcode,
        'country': country,
        'email': email,
        'phone': phone,
      };
}

class ShippingInfo {
  final String firstName;
  final String lastName;
  final String address1;
  final String city;
  final String state;
  final String postcode;
  final String country;

  ShippingInfo({
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  // Factory constructor to create ShippingInfo from BillingInfo
  factory ShippingInfo.fromBilling(BillingInfo billing) {
    return ShippingInfo(
      firstName: billing.firstName,
      lastName: billing.lastName,
      address1: billing.address1,
      city: billing.city,
      state: billing.state,
      postcode: billing.postcode,
      country: billing.country,
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'address_1': address1,
        'city': city,
        'state': state,
        'postcode': postcode,
        'country': country,
      };
}

class ShippingLine {
  final String methodId;
  final String methodTitle;
  final String total;

  ShippingLine({
    required this.methodId,
    required this.methodTitle,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'method_id': methodId,
    'method_title': methodTitle,
    'total': total,
  };
}
