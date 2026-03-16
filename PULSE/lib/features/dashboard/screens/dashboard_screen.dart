import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/dashboard/providers/dashboard_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/status_badge.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu, color: AppColors.textPrimary),
        title: Text(
          'Home Dashboard',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(dashboardProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Vehicle Status Card
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle: ${data.vehicleName}',
                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(status: data.vehicleStatus),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${data.station}',
                            style: AppTextStyles.micro,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Emergency Action Buttons
              SectionCard(
                child: Column(
                  children: [
                    AppButton(
                      text: 'START MISSION',
                      variant: ButtonVariant.emergency,
                      onPressed: () => context.go('/mission/setup'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'ANALYSIS',
                            variant: ButtonVariant.primary,
                            onPressed: () => context.push('/traffic/intelligence'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'SIMULATOR',
                            variant: ButtonVariant.secondary,
                            onPressed: () => context.push('/simulation'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Traffic Summary Card
              SectionCard(
                title: 'TRAFFIC SUMMARY',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Traffic Density: ${data.trafficDensity}',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nearby Incidents: ${data.nearbyIncidents}',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.push('/traffic/intelligence'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VIEW TRAFFIC INTELLIGENCE',
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Recent Missions
              SectionCard(
                title: 'RECENT MISSIONS',
                child: Column(
                  children: data.recentMissions.map((mission) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${mission.from} → ${mission.to}', style: AppTextStyles.label),
                                Text('Duration: ${mission.durationMinutes} min', style: AppTextStyles.micro),
                              ],
                            ),
                          ),
                          const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.push('/mission/active');
              break;
            case 2:
              context.push('/traffic/intelligence');
              break;
            case 3:
              context.push('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.traffic), label: 'Traffic'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
