import 'package:facebook_app_events/facebook_app_events.dart';

class MetaEventsService {
  static final MetaEventsService _instance = MetaEventsService._internal();

  factory MetaEventsService() {
    return _instance;
  }

  MetaEventsService._internal();

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  // 1. Search
  Future<void> logSearch(String query) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'Search',
        parameters: {
          'search_string': query,
          'success': 1,
        },
      );
      print('====== [Meta Events] logSearch: $query ======');
    } catch (e) {
      print('====== [Meta Events Error] logSearch: $e ======');
    }
  }

  // 2. Barcode Scan (Custom)
  Future<void> logBarcodeScan(String barcode, {bool success = true}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'BarcodeScan',
        parameters: {
          'barcode': barcode,
          'success': success ? 1 : 0,
        },
      );
      print('====== [Meta Events] logBarcodeScan: $barcode ======');
    } catch (e) {
      print('====== [Meta Events Error] logBarcodeScan: $e ======');
    }
  }

  // 3. View Content
  Future<void> logViewContent({
    required String contentId,
    required String contentType,
    double? price,
    String currency = 'SAR',
  }) async {
    try {
      await _facebookAppEvents.logViewContent(
        id: contentId,
        type: contentType,
        price: price,
        currency: currency,
      );
      print('====== [Meta Events] logViewContent: $contentId ======');
    } catch (e) {
      print('====== [Meta Events Error] logViewContent: $e ======');
    }
  }

  // 4. Add To Cart
  Future<void> logAddToCart({
    required String contentId,
    required String contentType,
    required double price,
    String currency = 'SAR',
  }) async {
    try {
      await _facebookAppEvents.logAddToCart(
        id: contentId,
        type: contentType,
        price: price,
        currency: currency,
      );
      print('====== [Meta Events] logAddToCart: $contentId ======');
    } catch (e) {
      print('====== [Meta Events Error] logAddToCart: $e ======');
    }
  }

  // 5. Initiate Checkout
  Future<void> logInitiateCheckout({
    required double totalPrice,
    required int numItems,
    String currency = 'SAR',
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'InitiateCheckout',
        parameters: {
          'num_items': numItems,
          'currency': currency,
        },
        valueToSum: totalPrice,
      );
      print('====== [Meta Events] logInitiateCheckout: $totalPrice ======');
    } catch (e) {
      print('====== [Meta Events Error] logInitiateCheckout: $e ======');
    }
  }

  // 6. Purchase
  Future<void> logPurchase({
    required double amount,
    required String orderId,
    String currency = 'SAR',
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          'order_id': orderId,
        },
      );
      print('====== [Meta Events] logPurchase: $orderId ======');
    } catch (e) {
      print('====== [Meta Events Error] logPurchase: $e ======');
    }
  }

  // 7. Contact
  Future<void> logContact(String method) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'Contact',
        parameters: {
          'method': method,
        },
      );
      print('====== [Meta Events] logContact: $method ======');
    } catch (e) {
      print('====== [Meta Events Error] logContact: $e ======');
    }
  }
}
