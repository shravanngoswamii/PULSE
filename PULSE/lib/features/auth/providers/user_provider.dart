import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/auth/models/user_model.dart';

final currentUserProvider = StateProvider<UserModel?>((ref) => null);
