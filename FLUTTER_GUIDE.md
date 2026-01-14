# Flutter Project Guide: UCPKSA E-commerce App

## 1. Project Overview

This document serves as a comprehensive guide to the UCPKSA Flutter e-commerce application. The primary goal of this project is to create a seamless mobile shopping experience for customers, integrating directly with a WooCommerce backend. This guide details the application's architecture, core components, and the critical debugging journey that led to a stable and functional authentication system.

---

## 2. Application Architecture

The application is structured following modern Flutter best practices, emphasizing separation of concerns for maintainability and scalability.

*   **State Management:** We use the **Provider** package for state management. This allows for a clean separation between UI and business logic, making the state accessible throughout the widget tree where needed. `AuthProvider` is a prime example of this pattern in action.

*   **Layered Structure:** The codebase is organized into logical layers:
    *   `lib/screens`: Contains all the UI widgets that represent different pages of the app (e.g., `LoginScreen`, `ProfileScreen`).
    *   `lib/providers`: Manages the application's state and acts as a bridge between the UI and the services layer (e.g., `AuthProvider`).
    *   `lib/services`: Handles all external communication, such as making API calls to the WordPress/WooCommerce backend (e.g., `AuthService`, `WooCommerceService`).
    *   `lib/models`: Defines the data structures used throughout the application, with methods to serialize and deserialize data from JSON (e.g., `Customer`).
    *   `lib/config`: A centralized file for storing all static configuration data, such as API endpoints and keys.

*   **Dependency Injection:** The Provider package is implicitly used for dependency injection, allowing services and state to be provided to the widgets that need them without creating tight coupling.

---

## 3. Core Components

### 3.1. Authentication Flow

The authentication process is the cornerstone of the user experience. It involves a sequence of API calls and state updates to securely log the user in.

1.  **UI Interaction:** The user enters their email and password on the `LoginScreen`.
2.  **Provider Call:** The `login` method in `AuthProvider` is triggered.
3.  **Service Request:** `AuthProvider` calls the `login` method in `AuthService`.
4.  **API Call:** `AuthService` sends a POST request to the `/wp-json/jwt-auth/v1/token` endpoint with the user's credentials.
5.  **Token Processing:** Upon a successful response, the service receives a JSON Web Token (JWT).
6.  **User ID Extraction:** The `jwt_decoder` package is used to decode the JWT and extract the `user_id` from its payload.
7.  **Data Storage:** The JWT and `user_id` are securely stored on the device using `shared_preferences`.
8.  **Fetch Customer Data:** Immediately after login, the `getCustomerById` method in `WooCommerceService` is called to fetch the full customer profile.
9.  **State Update:** The fetched `Customer` object is stored in the `AuthProvider`, and the authentication status is updated to `authenticated`.
10. **UI Update:** The UI listens for changes in `AuthProvider` and navigates the user to their profile or the home screen.

### 3.2. Key Dependencies

*   `provider`: For state management.
*   `dio`: A powerful HTTP client for making API requests.
*   `shared_preferences`: For persisting session data (token, user ID) locally on the device.
*   `jwt_decoder`: A crucial utility for decoding JWTs and extracting claims, which was key to solving our main authentication issue.

---

## 4. The Debugging Journey: From Failure to Success

The path to a working authentication system was challenging. We encountered several critical, misleading bugs that required systematic diagnosis.

### Problem 1: Login Fails - The Missing `user_id`

*   **Symptom:** The user would log in with correct credentials, but the app would indicate a failure without a clear error message.
*   **Diagnosis:**
    1.  We added a diagnostic `log` statement inside the `AuthService` to print the raw server response after a login attempt.
    2.  The log revealed that the server was sending a valid JWT (`token`) but was **not** including the `user_id` field in the response body as the app expected.
*   **Solution:**
    1.  We added the `jwt_decoder` package to the project.
    2.  We modified the `AuthService.login` method to decode the received JWT.
    3.  We successfully extracted the `user_id` from the `data.user.id` field within the JWT payload, making the app self-reliant for this crucial piece of data.

### Problem 2: `NoSuchMethodError` - The Deceptive Data Structure

*   **Symptom:** After fixing the `user_id` issue, the login process would still fail, but this time with a `NoSuchMethodError`. The logs showed "Login successful" followed immediately by "Unexpected error fetching customer".
*   **Diagnosis:**
    1.  The error occurred right after successfully getting the `user_id`, pointing to an issue in the `getCustomerById` function within the `WooCommerceService`.
    2.  We added another diagnostic `log` statement, `CUSTOMER DATA FROM SERVER: ...`, inside `getCustomerById` to inspect the raw JSON data for the customer profile.
    3.  We carefully compared the logged JSON with the `Customer.fromJson` factory in `lib/models/customer_model.dart`. The comparison revealed the critical mismatch:
        *   **Server was sending:** `"avatar_url": "https://..."`
        *   **App was trying to read:** `json['avatar_urls']['96']`
*   **Solution:**
    1.  We corrected a single line in the `Customer.fromJson` factory.
    2.  We changed `avatarUrl: json['avatar_urls']['96']` to `avatarUrl: json['avatar_url']`.
    3.  This allowed the app to correctly parse the customer data, and the entire login flow succeeded for the first time.

## 5. Conclusion & Next Steps

This debugging process highlights the importance of systematic logging and verifying data contracts between the client and server. The application is now in a stable state with a robust authentication system.

The next logical step is to evolve the authentication system further by implementing a more modern, passwordless login flow using phone numbers, as was originally envisioned.
