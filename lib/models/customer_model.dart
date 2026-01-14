
class Customer {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String avatarUrl;

  Customer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.avatarUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? '', // Corrected from avatar_urls['96']
    );
  }
}
