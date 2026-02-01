import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/products_screen.dart';
import 'package:myapp/widgets/custom_bottom_nav_bar.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'l10n/generated/app_localizations.dart';

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen>
    with SingleTickerProviderStateMixin {
  final WooCommerceService _wooService = WooCommerceService();
  List<WooProductCategory> _allCategories = [];
  List<WooProductCategory> _mainCategories = [];
  bool _isLoading = true;
  int _selectedMainIndex = 0;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchCategories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _wooService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _mainCategories = categories.where((c) => c.parent == 0).toList();
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<WooProductCategory> _getSubCategories(int parentId) {
    return _allCategories.where((c) => c.parent == parentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _allCategories.isEmpty
            ? _buildEmptyState()
            : FadeTransition(
                opacity: _fadeController,
                child: _buildMainLayout(),
              ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Row(
          children: [
            Container(width: 100, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.no_categories_found,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLayout() {
    final selectedCategory = _mainCategories[_selectedMainIndex];
    final subCategories = _getSubCategories(selectedCategory.id);

    return Row(
      children: [
        // Sidebar
        _buildSidebar(),

        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildSubCategoryContent(selectedCategory, subCategories),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return GlassContainer.clearGlass(
      width: 100,
      height: double.infinity,
      borderWidth: 0,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.orange.withAlpha(20), Colors.deepOrange.withAlpha(10)],
      ),
      blur: 20,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: _mainCategories.length,
        itemBuilder: (context, index) {
          final category = _mainCategories[index];
          final isSelected = _selectedMainIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedMainIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.orange.withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  if (category.image != null)
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: category.image!.src,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.category, size: 20),
                      ),
                    )
                  else
                    Icon(
                      Icons.category,
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 24,
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryContent(
    WooProductCategory parent,
    List<WooProductCategory> subCategories,
  ) {
    return Column(
      key: ValueKey(parent.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parent.name,
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 3,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),

        // Hero Banner if no subs or just to look cool
        if (subCategories.isEmpty)
          Expanded(
            child: Center(child: _buildCategoryCard(parent, isHero: true)),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(subCategories[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
    WooProductCategory category, {
    bool isHero = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsScreen(category: category.name),
          ),
        );
      },
      child: Container(
        width: isHero ? double.infinity : null,
        margin: isHero ? const EdgeInsets.all(24) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              if (category.image != null)
                CachedNetworkImage(
                  imageUrl: category.image!.src,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.orange),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.orange.withAlpha(30),
                  child: Center(
                    child: Icon(
                      Icons.category,
                      size: isHero ? 64 : 32,
                      color: Colors.orange,
                    ),
                  ),
                ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(180)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Text
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isHero ? 22 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isHero) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.explore_collections,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          l10n.shop_now,
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
