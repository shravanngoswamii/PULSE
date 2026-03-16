class UserModel {
  final String id;
  final String name;
  final String vehicleId;
  final String role;
  final String email;
  final String token;
  final String? phone;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.vehicleId,
    required this.role,
    required this.email,
    required this.token,
    this.phone,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? json['vehicleId'] as String? ?? '',
      role: json['role'] as String? ?? 'driver',
      email: json['email'] as String? ?? '',
      token: json['token'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicle_id': vehicleId,
      'role': role,
      'email': email,
      'token': token,
      'phone': phone,
      'is_active': isActive,
    };
  }
}
