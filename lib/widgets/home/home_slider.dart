import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/products_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

// نموذج موحد لعناصر السلايدر
class SliderItem {
  final String imageUrl;
  final String type; // 'category' or 'brand'
  final int id;
  final String name;

  SliderItem({
    required this.imageUrl,
    required this.type,
    required this.id,
    required this.name,
  });
}

class HomeSlider extends StatefulWidget {
  const HomeSlider({super.key});

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  final WooCommerceService _wooService = WooCommerceService();
  List<SliderItem> _sliderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // تأخير التنفيذ للتأكد من جاهزية الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchSliderData();
    });
  }

  Future<void> _fetchSliderData() async {
    try {
      // جلب الفئات والماركات بشكل متوازي
      final results = await Future.wait([
        _wooService.getCategories(),
        _wooService.getBrands(),
      ]);

      // تأكد من نوع البيانات قبل التحويل لتجنب أخطاء الـ casting
      final List<WooProductCategory> categories =
          results[0] is List<WooProductCategory>
          ? results[0] as List<WooProductCategory>
          : [];
      final List<WooBrand> brands = results[1] is List<WooBrand>
          ? results[1] as List<WooBrand>
          : [];

      List<SliderItem> items = [];

      // إضافة الفئات التي تظهر في السلايدر مع تحققات أمان إضافية
      for (var cat in categories) {
        if (cat.sliderData?.isFeatured == true &&
            cat.sliderData?.sliderImage != null &&
            cat.sliderData!.sliderImage!.isNotEmpty) {
          items.add(
            SliderItem(
              imageUrl: cat.sliderData!.sliderImage!,
              type: 'category',
              id: cat.id,
              name: cat.name,
            ),
          );
        }
      }

      // إضافة الماركات التي تظهر في السلايدر مع تحققات أمان إضافية
      for (var brand in brands) {
        if (brand.sliderData?.isFeatured == true &&
            brand.sliderData?.sliderImage != null &&
            brand.sliderData!.sliderImage!.isNotEmpty) {
          items.add(
            SliderItem(
              imageUrl: brand.sliderData!.sliderImage!,
              type: 'brand',
              id: brand.id,
              name: brand.name,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _sliderItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSliderTap(SliderItem item) {
    if (item.type == 'category') {
      // الانتقال إلى منتجات الفئة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductsScreen(categoryId: item.id, category: item.name),
        ),
      );
    } else if (item.type == 'brand') {
      // الانتقال إلى منتجات الماركة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductsScreen(brandId: item.id, brandName: item.name),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmer();
    }

    if (_sliderItems.isEmpty) {
      // Fallback static images if no categories/brands are marked for slider
      return _buildStaticSlider();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180.0,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.9,
        ),
        items: _sliderItems.map((item) {
          return GestureDetector(
            onTap: () => _handleSliderTap(item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                width: 1000,
                placeholder: (context, url) => _buildShimmer(),
                errorWidget: (context, url, error) => _buildErrorPlaceholder(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStaticSlider() {
    final List<String> imgList = [
      'https://ucpksa.com/wp-content/uploads/2024/01/banner1.jpg',
      'https://ucpksa.com/wp-content/uploads/2024/01/banner2.jpg',
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 180.0,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayCurve: Curves.fastOutSlowIn,
          enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          viewportFraction: 0.9,
        ),
        items: imgList.map((item) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: item,
              fit: BoxFit.cover,
              width: 1000,
              placeholder: (context, url) => _buildShimmer(),
              errorWidget: (context, url, error) => _buildErrorPlaceholder(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 1000,
      color: Colors.orange.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.image, color: Colors.orange, size: 50),
      ),
    );
  }
}
