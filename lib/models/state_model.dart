class CountryState {
  final String code;
  final String name;

  CountryState({required this.code, required this.name});

  factory CountryState.fromJson(Map<String, dynamic> json) {
    return CountryState(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}
