# Project Blueprint

## Overview

This document outlines the architecture, features, and implementation details of the Flutter e-commerce application. It serves as a single source of truth for the project's design and development.

## Style and Design

The application follows a modern, clean, and user-friendly design aesthetic. Key design elements include:

*   **Typography:** Google Fonts (Poppins) are used for a consistent and professional look.
*   **Color Scheme:** A simple and effective color scheme with a primary accent color for branding.
*   **Layout:** Responsive layouts that adapt to different screen sizes.
*   **Iconography:** Material Design icons for intuitive navigation and actions.

## Implemented Features

*   **Product Browsing:** Users can browse products by category.
*   **Product Details:** A dedicated screen to view detailed information about each product.
*   **Shopping Cart:** A fully functional shopping cart that allows users to add, remove, and update product quantities.
*   **Favorites:** Users can mark products as favorites for easy access.
*   **Checkout Process:** A streamlined checkout process with a dedicated screen.
*   **Order History:** A screen for users to view their past orders.

## Current Plan: Refactoring and Bug Squashing

**Objective:** The primary goal of this development cycle is to refactor the application to remove the dependency on the `woocommerce_flutter_api` package and address various bugs and warnings.

**Completed Steps:**

1.  **Dependency Removal:** The `woocommerce_flutter_api` package has been successfully removed from the `pubspec.yaml` file.
2.  **Custom WooCommerce Service:** A new `WooCommerceService` has been implemented using the `dio` package to handle direct communication with the WooCommerce API.
3.  **Data Model Creation:** Custom data models (`WooProduct`, `WooProductImage`, `WooProductCategory`) have been created to represent the data received from the API.
4.  **Provider Updates:** The `CartProvider` and `FavoritesProvider` have been updated to use the new data models.
5.  **Screen Refactoring:** All screens that previously relied on the `woocommerce_flutter_api` package have been refactored to use the new `WooCommerceService` and data models.

**Remaining Issues:**

*   **Asset Warnings:** The `pubspec.yaml` file contains references to asset directories that do not exist (`assets/products/` and `assets/brands/`).
*   **Deprecated Code:** Several `deprecated_member_use` warnings are present throughout the codebase.
*   **`avoid_print` Warnings:** The use of `print` statements for debugging should be replaced with a more robust logging solution.

**Next Steps:**

1.  Create the missing asset directories to resolve the warnings in `pubspec.yaml`.
2.  Address the `deprecated_member_use` warnings by updating the code to use the recommended replacements.
3.  Replace `print` statements with a proper logging framework.
4.  Remove the unnecessary import of `category_model.dart` from `products_screen.dart`.
