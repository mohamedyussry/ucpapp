
# Project Blueprint

## Overview

This document outlines the structure, features, and design of the Flutter application.

## Implemented Features

*   **Login Screen:** A basic login screen with email and password fields.
*   **Home Screen:** Displays categories for "Self Care" and "Medicines".
*   **Product List Screen:** Shows a list of products within a selected category.
*   **Self-Care Screen:** A dedicated screen for self-care-related content.
*   **Language Selection Screen:** Allows users to select their preferred language.
*   **Basic Navigation:** Navigation between screens is implemented.
*   **Styling:** The app uses the Google Fonts library for custom fonts and has a defined color scheme.

## Current Plan

The current task is to fix broken image links that were causing `SocketException` and `Unable to load asset` errors. The original plan was to find and fix the specific broken URLs, but due to recurring issues, the strategy has been updated to replace all network and missing asset images with a local asset image to ensure application stability.

### Steps:

1.  **DONE** Identify files with `NetworkImage` and `AssetImage` widgets.
2.  **DONE** Replace the problematic URLs with placeholder image URLs from `https://via.placeholder.com`.
3.  **DONE** Identify a suitable local asset to use as a placeholder.
4.  **DONE** Replace all `NetworkImage` widgets with `AssetImage` widgets pointing to the local asset (`assets/logo.png`).
5.  **DONE** Replace all missing asset images with the local asset (`assets/logo.png`).
6.  **DONE** Update this `blueprint.md` file to document the project.

