import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMission = ref.watch(missionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'ACTIVE MISSION',
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
      body: Stack(
        children: [
          // 1. Map
          const PulseMap(
            markers: ['Ambulance', 'Hospital', 'Intersection'],
          ),

          // Top Header Layer (HUD)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(20),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.1),
                         blurRadius: 4,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.my_location, size: 14, color: AppColors.primary),
                       const SizedBox(width: 4),
                       Text('LIVE', style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
                 IconButton(
                   icon: const Icon(Icons.layers, color: AppColors.textPrimary),
                   onPressed: () {},
                   style: IconButton.styleFrom(backgroundColor: Colors.white),
                 ),
              ],
            ),
          ),

          // Bottom HUD Layer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2. Mission Stats Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('[ MISSION PROGRESS ]', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () => context.push('/traffic/intelligence'),
                        icon: const Icon(Icons.analytics_outlined, size: 14, color: AppColors.primary),
                        label: Text('TRAFFIC INTEL', style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('DISTANCE', '${currentMission?.distance.toStringAsFixed(1) ?? "0.0"} km'),
                      _buildStatItem('SIGNALS', '${currentMission?.signalsCleared ?? 0} Cleared'),
                      _buildStatItem('ETA', currentMission?.eta ?? '-- min'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Next Signal Alert
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('[NEXT SIGNAL ALERT]', style: AppTextStyles.micro),
                              const SizedBox(height: 4),
                              Text(
                                'MG Road Junction',
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Green Corridor Active',
                                style: AppTextStyles.micro.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.traffic, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. End Mission Button
                  AppButton(
                    text: '[END MISSION]',
                    variant: ButtonVariant.emergency,
                    onPressed: () async {
                      await ref.read(missionProvider.notifier).endMission();
                      if (context.mounted) {
                        context.go('/mission/summary');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.micro),
        Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}
