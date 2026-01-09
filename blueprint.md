
# Application Blueprint

## Overview

This document outlines the design, features, and implementation plan for the UCP (Unified Care Platform) mobile application. The application is a Flutter-based e-commerce platform designed to interact with a WooCommerce backend, allowing users to browse products, manage a shopping cart, and place orders.

## Application Architecture & Features

This section details the project's structure, including UI screens, state management, data models, and services.

### 1. Core Concepts

- **Theme and Branding:**
  - **Primary Color:** Orange is used as the main accent color for buttons, active states, and highlights.
  - **Typography:** The `google_fonts` package (specifically 'Poppins') is used for a clean and modern text style.
  - **UI Design:** The app follows a minimalist design with a white background, clear visual hierarchy, and intuitive navigation.

- **State Management:**
  - The `provider` package is used as the primary state management solution. It allows for a clean separation between the UI and business logic, managing the state of the cart, currency, and checkout process.

- **Backend Integration:**
  - All communication with the e-commerce backend is handled through a centralized `WooCommerceService`. This service abstracts the complexities of making API calls using the `dio` package.

### 2. Screens (UI Flow)

- **`main.dart` (App Entry Point):**
  - Initializes the app and sets up the core `MaterialApp`.
  - Defines the global theme using `ThemeData`, including color schemes and font styles (`Poppins`).
  - Configures the initial route of the application to the `SplashScreen`.
  - Sets up the primary `MultiProvider` for all app-wide providers.

- **`splash_screen.dart`:**
  - The first screen the user sees.
  - Displays the application logo for a brief period (3 seconds) before navigating to the `LanguageSelectionScreen`.

- **`language_selection_screen.dart`:**
  - Presents the user with a choice between "English" and "Arabic".
  - This screen is a placeholder for future localization features and currently navigates to the `CartScreen` as a temporary measure for development.

- **`home_screen.dart`:**
  - Intended to be the main product browsing screen.
  - Currently, it's a basic placeholder and will be the focus of the next development phase.

- **`cart_screen.dart`:**
  - Displays all items that the user has added to their shopping cart.
  - Shows the product image, name, quantity, and price for each item.
  - Allows users to adjust the quantity of each item.
  - Displays the total amount for the cart.
  - Contains a "Proceed to Checkout" button which navigates to the `CheckoutScreen`.

- **`checkout_screen.dart`:**
  - A comprehensive screen for collecting all necessary information to place an order.
  - Contains a multi-step form for:
    - **Billing Details:** Name, address, contact information.
    - **Shipping Details:** An optional, separate form if shipping to a different address.
    - **Order Summary:** Displays subtotal, shipping costs, and the total amount.
  - Fetches and displays available shipping methods based on the user's address.
  - Allows the user to select a shipping method using modern `ChoiceChip` widgets.
  - Handles the final order placement by creating an `OrderPayload` and sending it to the backend.

- **`payment_success_screen.dart`:**
  - A simple confirmation screen shown to the user after their order has been successfully placed.
  - Displays a success message and an icon.

### 3. State Management (Providers)

- **`providers/cart_provider.dart`:**
  - Manages the state of the shopping cart.
  - Handles adding products (`addItem`), removing them, clearing the cart (`clear`), and calculating the total amount.
  - Uses a `Map` to store `CartItemModel` objects, indexed by product ID.

- **`providers/currency_provider.dart`:**
  - Manages the display of the currency throughout the app.
  - Provides the currency symbol and an optional image URL for the currency, making it easy to change globally.

- **`providers/checkout_provider.dart`:**
  - Manages the state of the checkout process.
  - Fetches and stores available shipping methods from WooCommerce.
  - Tracks the currently selected shipping method.
  - Calculates the total order cost, including subtotal, shipping, and taxes.

### 4. Data Models

- **`models/product_model.dart`:**
  - Represents a single product from WooCommerce.
  - Contains fields like `id`, `name`, `price`, and a list of `ProductImage` objects.

- **`models/cart_item_model.dart`:**
  - Represents an item within the shopping cart.
  - Contains a `ProductModel` and the `quantity` of that product in the cart.

- **`models/order_payload_model.dart`:**
  - A comprehensive set of models that define the structure of the JSON payload required to create a new order via the WooCommerce API.
  - Includes `OrderPayload`, `BillingInfo`, `ShippingInfo`, and `ShippingLine`.

- **`models/line_item_model.dart`:**
  - A specific model used within the `OrderPayload`.
  - Represents a single product line item in the order, containing the `productId` and `quantity`.

### 5. Services

- **`services/woocommerce_service.dart`:**
  - The single point of contact for all WooCommerce API interactions.
  - Configures the `dio` HTTP client with the base URL and authentication credentials (consumer key/secret).
  - Contains methods for:
    - `getProducts()`: Fetches a list of all products.
    - `getShippingMethodsForLocation()`: Retrieves shipping options based on location.
    - `createOrder()`: Sends the final order payload to the WooCommerce backend.

### 6. Reusable Widgets

- **`widgets/cart_icon.dart`:**
  - A reusable icon for the app bar that displays the current number of items in the cart.
  - Tapping it navigates the user to the `CartScreen`.

## Implementation Plan

*This section will outline the steps for the next feature to be implemented.*
