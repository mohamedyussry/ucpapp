
# Project Blueprint: E-commerce App

## Overview

This document outlines the architecture, features, and design of a Flutter-based e-commerce mobile application. The app connects to a WooCommerce backend to display and manage products.

## Implemented Features & Design

*   **Home Screen (`home_screen.dart`):**
    *   Serves as the main entry point after the splash screen.
    *   Features a clean UI with a search bar and a bottom navigation menu.
    *   Provides navigation to the "Self Care" category section.

*   **Self-Care Categories Screen (`self_care_screen.dart`):**
    *   Displays three main categories: "HIM", "HER", and "BABY".
    *   Each category is represented by a full-screen, looping background video (`assets/him.mp4`, `assets/HER.mp4`, `assets/baby.mp4`) to create a dynamic and visually engaging experience.
    *   The category titles are overlaid on the videos with a stylish `GoogleFonts.cinzel` font.
    *   Tapping on a category navigates the user to the corresponding products screen.
    *   Separates the displayed category title (e.g., "HIM") from the actual API query category name (e.g., "For Him") to allow for clean UI text while fetching the correct data.

*   **Products Screen (`products_screen.dart`):**
    *   Displays products from a selected category in a 2-column grid view.
    *   Fetches product data dynamically from a WooCommerce backend.
    *   Includes a search bar for filtering products and a shopping cart icon.
    *   Shows a loading indicator while products are being fetched.
    *   Displays a "No products found" message if a category is empty or if there's an error.

*   **WooCommerce Integration (`woocommerce_service.dart`):**
    *   Connects to the WooCommerce API using the `woocommerce_flutter_api` and `dio` packages.
    *   Handles fetching product categories and products by category ID.
    *   Includes a workaround to fetch categories directly via a `Dio` GET request to bypass a deserialization issue in the `woocommerce_flutter_api` package, ensuring raw `List<Map<String, dynamic>>` data is handled correctly.
    *   Manages API credentials securely via a `config.dart` file (which is git-ignored).

*   **Product Card Widget (`product_card.dart`):**
    *   A reusable widget to display a single product with its image, name, and price.

*   **Configuration (`config.dart`):**
    *   Centralizes API keys and URLs. This file is included in `.gitignore` to prevent sensitive credentials from being committed to version control.

## Current Plan

**Goal:** Upload the project to a GitHub repository.

**Steps:**
1.  [x] Create this `blueprint.md` file to document the project.
2.  [ ] Initialize a Git repository.
3.  [ ] Add all project files to the staging area.
4.  [ ] Commit the files with the message "Feat: Initial commit with product display functionality".
5.  [ ] Request the remote GitHub repository URL from the user.
6.  [ ] Add the remote origin.
7.  [ ] Push the project to the `main` branch.
