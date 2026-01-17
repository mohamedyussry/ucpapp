
class Customer {
  int id;
  String email;
  String firstName;
  String lastName;
  String username;
  String avatarUrl;
  String? address;
  String? birthday;
  String? gender;
  String? phone;

  Customer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.avatarUrl,
    this.address,
    this.birthday,
    this.gender,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      address: json['billing']?['address_1'],
      phone: json['billing']?['phone'],
      // birthday and gender are not standard WooCommerce fields,
      // they might need to be handled via metadata if you add them.
    );
  }
}
