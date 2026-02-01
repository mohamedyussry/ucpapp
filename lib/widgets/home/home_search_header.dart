import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:myapp/widgets/cart_badge.dart';
import 'package:myapp/screens/profile_screen.dart';
import 'package:myapp/product_detail_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeSearchHeader extends StatefulWidget {
  const HomeSearchHeader({super.key});

  @override
  State<HomeSearchHeader> createState() => _HomeSearchHeaderState();
}

class _HomeSearchHeaderState extends State<HomeSearchHeader> {
  final WooCommerceService _wooService = WooCommerceService();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  List<WooProductCategory> _categories = [];
  WooProductCategory? _selectedCategory;
  List<WooProduct> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _hideOverlay();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48), // Adjust to appear below the search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 350),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _buildSearchResultsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    final l10n = AppLocalizations.of(context)!;
    return StatefulBuilder(
      builder: (context, setOverlayState) {
        if (_isSearching) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            ),
          );
        }

        if (_searchResults.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                l10n.results_not_found,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.images.first.src,
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                    title: Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${product.price?.toStringAsFixed(2) ?? "0.00"} ${l10n.currency_sar}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      _hideOverlay();
                      _searchController.clear();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            TextButton(
              onPressed: _hideOverlay,
              child: Text(
                l10n.close_search,
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _wooService.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        _hideOverlay();
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });
    _showOverlay();

    try {
      final results = await _wooService.getProducts(
        search: query,
        categoryId: _selectedCategory?.id,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.black87),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              Image.asset(
                'assets/home/logo.png',
                height: 35,
                errorBuilder: (context, error, stackTrace) => Text(
                  l10n.app_title,
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const CartBadge(),
            ],
          ),
          const SizedBox(height: 12),
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onTap: () {
                        if (_searchController.text.isNotEmpty) _showOverlay();
                      },
                      decoration: InputDecoration(
                        hintText: l10n.search_placeholder,
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  _buildCategoryDropdown(l10n),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WooProductCategory?>(
          value: _selectedCategory,
          hint: Text(
            l10n.all_categories,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.orange,
            size: 16,
          ),
          style: GoogleFonts.poppins(color: Colors.orange, fontSize: 11),
          onChanged: (WooProductCategory? newValue) {
            setState(() {
              _selectedCategory = newValue;
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            });
          },
          items: [
            DropdownMenuItem<WooProductCategory?>(
              value: null,
              child: Text(l10n.all_categories),
            ),
            ..._categories.map((cat) {
              return DropdownMenuItem<WooProductCategory?>(
                value: cat,
                child: Text(cat.name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
        ),
      ),
    );
  }
}
