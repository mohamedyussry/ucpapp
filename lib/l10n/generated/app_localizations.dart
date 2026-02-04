import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'UCP PHARMACY'**
  String get app_title;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search_products.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get search_products;

  /// No description provided for @best_sellers.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get best_sellers;

  /// No description provided for @new_arrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get new_arrivals;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get see_all;

  /// No description provided for @shop_by_category.
  ///
  /// In en, this message translates to:
  /// **'Shop by Category'**
  String get shop_by_category;

  /// No description provided for @shop_by_brands.
  ///
  /// In en, this message translates to:
  /// **'Shop by Brands'**
  String get shop_by_brands;

  /// No description provided for @loyalty_program.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Program'**
  String get loyalty_program;

  /// No description provided for @personal_info.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personal_info;

  /// No description provided for @my_orders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get my_orders;

  /// No description provided for @my_points.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get my_points;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get about_app;

  /// No description provided for @help_support.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help_support;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @my_account.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get my_account;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @push_notification.
  ///
  /// In en, this message translates to:
  /// **'Push Notification'**
  String get push_notification;

  /// No description provided for @sync_notifications.
  ///
  /// In en, this message translates to:
  /// **'Sync Notifications'**
  String get sync_notifications;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search for products...'**
  String get search_placeholder;

  /// No description provided for @all_categories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get all_categories;

  /// No description provided for @results_not_found.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get results_not_found;

  /// No description provided for @close_search.
  ///
  /// In en, this message translates to:
  /// **'Close Search'**
  String get close_search;

  /// No description provided for @add_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get add_to_cart;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @in_stock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get in_stock;

  /// No description provided for @out_of_stock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get out_of_stock;

  /// No description provided for @free_delivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get free_delivery;

  /// No description provided for @available_in_store.
  ///
  /// In en, this message translates to:
  /// **'Available in nearest store'**
  String get available_in_store;

  /// No description provided for @added_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Added to Cart!'**
  String get added_to_cart;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @no_categories_found.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get no_categories_found;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @explore_collections.
  ///
  /// In en, this message translates to:
  /// **'Explore all collections'**
  String get explore_collections;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @failed_load_products.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products. Please try again later.'**
  String get failed_load_products;

  /// No description provided for @no_products_matching.
  ///
  /// In en, this message translates to:
  /// **'No products found matching your search.'**
  String get no_products_matching;

  /// No description provided for @shop_now.
  ///
  /// In en, this message translates to:
  /// **'SHOP NOW'**
  String get shop_now;

  /// No description provided for @no_products_available.
  ///
  /// In en, this message translates to:
  /// **'No products available.'**
  String get no_products_available;

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @no_brands_found.
  ///
  /// In en, this message translates to:
  /// **'No brands found'**
  String get no_brands_found;

  /// No description provided for @connection_failed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connection_failed;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknown_error;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @phone_login.
  ///
  /// In en, this message translates to:
  /// **'Phone Login'**
  String get phone_login;

  /// No description provided for @enter_phone_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code.'**
  String get enter_phone_subtitle;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @enter_phone_hint.
  ///
  /// In en, this message translates to:
  /// **'5XXXXXXXX'**
  String get enter_phone_hint;

  /// No description provided for @err_enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get err_enter_phone;

  /// No description provided for @err_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 9-digit mobile number'**
  String get err_invalid_phone;

  /// No description provided for @send_code.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get send_code;

  /// No description provided for @login_email.
  ///
  /// In en, this message translates to:
  /// **'Login with Email & Password'**
  String get login_email;

  /// No description provided for @login_guest.
  ///
  /// In en, this message translates to:
  /// **'Login as Guest'**
  String get login_guest;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @sync_success.
  ///
  /// In en, this message translates to:
  /// **'Notifications synced successfully!'**
  String get sync_success;

  /// No description provided for @sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync notifications.'**
  String get sync_failed;

  /// No description provided for @otp_resent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent again!'**
  String get otp_resent;

  /// No description provided for @otp_failed_resend.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend'**
  String get otp_failed_resend;

  /// No description provided for @otp_enter_full.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 4-digit code'**
  String get otp_enter_full;

  /// No description provided for @otp_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get otp_invalid;

  /// No description provided for @otp_title.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get otp_title;

  /// No description provided for @otp_subtitle.
  ///
  /// In en, this message translates to:
  /// **'We have sent the verification code to'**
  String get otp_subtitle;

  /// No description provided for @otp_your_phone.
  ///
  /// In en, this message translates to:
  /// **'your phone'**
  String get otp_your_phone;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resend_code;

  /// No description provided for @resend_in.
  ///
  /// In en, this message translates to:
  /// **'Resend code in '**
  String get resend_in;

  /// No description provided for @currency_sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currency_sar;

  /// No description provided for @loyalty_card.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Card'**
  String get loyalty_card;

  /// No description provided for @boost_points.
  ///
  /// In en, this message translates to:
  /// **'Boost Your Points'**
  String get boost_points;

  /// No description provided for @double_discounts.
  ///
  /// In en, this message translates to:
  /// **'& Multiply Double Your Discounts'**
  String get double_discounts;

  /// No description provided for @points_conversion.
  ///
  /// In en, this message translates to:
  /// **'Every 10 SAR = {points} Points'**
  String points_conversion(String points);

  /// No description provided for @points_value.
  ///
  /// In en, this message translates to:
  /// **'Every 10 Points = 1 SAR'**
  String get points_value;

  /// No description provided for @tier_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get tier_basic;

  /// No description provided for @tier_plus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get tier_plus;

  /// No description provided for @tier_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get tier_premium;

  /// No description provided for @tier_elite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get tier_elite;

  /// No description provided for @condition_plus.
  ///
  /// In en, this message translates to:
  /// **'Reach 2,000 SAR in purchases within a year to unlock.'**
  String get condition_plus;

  /// No description provided for @condition_premium.
  ///
  /// In en, this message translates to:
  /// **'Reach 5,000 SAR in purchases within a year to unlock.'**
  String get condition_premium;

  /// No description provided for @condition_elite.
  ///
  /// In en, this message translates to:
  /// **'Reach 10,000 SAR in purchases within a year to unlock.'**
  String get condition_elite;

  /// No description provided for @cat_for_baby.
  ///
  /// In en, this message translates to:
  /// **'For Baby'**
  String get cat_for_baby;

  /// No description provided for @cat_for_her.
  ///
  /// In en, this message translates to:
  /// **'For Her'**
  String get cat_for_her;

  /// No description provided for @cat_for_him.
  ///
  /// In en, this message translates to:
  /// **'For Him'**
  String get cat_for_him;

  /// No description provided for @cat_medicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get cat_medicine;

  /// No description provided for @my_cart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get my_cart;

  /// No description provided for @cart_empty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cart_empty;

  /// No description provided for @removed_from_cart.
  ///
  /// In en, this message translates to:
  /// **'{product} removed from cart'**
  String removed_from_cart(String product);

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @enter_discount_code.
  ///
  /// In en, this message translates to:
  /// **'Enter Discount Code'**
  String get enter_discount_code;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @coupon_applied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied: {code}'**
  String coupon_applied(String code);

  /// No description provided for @place_order.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get place_order;

  /// No description provided for @continue_step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_step;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @shipping_details.
  ///
  /// In en, this message translates to:
  /// **'Shipping Details'**
  String get shipping_details;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @select_location_map.
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get select_location_map;

  /// No description provided for @select_region.
  ///
  /// In en, this message translates to:
  /// **'Select Region'**
  String get select_region;

  /// No description provided for @shipping_to.
  ///
  /// In en, this message translates to:
  /// **'Shipping To'**
  String get shipping_to;

  /// No description provided for @payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payment_method;

  /// No description provided for @order_notes.
  ///
  /// In en, this message translates to:
  /// **'Order Notes'**
  String get order_notes;

  /// No description provided for @order_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Notes about your order...'**
  String get order_notes_hint;

  /// No description provided for @final_review.
  ///
  /// In en, this message translates to:
  /// **'Final Review'**
  String get final_review;

  /// No description provided for @order_summary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get order_summary;

  /// No description provided for @no_payment_methods.
  ///
  /// In en, this message translates to:
  /// **'No payment methods available.'**
  String get no_payment_methods;

  /// No description provided for @please_select_payment.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method.'**
  String get please_select_payment;

  /// No description provided for @payment_init_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize payment. Please try again.'**
  String get payment_init_failed;

  /// No description provided for @payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed or cancelled.'**
  String get payment_failed;

  /// No description provided for @order_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order. Please try again.'**
  String get order_failed;

  /// No description provided for @err_please_enter.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String err_please_enter(String field);

  /// No description provided for @err_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get err_invalid_email;

  /// No description provided for @coupon_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon code'**
  String get coupon_invalid;

  /// No description provided for @coupon_expired.
  ///
  /// In en, this message translates to:
  /// **'This coupon has expired'**
  String get coupon_expired;

  /// No description provided for @coupon_removed.
  ///
  /// In en, this message translates to:
  /// **'Coupon removed'**
  String get coupon_removed;

  /// No description provided for @tab_ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get tab_ongoing;

  /// No description provided for @tab_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tab_completed;

  /// No description provided for @tab_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tab_cancelled;

  /// No description provided for @no_ongoing_orders.
  ///
  /// In en, this message translates to:
  /// **'No ongoing orders yet.'**
  String get no_ongoing_orders;

  /// No description provided for @no_completed_orders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders yet.'**
  String get no_completed_orders;

  /// No description provided for @no_cancelled_orders.
  ///
  /// In en, this message translates to:
  /// **'No cancelled orders yet.'**
  String get no_cancelled_orders;

  /// No description provided for @order_number.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String order_number(Object id);

  /// No description provided for @price_label.
  ///
  /// In en, this message translates to:
  /// **'Price: {price} {currency}'**
  String price_label(String price, String currency);

  /// No description provided for @track_btn.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track_btn;

  /// No description provided for @details_btn.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details_btn;

  /// No description provided for @view_details_link.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get view_details_link;

  /// No description provided for @order_again_btn.
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get order_again_btn;

  /// No description provided for @rate_label.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate_label;

  /// No description provided for @err_no_products_reorder.
  ///
  /// In en, this message translates to:
  /// **'No products found to re-order.'**
  String get err_no_products_reorder;

  /// No description provided for @msg_products_added_cart.
  ///
  /// In en, this message translates to:
  /// **'{count} products added to cart.'**
  String msg_products_added_cart(int count);

  /// No description provided for @err_products_not_found.
  ///
  /// In en, this message translates to:
  /// **'Failed to find products. They might be out of stock.'**
  String get err_products_not_found;

  /// No description provided for @err_reordering.
  ///
  /// In en, this message translates to:
  /// **'Error re-ordering: {error}'**
  String err_reordering(Object error);

  /// No description provided for @err_loading_orders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String err_loading_orders(Object error);

  /// No description provided for @err_load_order_details.
  ///
  /// In en, this message translates to:
  /// **'Could not load order details'**
  String get err_load_order_details;

  /// No description provided for @go_back.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get go_back;

  /// No description provided for @loading_order_tracking.
  ///
  /// In en, this message translates to:
  /// **'Loading order tracking...'**
  String get loading_order_tracking;

  /// No description provided for @wishlist_title.
  ///
  /// In en, this message translates to:
  /// **'Your Wishlist ({count})'**
  String wishlist_title(int count);

  /// No description provided for @wishlist_empty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any products to your Wishlist yet!'**
  String get wishlist_empty;

  /// No description provided for @shop_by_categories_btn.
  ///
  /// In en, this message translates to:
  /// **'Shop by Categories'**
  String get shop_by_categories_btn;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profile_updated;

  /// No description provided for @profile_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profile_update_failed;

  /// No description provided for @edit_photo.
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get edit_photo;

  /// No description provided for @remove_btn.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove_btn;

  /// No description provided for @personal_details.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personal_details;

  /// No description provided for @billing_address.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get billing_address;

  /// No description provided for @contact_details.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contact_details;

  /// No description provided for @company_label.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company_label;

  /// No description provided for @address1_label.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get address1_label;

  /// No description provided for @address2_label.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get address2_label;

  /// No description provided for @city_label.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city_label;

  /// No description provided for @postcode_label.
  ///
  /// In en, this message translates to:
  /// **'Postcode'**
  String get postcode_label;

  /// No description provided for @country_label.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country_label;

  /// No description provided for @state_label.
  ///
  /// In en, this message translates to:
  /// **'State/Region'**
  String get state_label;

  /// No description provided for @discard_btn.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard_btn;

  /// No description provided for @save_changes_btn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes_btn;

  /// No description provided for @loyalty_rewards_title.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Rewards'**
  String get loyalty_rewards_title;

  /// No description provided for @welcome_rewards.
  ///
  /// In en, this message translates to:
  /// **'Welcome to UCP Rewards'**
  String get welcome_rewards;

  /// No description provided for @points_history.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get points_history;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @no_history_found.
  ///
  /// In en, this message translates to:
  /// **'No history found.'**
  String get no_history_found;

  /// No description provided for @loyalty_card_label.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Card'**
  String get loyalty_card_label;

  /// No description provided for @current_points.
  ///
  /// In en, this message translates to:
  /// **'Current Points'**
  String get current_points;

  /// No description provided for @ucp_loyalty_program.
  ///
  /// In en, this message translates to:
  /// **'UCP Loyalty Program'**
  String get ucp_loyalty_program;

  /// No description provided for @active_account.
  ///
  /// In en, this message translates to:
  /// **'Active Account'**
  String get active_account;

  /// No description provided for @pts_suffix.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get pts_suffix;

  /// No description provided for @choose_language.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get choose_language;

  /// No description provided for @continue_btn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_btn;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome_back;

  /// No description provided for @login_to_account.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get login_to_account;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @please_enter_username.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get please_enter_username;

  /// No description provided for @please_enter_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get please_enter_password;

  /// No description provided for @login_btn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_btn;

  /// No description provided for @no_account_signup.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get no_account_signup;

  /// No description provided for @back_to_phone_login.
  ///
  /// In en, this message translates to:
  /// **'Back to Phone Login'**
  String get back_to_phone_login;

  /// No description provided for @continue_as_guest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continue_as_guest;

  /// No description provided for @order_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get order_confirmed;

  /// No description provided for @thank_you_order.
  ///
  /// In en, this message translates to:
  /// **'Thank You For Your Order!'**
  String get thank_you_order;

  /// No description provided for @order_placed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully.'**
  String get order_placed_successfully;

  /// No description provided for @order_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get order_details;

  /// No description provided for @order_id_label.
  ///
  /// In en, this message translates to:
  /// **'Order ID:'**
  String get order_id_label;

  /// No description provided for @date_label.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get date_label;

  /// No description provided for @payment_method_label.
  ///
  /// In en, this message translates to:
  /// **'Payment Method:'**
  String get payment_method_label;

  /// No description provided for @status_label.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get status_label;

  /// No description provided for @shipping_address_label.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shipping_address_label;

  /// No description provided for @order_summary_label.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get order_summary_label;

  /// No description provided for @total_label.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total_label;

  /// No description provided for @continue_shopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continue_shopping;

  /// No description provided for @order_tracking_title.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get order_tracking_title;

  /// No description provided for @image_not_found.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get image_not_found;

  /// No description provided for @order_id_colon.
  ///
  /// In en, this message translates to:
  /// **'Order ID :'**
  String get order_id_colon;

  /// No description provided for @received_status.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received_status;

  /// No description provided for @on_the_way_status.
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get on_the_way_status;

  /// No description provided for @delivered_status.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered_status;

  /// No description provided for @products_label.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products_label;

  /// No description provided for @order_label.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order_label;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @please_enter_first_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get please_enter_first_name;

  /// No description provided for @please_enter_last_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get please_enter_last_name;

  /// No description provided for @please_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get please_enter_email;

  /// No description provided for @please_enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get please_enter_valid_email;

  /// No description provided for @please_enter_password_signup.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get please_enter_password_signup;

  /// No description provided for @password_min_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_min_length;

  /// No description provided for @register_btn.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_btn;

  /// No description provided for @registration_successful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please log in.'**
  String get registration_successful;

  /// No description provided for @registration_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. The email might already be in use.'**
  String get registration_failed;

  /// No description provided for @error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String error_occurred(String error);

  /// No description provided for @what_can_we_help.
  ///
  /// In en, this message translates to:
  /// **'What can we help you find?'**
  String get what_can_we_help;

  /// No description provided for @delivery_to.
  ///
  /// In en, this message translates to:
  /// **'Delivery to'**
  String get delivery_to;

  /// No description provided for @change_btn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change_btn;

  /// No description provided for @bestseller.
  ///
  /// In en, this message translates to:
  /// **'Bestseller'**
  String get bestseller;

  /// No description provided for @popular_brands.
  ///
  /// In en, this message translates to:
  /// **'Popular Brands'**
  String get popular_brands;

  /// No description provided for @select_delivery_location.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Location'**
  String get select_delivery_location;

  /// No description provided for @move_map_to_select.
  ///
  /// In en, this message translates to:
  /// **'Move the map to select your location'**
  String get move_map_to_select;

  /// No description provided for @confirm_location.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirm_location;

  /// No description provided for @payment_title.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment_title;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_warning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.'**
  String get delete_account_warning;

  /// No description provided for @delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Account Deletion'**
  String get delete_account_confirm;

  /// No description provided for @cancel_btn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_btn;

  /// No description provided for @delete_btn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete_btn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
