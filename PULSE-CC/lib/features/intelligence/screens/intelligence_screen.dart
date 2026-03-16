import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_app_bar.dart';
import '../../../shared/widgets/pulse_bottom_nav.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/section_label.dart';
import '../intelligence_controller.dart';
import '../widgets/city_stats_grid.dart';
import '../widgets/district_map_view.dart';
import '../widgets/intersection_insights_row.dart';
import '../widgets/weekly_safety_audit_card.dart';

class IntelligenceScreen extends ConsumerStatefulWidget {
  const IntelligenceScreen({super.key});

  @override
  ConsumerState<IntelligenceScreen> createState() => _IntelligenceScreenState();
}

class _IntelligenceScreenState extends ConsumerState<IntelligenceScreen> {
  int _selectedTab = 0; // 0 for Full Route, 1 for Intersection Control

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(intelligenceControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intelligenceControllerProvider);
    final controller = ref.read(intelligenceControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PulseAppBar(
        title: 'TRAFFIC INTELLIGENCE PANEL',
        subtitle: 'CITY TRAFFIC ANALYTICS',
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // LIVE SYSTEM FEED
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.liveDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE SYSTEM FEED',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // CITY STATS
                  CityStatsGrid(stats: state.cityStats),
                  const SizedBox(height: 20),

                  // DISTRICT VIEW
                  SectionLabel(label: 'DISTRICT VIEW - ${state.selectedDistrict.sectorName.toUpperCase()}'),
                  const SizedBox(height: 8),
                  DistrictMapView(district: state.selectedDistrict),
                  const SizedBox(height: 16),

                  // ACTION BUTTONS
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/live-map'),
                      icon: const Icon(Icons.route, color: AppColors.textPrimary, size: 18),
                      label: Text(
                        'VIEW FULL ROUTE',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/live-map/intersection/INT-001'),
                      icon: const Icon(Icons.traffic, color: Colors.white, size: 18),
                      label: Text(
                        'OPEN INTERSECTION CONTROL',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TAB ROW (Visual only)
                  Row(
                    children: [
                      _buildTab(0, 'Full Route'),
                      const SizedBox(width: 8),
                      _buildTab(1, 'Intersection Control'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // INTERSECTION INSIGHTS
                  const SectionLabel(label: 'INTERSECTION INSIGHTS'),
                  const SizedBox(height: 8),
                  IntersectionInsightsRow(intersections: state.intersections),
                  const SizedBox(height: 20),

                  // WEEKLY SAFETY AUDIT
                  WeeklySafetyAuditCard(audit: state.safetyAudit),
                  const SizedBox(height: 20),

                  // INCIDENT INSIGHTS
                  const SectionLabel(label: 'INCIDENT INSIGHTS'),
                  const SizedBox(height: 8),
                  PulseCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInsightRow(
                          Icons.warning_amber,
                          AppColors.danger,
                          'High Risk Area',
                          state.incidentInsights.highRiskArea,
                          valueFontWeight: FontWeight.w600,
                        ),
                        const Divider(height: 24, color: AppColors.border, thickness: 0.5),
                        _buildInsightRow(
                          Icons.directions_car,
                          AppColors.textHint,
                          'Accidents This Week',
                          state.incidentInsights.accidentsThisWeek.toString(),
                          valueColor: AppColors.danger,
                          valueFontWeight: FontWeight.w700,
                        ),
                        // const Divider(height: 24, color: AppColors.border, thickness: 0.5),
                        // _buildInsightRow(
                        //   Icons.traffic,
                        //   AppColors.textHint,
                        //   'Most Common Cause',
                        //   state.incidentInsights.mostCommonCause,
                        //   valueFontWeight: FontWeight.w600,
                        // ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16 + 64 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
      bottomNavigationBar: const PulseBottomNav(currentIndex: 4),
    );
  }

  Widget _buildTab(int index, String label) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: () => setState(() => _selectedTab = index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppColors.primary : AppColors.surface,
            foregroundColor: isActive ? Colors.white : AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isActive ? BorderSide.none : const BorderSide(color: AppColors.border),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    IconData icon,
    Color iconColor,
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.w400,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: valueFontWeight,
          ),
        ),
      ],
    );
  }
}
