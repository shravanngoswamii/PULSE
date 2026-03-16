import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../features/auth/auth_controller.dart';
import '../../../data/sources/local/secure_storage.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(secureStorageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PulseAppBar(
        title: 'SETTINGS',
        subtitle: 'Operator Profile',
        showSettings: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFILE',
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            PulseCard(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, String?>>(
                future: _loadProfile(storage),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final officerId = data?['officer_id'] ?? '---';
                  final role = data?['user_role'] ?? '---';
                  final name = data?['user_name'] ?? '---';

                  return Column(
                    children: [
                      _ProfileRow(label: 'NAME', value: name),
                      const Divider(height: 24, color: AppColors.border),
                      _ProfileRow(label: 'EMAIL / ID', value: officerId),
                      const Divider(height: 24, color: AppColors.border),
                      _ProfileRow(label: 'ROLE', value: role),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ACCOUNT',
              style: AppTypography.micro.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  'LOGOUT',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String?>> _loadProfile(SecureStorage storage) async {
    final officerId = await storage.getOfficerId();
    final role = await storage.read('user_role');
    final name = await storage.read('user_name');
    return {
      'officer_id': officerId,
      'user_role': role,
      'user_name': name,
    };
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
