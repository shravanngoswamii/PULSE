class UserModel {
  final String id;
  final String name;
  final String vehicleId;
  final String role;
  final String email;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.vehicleId,
    required this.role,
    required this.email,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      vehicleId: json['vehicleId'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicleId': vehicleId,
      'role': role,
      'email': email,
      'token': token,
    };
  }
}
