# Project Blueprint: E-commerce App

## Overview

This document outlines the architecture, features, and design of a Flutter-based e-commerce mobile application. The app connects to a WooCommerce backend to display and manage products.

## Implemented Features & Design

*   **Home Screen (`home_screen.dart`):**
    *   Serves as the main entry point after the splash screen.
    *   Features a clean UI with a search bar and a bottom navigation menu.
    *   Provides navigation to the "Self Care" category section and the "Medicines" product screen.
    *   Tapping the "Medicines" banner now navigates to the `ProductsScreen`, filtering for the "Medicine" category.

*   **Self-Care Categories Screen (`self_care_screen.dart`):**
    *   Displays three main categories: "HIM", "HER", and "BABY".
    *   Each category is represented by a full-screen, looping background video to create a dynamic and visually engaging experience.
    *   The category titles are overlaid on the videos with a stylish `GoogleFonts.cinzel` font.
    *   Tapping on a category navigates the user to the corresponding products screen.
    *   Separates the displayed category title (e.g., "HIM") from the actual API query category name (e.g., "For Him") to allow for clean UI text while fetching the correct data.

*   **Products Screen (`products_screen.dart`):**
    *   Displays products from a selected category in a 2-column grid view.
    *   Fetches product data dynamically from a WooCommerce backend.
    *   Includes a search bar for filtering products and a shopping cart icon.
    *   Shows a loading indicator while products are being fetched.
    *   Displays a "No products found" message if a category is empty or if there's an error.

*   **My Orders Screen (`my_orders_screen.dart`):**
    *   Replaces the previous "Cart" screen in the bottom navigation.
    *   Features a tabbed interface for "Ongoing", "Completed", and "Cancelled" orders.
    *   **New:** The UI has been meticulously updated to exactly match the user-provided design, including button styles, card layouts, spacing, and color details.
    *   Displays detailed order cards with product images, status, and relevant action buttons (e.g., "Track", "Details", "Order again").
    *   Currently populated with static placeholder data using new placeholder images.

*   **WooCommerce Integration (`woocommerce_service.dart`):**
    *   Connects to the WooCommerce API using the `woocommerce_flutter_api` and `dio` packages.
    *   Handles fetching product categories and products by category ID.
    *   Includes a workaround to fetch categories directly via a `Dio` GET request to bypass a deserialization issue in the `woocommerce_flutter_api` package, ensuring raw `List<Map<String, dynamic>>` data is handled correctly.
    *   Manages API credentials securely via a `config.dart` file (which is git-ignored).

*   **Product Card Widget (`product_card.dart`):**
    *   A reusable widget to display a single product with its image, name, and price.

*   **Checkout Screen (`checkout_screen.dart`):**
    *   Allows users to review their order and proceed to payment.
    *   Features a home icon that navigates users back to the main screen.

*   **Payment Success Screen (`payment_success_screen.dart`):**
    *   A confirmation page displayed after a successful payment.
    *   Includes a home icon for easy navigation back to the main screen.

*   **Custom Bottom Navigation Bar (`custom_bottom_nav_bar.dart`):**
    *   The "Cart" item has been replaced with an "Orders" item.
    *   The icon is now `FontAwesomeIcons.box`.
    *   Tapping "Orders" navigates to the new `MyOrdersScreen`.

*   **Configuration (`config.dart`):**
    *   Centralizes API keys and URLs. This file is included in `.gitignore` to prevent sensitive credentials from being committed to version control.

## Current Plan

**Goal:** Refine the "My Orders" screen design to perfection.

**Steps:**
1.  [x] Create `my_orders_screen.dart` with a tabbed layout.
2.  [x] Update `custom_bottom_nav_bar.dart` to navigate to the new screen.
3.  [x] Meticulously refine the UI of `my_orders_screen.dart` to exactly match the provided design, including button styles, layouts, and static images.
4.  [x] Update this `blueprint.md` file to reflect the latest design refinements.
