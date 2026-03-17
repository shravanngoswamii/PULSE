import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/core/services/location_service.dart';
import 'package:pulse_ev/core/services/geocoding_service.dart';
import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';

// Provider to get the current GPS position
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  return await LocationService.getCurrentPosition();
});

// Provider to reverse geocode a lat/lng pair into a place name
final reverseGeocodeProvider = FutureProvider.family<String?, ({double lat, double lng})>(
  (ref, coords) async {
    return await GeocodingService.reverseGeocode(coords.lat, coords.lng);
  },
);

class MissionSetupScreen extends ConsumerStatefulWidget {
  const MissionSetupScreen({super.key});

  @override
  ConsumerState<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends ConsumerState<MissionSetupScreen> {
  String _selectedIncident = 'Medical Emergency';
  String _selectedPriority = 'Critical';
  HospitalModel? _selectedHospital;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<String> _incidentTypes = [
    'Medical Emergency',
    'Accident',
    'Fire Response',
    'Police Support',
  ];

  final List<String> _priorities = ['Critical', 'High', 'Standard'];

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppColors.darkGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/dashboard'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const Spacer(),
                          Text('MISSION SETUP', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          const Spacer(),
                          const SizedBox(width: 36),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(user?.vehicleId ?? 'N/A', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(user?.name ?? '', style: AppTextStyles.micro.copyWith(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      SectionCard(
                        title: 'INCIDENT',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedIncident,
                                  isExpanded: true,
                                  isDense: true,
                                  items: _incidentTypes.map((type) {
                                    return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)));
                                  }).toList(),
                                  onChanged: (v) => setState(() => _selectedIncident = v!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: _priorities.map((p) {
                                final isSelected = _selectedPriority == p;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedPriority = p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: isSelected ? AppColors.primaryGradient : null,
                                          color: isSelected ? null : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: isSelected ? AppShadows.glow : AppShadows.card,
                                        ),
                                        child: Center(
                                          child: Text(
                                            p,
                                            style: AppTextStyles.caption.copyWith(
                                              color: isSelected ? Colors.white : AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      SectionCard(
                        title: 'DESTINATION',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: positionAsync.when(
                                      loading: () => Text('Acquiring GPS...', style: AppTextStyles.micro),
                                      error: (_, __) => Text('GPS unavailable', style: AppTextStyles.micro),
                                      data: (pos) {
                                        if (pos == null) {
                                          return Text('GPS unavailable', style: AppTextStyles.micro);
                                        }
                                        final placeAsync = ref.watch(
                                          reverseGeocodeProvider((lat: pos.latitude, lng: pos.longitude)),
                                        );
                                        return placeAsync.when(
                                          loading: () => Text('Resolving...', style: AppTextStyles.micro),
                                          error: (_, __) => Text(
                                            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                                            style: AppTextStyles.micro,
                                          ),
                                          data: (placeName) => Text(
                                            placeName ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                                            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search hospitals...',
                                hintStyle: AppTextStyles.micro,
                                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              onChanged: (value) => setState(() => _searchQuery = value),
                            ),
                            const SizedBox(height: 10),
                            _buildHospitalList(positionAsync),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final result = await context.push<Map<String, dynamic>>('/mission/pick-destination');
                                if (result != null && mounted) {
                                  setState(() {
                                    _selectedHospital = HospitalModel(
                                      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                                      name: result['name'] as String,
                                      lat: result['lat'] as double,
                                      lng: result['lng'] as double,
                                      distanceKm: 0.0,
                                      etaMinutes: 0.0,
                                    );
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text('Choose on Map', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_selectedHospital != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_selectedHospital!.distanceKm.toStringAsFixed(1)} km', style: AppTextStyles.sectionTitle.copyWith(fontSize: 18)),
                                  Text('ETA: ${_selectedHospital!.eta}', style: AppTextStyles.micro),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      AppButton(
                        text: 'START MISSION',
                        variant: ButtonVariant.emergency,
                        onPressed: () async {
                          if (_selectedHospital != null) {
                            final position = ref.read(currentPositionProvider).valueOrNull;
                            final originLat = position?.latitude ?? 0.0;
                            final originLng = position?.longitude ?? 0.0;

                            final router = GoRouter.of(context);
                            await ref.read(missionProvider.notifier).startMission(
                              incidentType: _selectedIncident,
                              priority: _selectedPriority,
                              hospital: _selectedHospital!,
                              originLat: originLat,
                              originLng: originLng,
                            );
                            router.go('/mission/active');
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/dashboard'),
                        child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalList(AsyncValue<Position?> positionAsync) {
    return positionAsync.when(
      loading: () => const AppLoadingIndicator(),
      error: (err, _) => ErrorView(message: 'Cannot load hospitals without GPS: $err'),
      data: (position) {
        if (position == null) {
          return const Text('Enable location services to see nearby hospitals.');
        }
        final hospitalsAsync = ref.watch(
          hospitalsProvider((lat: position.latitude, lng: position.longitude)),
        );
        return hospitalsAsync.when(
          loading: () => const AppLoadingIndicator(),
          error: (err, _) => ErrorView(message: err.toString()),
          data: (hospitals) {
            final filtered = _searchQuery.isEmpty
                ? hospitals
                : hospitals.where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
            if (_selectedHospital == null && filtered.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _selectedHospital = filtered.first);
              });
            }
            return Column(
              children: filtered.map((h) {
                final isSelected = _selectedHospital?.id == h.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedHospital = h),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              h.name,
                              style: AppTextStyles.label.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${h.distanceKm.toStringAsFixed(1)} km',
                            style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
