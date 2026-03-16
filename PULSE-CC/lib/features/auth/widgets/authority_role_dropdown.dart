import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';

class AuthorityRoleDropdown extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String?> onChanged;

  const AuthorityRoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authority Role',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
              onChanged: onChanged,
              items: const [
                DropdownMenuItem(
                  value: AppStrings.roleTrafficOfficer,
                  child: Text(AppStrings.roleTrafficOfficer),
                ),
                DropdownMenuItem(
                  value: AppStrings.roleChiefOfficer,
                  child: Text(AppStrings.roleChiefOfficer),
                ),
                DropdownMenuItem(
                  value: AppStrings.roleSystemAdmin,
                  child: Text(AppStrings.roleSystemAdmin),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
