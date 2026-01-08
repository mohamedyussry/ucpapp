
class WooProduct {
  final int id;
  final String name;
  final String type;
  final String? price;
  final String? salePrice;
  final String? regularPrice;
  final String description;
  final String permalink;
  final List<WooProductImage> images;
  final List<WooProductCategory> categories;
  final List<WooProductAttribute> attributes;
  final String stockStatus;
  final int? stockQuantity;
  final String averageRating;
  final int ratingCount;

  WooProduct({
    required this.id,
    required this.name,
    required this.type,
    this.price,
    this.salePrice,
    this.regularPrice,
    required this.description,
    required this.permalink,
    required this.images,
    required this.categories,
    required this.attributes,
    required this.stockStatus,
    this.stockQuantity,
    required this.averageRating,
    required this.ratingCount,
  });

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    return WooProduct(
      id: json['id'],
      name: json['name'],
      type: json['type'] ?? 'simple',
      price: json['price'],
      salePrice: json['sale_price'],
      regularPrice: json['regular_price'],
      description: json['description'] ?? '',
      permalink: json['permalink'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((imgJson) => WooProductImage.fromJson(imgJson))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((catJson) => WooProductCategory.fromJson(catJson))
              .toList() ??
          [],
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((attrJson) => WooProductAttribute.fromJson(attrJson))
              .toList() ??
          [],
      stockStatus: json['stock_status'] ?? 'outofstock',
      stockQuantity: json['stock_quantity'],
      averageRating: json['average_rating'] ?? '0.0',
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'sale_price': salePrice,
      'regular_price': regularPrice,
      'description': description,
      'permalink': permalink,
      'images': images.map((img) => img.toJson()).toList(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'stock_status': stockStatus,
      'stock_quantity': stockQuantity,
      'average_rating': averageRating,
      'rating_count': ratingCount,
    };
  }
}

class WooProductImage {
  final int id;
  final String src;
  final String name;

  WooProductImage({
    required this.id,
    required this.src,
    required this.name,
  });

  factory WooProductImage.fromJson(Map<String, dynamic> json) {
    return WooProductImage(
      id: json['id'],
      src: json['src'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'name': name,
    };
  }
}

class WooProductCategory {
  final int id;
  final String name;

  WooProductCategory({required this.id, required this.name});

  factory WooProductCategory.fromJson(Map<String, dynamic> json) {
    return WooProductCategory(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class WooProductAttribute {
  final int id;
  final String name;
  final List<String> options;

  WooProductAttribute({
    required this.id,
    required this.name,
    required this.options,
  });

  factory WooProductAttribute.fromJson(Map<String, dynamic> json) {
    return WooProductAttribute(
      id: json['id'],
      name: json['name'] ?? '',
      options: List<String>.from(json['options'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options,
    };
  }
}

class WooProductVariation {
  final int id;
  final String? price;
  final String? regularPrice;
  final String? salePrice;
  final WooProductImage? image;
  final List<Map<String, dynamic>> attributes;
  final String stockStatus;
  final int? stockQuantity;

  WooProductVariation({
    required this.id,
    this.price,
    this.regularPrice,
    this.salePrice,
    this.image,
    required this.attributes,
    required this.stockStatus,
    this.stockQuantity,
  });

  factory WooProductVariation.fromJson(Map<String, dynamic> json) {
    return WooProductVariation(
      id: json['id'],
      price: json['price'],
      regularPrice: json['regular_price'],
      salePrice: json['sale_price'],
      image: json['image'] != null ? WooProductImage.fromJson(json['image']) : null,
      attributes: List<Map<String, dynamic>>.from(json['attributes'] ?? []),
      stockStatus: json['stock_status'] ?? 'outofstock',
      stockQuantity: json['stock_quantity'],
    );
  }
}
