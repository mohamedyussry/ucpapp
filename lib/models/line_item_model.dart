class LineItem {
  final int productId;
  final int quantity;
  final int? variationId;

  LineItem({
    required this.productId,
    required this.quantity,
    this.variationId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'quantity': quantity,
    };
    if (variationId != null) {
      data['variation_id'] = variationId;
    }
    return data;
  }
}
