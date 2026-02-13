class WooProduct {
  final int id;
  final String name;
  final String type;
  final double? price;
  final double? salePrice;
  final double? regularPrice;
  final String description;
  final String permalink;
  final List<WooProductImage> images;
  final List<WooProductCategory> categories;
  final List<WooProductAttribute> attributes;
  final String stockStatus;
  final int? stockQuantity;
  final double averageRating;
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
      price: double.tryParse(json['price']?.toString() ?? ''),
      salePrice: double.tryParse(json['sale_price']?.toString() ?? ''),
      regularPrice: double.tryParse(json['regular_price']?.toString() ?? ''),
      description: json['description'] ?? '',
      permalink: json['permalink'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((imgJson) => WooProductImage.fromJson(imgJson))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((catJson) => WooProductCategory.fromJson(catJson))
              .toList() ??
          [],
      attributes:
          (json['attributes'] as List<dynamic>?)
              ?.map((attrJson) => WooProductAttribute.fromJson(attrJson))
              .toList() ??
          [],
      stockStatus: json['stock_status'] ?? 'outofstock',
      stockQuantity: json['stock_quantity'],
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0.0') ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price?.toString(),
      'sale_price': salePrice?.toString(),
      'regular_price': regularPrice?.toString(),
      'description': description,
      'permalink': permalink,
      'images': images.map((img) => img.toJson()).toList(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'attributes': attributes.map((attr) => attr.toJson()).toList(),
      'stock_status': stockStatus,
      'stock_quantity': stockQuantity,
      'average_rating': averageRating.toString(),
      'rating_count': ratingCount,
    };
  }
}

class WooProductImage {
  final int id;
  final String src;
  final String name;

  WooProductImage({required this.id, required this.src, required this.name});

  factory WooProductImage.fromJson(Map<String, dynamic> json) {
    return WooProductImage(
      id: json['id'] is int ? json['id'] : 0,
      src: json['src']?.toString() ?? json['url']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'src': src, 'name': name};
  }
}

class WooProductCategory {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final WooProductImage? image;
  final WooSliderData? sliderData;

  WooProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parent = 0,
    this.image,
    this.sliderData,
  });

  factory WooProductCategory.fromJson(Map<String, dynamic> json) {
    return WooProductCategory(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parent: json['parent'] ?? 0,
      image: json['image'] != null && json['image'] is Map<String, dynamic>
          ? WooProductImage.fromJson(json['image'])
          : null,
      sliderData: json['slider_data'] != null
          ? WooSliderData.fromJson(json['slider_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent': parent,
      'image': image?.toJson(),
      'slider_data': sliderData?.toJson(),
    };
  }
}

class WooSliderData {
  final bool isFeatured;
  final String? sliderImage;

  WooSliderData({required this.isFeatured, this.sliderImage});

  factory WooSliderData.fromJson(Map<String, dynamic> json) {
    return WooSliderData(
      isFeatured: json['is_featured'] ?? false,
      sliderImage: json['slider_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'is_featured': isFeatured, 'slider_image': sliderImage};
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
    return {'id': id, 'name': name, 'options': options};
  }
}

class WooProductVariation {
  final int id;
  final double? price;
  final double? regularPrice;
  final double? salePrice;
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
      price: double.tryParse(json['price']?.toString() ?? ''),
      regularPrice: double.tryParse(json['regular_price']?.toString() ?? ''),
      salePrice: double.tryParse(json['sale_price']?.toString() ?? ''),
      image: json['image'] != null
          ? WooProductImage.fromJson(json['image'])
          : null,
      attributes: List<Map<String, dynamic>>.from(json['attributes'] ?? []),
      stockStatus: json['stock_status'] ?? 'outofstock',
      stockQuantity: json['stock_quantity'],
    );
  }
}

class WooBrand {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final WooProductImage? image;
  final bool isVisibleInApp;
  final WooSliderData? sliderData;

  WooBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.isVisibleInApp = true,
    this.sliderData,
  });

  factory WooBrand.fromJson(Map<String, dynamic> json) {
    WooProductImage? brandImage;

    final rawImage = json['image'] ?? json['thumbnail'];

    if (rawImage != null) {
      if (rawImage is Map<String, dynamic>) {
        brandImage = WooProductImage.fromJson(rawImage);
      } else if (rawImage is String && rawImage.isNotEmpty) {
        brandImage = WooProductImage(
          id: 0,
          src: rawImage,
          name: json['name'] ?? '',
        );
      }
    }

    final appSettings = json['app_settings'];
    bool showInApp = true;
    if (appSettings != null && appSettings is Map<String, dynamic>) {
      showInApp = appSettings['show_in_app'] ?? true;
    }

    return WooBrand(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      image: brandImage,
      isVisibleInApp: showInApp,
      sliderData: json['slider_data'] != null
          ? WooSliderData.fromJson(json['slider_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image?.toJson(),
      'is_visible_in_app': isVisibleInApp,
      'slider_data': sliderData?.toJson(),
    };
  }
}
