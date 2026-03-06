import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/products_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/product_detail_screen.dart';

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
      // جلب جميع عناصر السلايدر (فئات + ماركات + منتجات) بطلب واحد موحد
      final items = await _wooService.getSliderItems();

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

  Future<void> _handleSliderTap(SliderItem item) async {
    if (item.type == 'category') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductsScreen(categoryId: item.id, category: item.name),
        ),
      );
    } else if (item.type == 'brand') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductsScreen(brandId: item.id, brandName: item.name),
        ),
      );
    } else if (item.type == 'product') {
      // إظهار مؤشر تحميل بسيط عند جلب تفاصيل المنتج
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      try {
        // جلب تفاصيل المنتج بالكامل باستخدام الـ ID مباشرة لضمان الدقة
        final fullProduct = await _wooService.getProductById(item.id);

        if (mounted) {
          Navigator.pop(context); // إغلاق مؤشر التحميل

          if (fullProduct != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: fullProduct),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('المنتج غير متوفر حالياً')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('عذراً، حدث خطأ أثناء تحميل بيانات المنتج'),
            ),
          );
        }
      }
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
