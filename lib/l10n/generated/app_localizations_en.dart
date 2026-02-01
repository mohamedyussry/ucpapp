// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'UCP PHARMACY';

  @override
  String get home => 'Home';

  @override
  String get categories => 'Categories';

  @override
  String get orders => 'Orders';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get search_products => 'Search Products';

  @override
  String get best_sellers => 'Best Sellers';

  @override
  String get new_arrivals => 'New Arrivals';

  @override
  String get see_all => 'See All';

  @override
  String get shop_by_category => 'Shop by Category';

  @override
  String get shop_by_brands => 'Shop by Brands';

  @override
  String get loyalty_program => 'Loyalty Program';

  @override
  String get personal_info => 'Personal Information';

  @override
  String get my_orders => 'My Orders';

  @override
  String get my_points => 'My Points';

  @override
  String get language => 'Language';

  @override
  String get about_app => 'About App';

  @override
  String get help_support => 'Help & Support';

  @override
  String get logout => 'Logout';

  @override
  String get edit_profile => 'Edit Profile';

  @override
  String get my_account => 'My Account';

  @override
  String get notification => 'Notification';

  @override
  String get push_notification => 'Push Notification';

  @override
  String get sync_notifications => 'Sync Notifications';

  @override
  String get select_language => 'Select Language';

  @override
  String get search_placeholder => 'Search for products...';

  @override
  String get all_categories => 'All Categories';

  @override
  String get results_not_found => 'No results found';

  @override
  String get close_search => 'Close Search';

  @override
  String get add_to_cart => 'Add to cart';

  @override
  String get reviews => 'Reviews';

  @override
  String get in_stock => 'In stock';

  @override
  String get out_of_stock => 'Out of stock';

  @override
  String get free_delivery => 'Free Delivery';

  @override
  String get available_in_store => 'Available in nearest store';

  @override
  String get added_to_cart => 'Added to Cart!';

  @override
  String get sar => 'SAR';

  @override
  String get no_categories_found => 'No categories found';

  @override
  String get retry => 'Retry';

  @override
  String get explore_collections => 'Explore all collections';

  @override
  String get products => 'Products';

  @override
  String get failed_load_products =>
      'Failed to load products. Please try again later.';

  @override
  String get no_products_matching => 'No products found matching your search.';

  @override
  String get shop_now => 'SHOP NOW';

  @override
  String get no_products_available => 'No products available.';

  @override
  String get brands => 'Brands';

  @override
  String get no_brands_found => 'No brands found';

  @override
  String get connection_failed => 'Connection Failed';

  @override
  String get unknown_error => 'Unknown error';

  @override
  String get close => 'Close';

  @override
  String get phone_login => 'Phone Login';

  @override
  String get enter_phone_subtitle =>
      'Enter your phone number to receive a verification code.';

  @override
  String get phone_number => 'Phone Number';

  @override
  String get enter_phone_hint => '5XXXXXXXX';

  @override
  String get err_enter_phone => 'Please enter your phone number';

  @override
  String get err_invalid_phone => 'Please enter a valid 9-digit mobile number';

  @override
  String get send_code => 'Send Code';

  @override
  String get login_email => 'Login with Email & Password';

  @override
  String get login_guest => 'Login as Guest';

  @override
  String get syncing => 'Syncing...';

  @override
  String get sync_success => 'Notifications synced successfully!';

  @override
  String get sync_failed => 'Failed to sync notifications.';

  @override
  String get otp_resent => 'Verification code sent again!';

  @override
  String get otp_failed_resend => 'Failed to resend';

  @override
  String get otp_enter_full => 'Please enter the full 4-digit code';

  @override
  String get otp_invalid => 'Invalid code';

  @override
  String get otp_title => 'Verification Code';

  @override
  String get otp_subtitle => 'We have sent the verification code to';

  @override
  String get otp_your_phone => 'your phone';

  @override
  String get verify => 'Verify';

  @override
  String get resend_code => 'Resend Code';

  @override
  String get resend_in => 'Resend code in ';

  @override
  String get currency_sar => 'SAR';

  @override
  String get loyalty_card => 'Loyalty Card';

  @override
  String get boost_points => 'Boost Your Points';

  @override
  String get double_discounts => '& Multiply Double Your Discounts';

  @override
  String points_conversion(String points) {
    return 'Every 10 SAR = $points Points';
  }

  @override
  String get points_value => 'Every 10 Points = 1 SAR';

  @override
  String get tier_basic => 'Basic';

  @override
  String get tier_plus => 'Plus';

  @override
  String get tier_premium => 'Premium';

  @override
  String get tier_elite => 'Elite';

  @override
  String get condition_plus =>
      'Reach 2,000 SAR in purchases within a year to unlock.';

  @override
  String get condition_premium =>
      'Reach 5,000 SAR in purchases within a year to unlock.';

  @override
  String get condition_elite =>
      'Reach 10,000 SAR in purchases within a year to unlock.';

  @override
  String get cat_for_baby => 'For Baby';

  @override
  String get cat_for_her => 'For Her';

  @override
  String get cat_for_him => 'For Him';

  @override
  String get cat_medicine => 'Medicine';

  @override
  String get my_cart => 'My Cart';

  @override
  String get cart_empty => 'Your cart is empty';

  @override
  String removed_from_cart(String product) {
    return '$product removed from cart';
  }

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Checkout';

  @override
  String get enter_discount_code => 'Enter Discount Code';

  @override
  String get apply => 'Apply';

  @override
  String coupon_applied(String code) {
    return 'Coupon applied: $code';
  }

  @override
  String get place_order => 'Place Order';

  @override
  String get continue_step => 'Continue';

  @override
  String get shipping => 'Shipping';

  @override
  String get payment => 'Payment';

  @override
  String get review => 'Review';

  @override
  String get shipping_details => 'Shipping Details';

  @override
  String get first_name => 'First Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get address => 'Address';

  @override
  String get email => 'Email';

  @override
  String get select_location_map => 'Select Location on Map';

  @override
  String get select_region => 'Select Region';

  @override
  String get shipping_to => 'Shipping To';

  @override
  String get payment_method => 'Payment Method';

  @override
  String get order_notes => 'Order Notes';

  @override
  String get order_notes_hint => 'Notes about your order...';

  @override
  String get final_review => 'Final Review';

  @override
  String get order_summary => 'Order Summary';

  @override
  String get no_payment_methods => 'No payment methods available.';

  @override
  String get please_select_payment => 'Please select a payment method.';

  @override
  String get payment_init_failed =>
      'Failed to initialize payment. Please try again.';

  @override
  String get payment_failed => 'Payment failed or cancelled.';

  @override
  String get order_failed => 'Failed to place order. Please try again.';

  @override
  String err_please_enter(String field) {
    return 'Please enter $field';
  }

  @override
  String get err_invalid_email => 'Please enter a valid email address';

  @override
  String get coupon_invalid => 'Invalid coupon code';

  @override
  String get coupon_expired => 'This coupon has expired';

  @override
  String get coupon_removed => 'Coupon removed';

  @override
  String get tab_ongoing => 'Ongoing';

  @override
  String get tab_completed => 'Completed';

  @override
  String get tab_cancelled => 'Cancelled';

  @override
  String get no_ongoing_orders => 'No ongoing orders yet.';

  @override
  String get no_completed_orders => 'No completed orders yet.';

  @override
  String get no_cancelled_orders => 'No cancelled orders yet.';

  @override
  String order_number(Object id) {
    return 'Order #$id';
  }

  @override
  String price_label(String price, String currency) {
    return 'Price: $price $currency';
  }

  @override
  String get track_btn => 'Track';

  @override
  String get details_btn => 'Details';

  @override
  String get view_details_link => 'View details';

  @override
  String get order_again_btn => 'Order again';

  @override
  String get rate_label => 'Rate';

  @override
  String get err_no_products_reorder => 'No products found to re-order.';

  @override
  String msg_products_added_cart(int count) {
    return '$count products added to cart.';
  }

  @override
  String get err_products_not_found =>
      'Failed to find products. They might be out of stock.';

  @override
  String err_reordering(Object error) {
    return 'Error re-ordering: $error';
  }

  @override
  String err_loading_orders(Object error) {
    return 'Failed to load orders: $error';
  }

  @override
  String get err_load_order_details => 'Could not load order details';

  @override
  String get go_back => 'Go Back';

  @override
  String get loading_order_tracking => 'Loading order tracking...';

  @override
  String wishlist_title(int count) {
    return 'Your Wishlist ($count)';
  }

  @override
  String get wishlist_empty =>
      'You haven\'t added any products to your Wishlist yet!';

  @override
  String get shop_by_categories_btn => 'Shop by Categories';

  @override
  String get profile_updated => 'Profile updated successfully';

  @override
  String get profile_update_failed => 'Failed to update profile';

  @override
  String get edit_photo => 'Edit Photo';

  @override
  String get remove_btn => 'Remove';

  @override
  String get personal_details => 'Personal Details';

  @override
  String get billing_address => 'Billing Address';

  @override
  String get contact_details => 'Contact Details';

  @override
  String get company_label => 'Company';

  @override
  String get address1_label => 'Address Line 1';

  @override
  String get address2_label => 'Address Line 2';

  @override
  String get city_label => 'City';

  @override
  String get postcode_label => 'Postcode';

  @override
  String get country_label => 'Country';

  @override
  String get state_label => 'State/Region';

  @override
  String get discard_btn => 'Discard';

  @override
  String get save_changes_btn => 'Save Changes';

  @override
  String get loyalty_rewards_title => 'Loyalty Rewards';

  @override
  String get welcome_rewards => 'Welcome to UCP Rewards';

  @override
  String get points_history => 'Points History';

  @override
  String get refresh => 'Refresh';

  @override
  String get no_history_found => 'No history found.';

  @override
  String get loyalty_card_label => 'Loyalty Card';

  @override
  String get current_points => 'Current Points';

  @override
  String get ucp_loyalty_program => 'UCP Loyalty Program';

  @override
  String get active_account => 'Active Account';

  @override
  String get pts_suffix => 'Pts';

  @override
  String get choose_language => 'Choose Language';

  @override
  String get continue_btn => 'Continue';

  @override
  String get welcome_back => 'Welcome Back';

  @override
  String get login_to_account => 'Login to your account';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get please_enter_username => 'Please enter your username';

  @override
  String get please_enter_password => 'Please enter your password';

  @override
  String get login_btn => 'Login';

  @override
  String get no_account_signup => 'Don\'t have an account? Sign up';

  @override
  String get back_to_phone_login => 'Back to Phone Login';

  @override
  String get continue_as_guest => 'Continue as Guest';

  @override
  String get order_confirmed => 'Order Confirmed';

  @override
  String get thank_you_order => 'Thank You For Your Order!';

  @override
  String get order_placed_successfully =>
      'Your order has been placed successfully.';

  @override
  String get order_details => 'Order Details';

  @override
  String get order_id_label => 'Order ID:';

  @override
  String get date_label => 'Date:';

  @override
  String get payment_method_label => 'Payment Method:';

  @override
  String get status_label => 'Status:';

  @override
  String get shipping_address_label => 'Shipping Address';

  @override
  String get order_summary_label => 'Order Summary';

  @override
  String get total_label => 'Total';

  @override
  String get continue_shopping => 'Continue Shopping';

  @override
  String get order_tracking_title => 'Order Tracking';

  @override
  String get image_not_found => 'Image not found';

  @override
  String get order_id_colon => 'Order ID :';

  @override
  String get received_status => 'Received';

  @override
  String get on_the_way_status => 'On the Way';

  @override
  String get delivered_status => 'Delivered';

  @override
  String get products_label => 'Products';

  @override
  String get order_label => 'Order';

  @override
  String get create_account => 'Create Account';

  @override
  String get please_enter_first_name => 'Please enter your first name';

  @override
  String get please_enter_last_name => 'Please enter your last name';

  @override
  String get please_enter_email => 'Please enter your email';

  @override
  String get please_enter_valid_email => 'Please enter a valid email';

  @override
  String get please_enter_password_signup => 'Please enter a password';

  @override
  String get password_min_length => 'Password must be at least 6 characters';

  @override
  String get register_btn => 'Register';

  @override
  String get registration_successful =>
      'Registration successful! Please log in.';

  @override
  String get registration_failed =>
      'Registration failed. The email might already be in use.';

  @override
  String error_occurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get what_can_we_help => 'What can we help you find?';

  @override
  String get delivery_to => 'Delivery to';

  @override
  String get change_btn => 'Change';

  @override
  String get bestseller => 'Bestseller';

  @override
  String get popular_brands => 'Popular Brands';

  @override
  String get select_delivery_location => 'Select Delivery Location';

  @override
  String get move_map_to_select => 'Move the map to select your location';

  @override
  String get confirm_location => 'Confirm Location';

  @override
  String get payment_title => 'Payment';
}
