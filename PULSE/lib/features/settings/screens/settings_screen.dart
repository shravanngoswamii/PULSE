import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/auth/providers/auth_provider.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';
import 'package:pulse_ev/features/settings/providers/settings_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SETTINGS',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // 1. Driver Profile Card
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver: ${ref.watch(currentUserProvider)?.name ?? 'N/A'}',
                          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Vehicle: ${ref.watch(currentUserProvider)?.vehicleId ?? 'N/A'}',
                          style: AppTextStyles.micro,
                        ),
                        Text(
                          'Email: ${ref.watch(currentUserProvider)?.email ?? 'N/A'}',
                          style: AppTextStyles.micro,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EDIT PROFILE',
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Notifications Section
            _buildSectionHeader(Icons.notifications_none_outlined, 'NOTIFICATIONS'),
            SectionCard(
              child: Column(
                children: [
                  _buildToggleRow('Mission Alerts', settings.missionAlerts, notifier.toggleMissionAlerts),
                  _buildToggleRow('Traffic Alerts', settings.trafficAlerts, notifier.toggleTrafficAlerts),
                  _buildToggleRow('Signal Priority Alerts', settings.signalPriorityAlerts, notifier.toggleSignalAlerts),
                  _buildToggleRow('Incident Notifications', settings.incidentNotifications, notifier.toggleIncidentNotifications, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Navigation Settings
            _buildSectionHeader(Icons.location_on_outlined, 'NAVIGATION SETTINGS'),
            SectionCard(
              child: Column(
                children: [
                  _buildToggleRow('Voice Guidance', settings.voiceGuidance, notifier.toggleVoiceGuidance),
                  _buildToggleRow('Route Recalculation', settings.routeRecalculation, notifier.toggleRouteRecalculation),
                  _buildToggleRow('Avoid Heavy Traffic', settings.avoidHeavyTraffic, notifier.toggleAvoidTraffic),
                  _buildDropdownRow(
                    'Map Orientation',
                    settings.mapOrientation,
                    ['Auto', 'North Up', 'Heading Up'],
                    (v) => notifier.setMapOrientation(v!),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. System Settings
            _buildSectionHeader(Icons.settings_input_component_outlined, 'SYSTEM SETTINGS'),
            SectionCard(
              child: Column(
                children: [
                  _buildDropdownRow(
                    'Data Sync Mode',
                    settings.dataSyncMode,
                    ['Auto', 'Manual', 'Offline'],
                    (v) => notifier.setDataSyncMode(v!),
                  ),
                  _buildToggleRow('Map Data Refresh', settings.mapDataRefresh, notifier.toggleMapRefresh),
                  _buildToggleRow('Simulation Mode', settings.simulationMode, notifier.toggleSimulationMode, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Emergency Preferences
            _buildSectionHeader(Icons.warning_amber_rounded, 'EMERGENCY PREFERENCES'),
            SectionCard(
              child: Column(
                children: [
                  _buildToggleRow('Auto Signal Override', settings.autoSignalOverride, notifier.toggleAutoSignalOverride),
                  _buildToggleRow('Emergency Siren Sync', settings.emergencySirenSync, notifier.toggleEmergencySirenSync),
                  _buildToggleRow('Traffic Authority Link', settings.trafficAuthorityLink, notifier.toggleTrafficAuthorityLink, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 6. Logout Button
            AppButton(
              text: '[ LOG OUT ]',
              variant: ButtonVariant.secondary,
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
            const SizedBox(height: 16),

            Text(
              'Version 1.0.0',
              style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.micro.copyWith(
              letterSpacing: 1,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, VoidCallback onToggle, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 14)),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 14)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
            items: items.map((i) {
              return DropdownMenuItem(
                value: i,
                child: Text(
                  i,
                  style: AppTextStyles.micro.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
