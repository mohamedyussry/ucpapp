import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/models/product_model.dart';
import 'package:myapp/services/woocommerce_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/screens/barcode_scanner_screen.dart';
import 'package:myapp/product_detail_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/product_card.dart'; // Assuming there is a product card widget
import 'package:myapp/services/meta_events_service.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool isFromBarcode;
  const SearchScreen({super.key, this.initialQuery, this.isFromBarcode = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final WooCommerceService _wooService = WooCommerceService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<WooProduct> _searchResults = [];
  bool _isSearching = false;
  List<String> _searchHistory = [];
  List<WooProductCategory> _categories = [];
  WooProductCategory? _selectedCategory;
  Timer? _debounce;

  // Pagination Variables
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  // New Filter/Sort variables
  String _orderby = 'date';
  String _order = 'desc';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _fetchCategories();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      if (widget.isFromBarcode) {
        _handleBarcodeQuery(widget.initialQuery!, pushReplacement: true);
      } else {
        _performSearch(widget.initialQuery!);
      }
    }
    // Auto focus search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query); // Remove if exists to move to top
    history.insert(0, query);
    if (history.length > 10) history = history.sublist(0, 10);
    await prefs.setStringList('search_history', history);
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
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
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _hasMore = true;
          _currentPage = 1;
        });
      }
    });
  }

  Future<void> _loadMoreProducts() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isFetchingMore = true;
      _currentPage++;
    });

    try {
      final results = await _wooService.getProducts(
        search: query,
        categoryId: _selectedCategory?.id,
        orderby: _orderby,
        order: _order,
        perPage: 30,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (results.isEmpty || results.length < 30) {
            _hasMore = false;
          }
          _searchResults.addAll(results);
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingMore = false);
      }
    }
  }
  
  Future<void> _scanBarcode() async {
    var res = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ));
    if (res != null && res.isNotEmpty) {
      _searchController.text = res;
      _handleBarcodeQuery(res, pushReplacement: false);
    }
  }

  Future<void> _handleBarcodeQuery(String res, {required bool pushReplacement}) async {
    final bool isNumeric = RegExp(r'^\d+$').hasMatch(res.trim());
    if (isNumeric) {
      setState(() => _isSearching = true);
      try {
        final results = await _wooService.getProducts(
          search: res,
          perPage: 2, // Check if there's more than one result
        );
        
        if (mounted) {
          setState(() => _isSearching = false);
          if (results.length == 1) {
            // Also update current search results so the item is there if user goes back
            setState(() {
              _searchResults = results;
              _currentPage = 1;
              _hasMore = false;
            });
            _saveSearchQuery(res);
            
            // Direct navigation to product details
            if (pushReplacement) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: results[0]),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: results[0]),
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    }
    
    // Default to showing search results list if no single match found
    _performSearch(res);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final results = await _wooService.getProducts(
        search: query,
        categoryId: _selectedCategory?.id,
        orderby: _orderby,
        order: _order,
        perPage: 30,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasMore = results.length == 30;
        });
        _saveSearchQuery(query);
        MetaEventsService().logSearch(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchBar(l10n),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () => _showSortBottomSheet(l10n),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySlider(l10n),
          const Divider(height: 1),
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSearchHistory(l10n)
                : _buildSearchResults(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      height: 45,
      // margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.search_placeholder,
          hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.orange, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.orange, size: 22),
            onPressed: _scanBarcode,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  void _showSortBottomSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sort_by,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildSortOption(l10n.newest, 'date', 'desc'),
              _buildSortOption(l10n.price_low_high, 'price', 'asc'),
              _buildSortOption(l10n.price_high_low, 'price', 'desc'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String orderby, String order) {
    bool isSelected = _orderby == orderby && _order == order;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.orange : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.orange)
          : null,
      onTap: () {
        setState(() {
          _orderby = orderby;
          _order = order;
        });
        Navigator.pop(context);
        if (_searchController.text.isNotEmpty)
          _performSearch(_searchController.text);
      },
    );
  }

  Widget _buildCategorySlider(AppLocalizations l10n) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : _categories[index - 1];
          final isSelected = _selectedCategory?.id == category?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
                if (_searchController.text.isNotEmpty)
                  _performSearch(_searchController.text);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.grey[50],
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    isAll ? l10n.all_categories : category!.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHistory(AppLocalizations l10n) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              l10n.search_placeholder,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recent_searches,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            TextButton(
              onPressed: _clearSearchHistory,
              child: Text(
                l10n.clear_all,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: _searchHistory.map((query) {
            return ActionChip(
              label: Text(query, style: GoogleFonts.poppins(fontSize: 12)),
              onPressed: () {
                _searchController.text = query;
                _performSearch(query);
              },
              backgroundColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[200]!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.results_not_found,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(product: product);
            },
          ),
        ),
        if (_isFetchingMore)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.orange),
          ),
      ],
    );
  }
}
