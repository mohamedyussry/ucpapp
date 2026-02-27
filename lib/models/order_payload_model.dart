import 'line_item_model.dart';

class OrderPayload {
  final String paymentMethod;
  final String paymentMethodTitle;
  final bool setPaid;
  final BillingInfo billing;
  final ShippingInfo shipping;
  final List<LineItem> lineItems;
  final List<ShippingLine> shippingLines;
  final List<CouponLine> couponLines;
  final String? customerNote;
  final String? transactionId;
  final int? customerId;
  final String? status;

  OrderPayload({
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.setPaid,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    this.shippingLines = const [],
    this.couponLines = const [],
    this.customerNote,
    this.transactionId,
    this.customerId,
    this.status,
  });

  Map<String, dynamic> toJson() {
    // Build the full customer note: always mention the app source.
    const String appSourceNote = '📱 تم إنشاء هذا الطلب من تطبيق الجوال';
    final String fullNote = (customerNote != null && customerNote!.isNotEmpty)
        ? '$appSourceNote\n${customerNote!}'
        : appSourceNote;

    return {
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'set_paid': setPaid,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'shipping_lines': shippingLines.map((line) => line.toJson()).toList(),
      'coupon_lines': couponLines.map((line) => line.toJson()).toList(),
      'customer_note': fullNote,
      // Store as order meta so it appears in WC admin Order Details panel
      'meta_data': [
        {'key': '_order_source', 'value': 'mobile_app'},
        {'key': '_order_source_label', 'value': 'تطبيق الجوال'},
      ],
      if (transactionId != null) 'transaction_id': transactionId,
      if (customerId != null) 'customer_id': customerId,
      if (status != null) 'status': status,
    };
  }
}

class CouponLine {
  final String code;

  CouponLine({required this.code});

  Map<String, dynamic> toJson() => {'code': code};
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
