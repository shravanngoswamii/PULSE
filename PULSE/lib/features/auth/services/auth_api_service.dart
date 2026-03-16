import 'dart:async';
import 'package:pulse_ev/core/errors/api_exception.dart';
import 'package:pulse_ev/features/auth/models/user_model.dart';

class AuthApiService {
  // Mock login behavior
  Future<UserModel> login(String emailOrVehicleId, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if ((emailOrVehicleId == 'A12' || emailOrVehicleId == 'driver@pulse.com') && 
        password == 'password123') {
      return UserModel(
        id: "A12",
        name: "John Doe",
        vehicleId: "Ambulance A-12",
        role: "driver",
        email: "driver@pulse.com",
        token: "mock_token_123",
      );
    } else {
      throw ApiException(message: 'Invalid credentials. Use A12 / password123');
    }
  }

  // Mock signup behavior
  Future<UserModel> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return UserModel(
      id: "NEW_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      vehicleId: "Ambulance T-01", // Placeholder for new signup
      role: "driver",
      email: email,
      token: "mock_token_${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  // Mock logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
