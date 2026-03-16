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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'MISSION SETUP',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // 1. Vehicle Info Card
            SectionCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle: ${user?.vehicleId ?? 'N/A'}', style: AppTextStyles.label),
                      Text('Driver: ${user?.name ?? 'N/A'}', style: AppTextStyles.micro),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Incident Details
            SectionCard(
              title: 'INCIDENT DETAILS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Incident Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       border: Border.all(color: AppColors.border),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: DropdownButtonHideUnderline(
                       child: DropdownButton<String>(
                         value: _selectedIncident,
                         isExpanded: true,
                         items: _incidentTypes.map((type) {
                           return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.label));
                         }).toList(),
                         onChanged: (v) => setState(() => _selectedIncident = v!),
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
                   const Text('Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Row(
                     children: _priorities.map((p) {
                       final isSelected = _selectedPriority == p;
                       return Expanded(
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 4),
                           child: InkWell(
                             onTap: () => setState(() => _selectedPriority = p),
                             child: Container(
                               padding: const EdgeInsets.symmetric(vertical: 12),
                               decoration: BoxDecoration(
                                 color: isSelected ? AppColors.secondary : Colors.white,
                                 border: Border.all(color: isSelected ? AppColors.secondary : AppColors.border),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Center(
                                 child: Text(
                                   p,
                                   style: AppTextStyles.micro.copyWith(
                                     color: isSelected ? Colors.white : AppColors.textPrimary,
                                     fontWeight: FontWeight.bold,
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
            const SizedBox(height: 16),

            // 3. Destination Selection
            SectionCard(
              title: 'DESTINATION',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: positionAsync.when(
                            loading: () => Text('Acquiring GPS...', style: AppTextStyles.label),
                            error: (_, __) => Text('GPS unavailable', style: AppTextStyles.label),
                            data: (pos) {
                              if (pos == null) {
                                return Text('GPS unavailable', style: AppTextStyles.label);
                              }
                              final placeAsync = ref.watch(
                                reverseGeocodeProvider((lat: pos.latitude, lng: pos.longitude)),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  placeAsync.when(
                                    loading: () => Text('Resolving location...', style: AppTextStyles.label),
                                    error: (_, __) => Text(
                                      '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                                      style: AppTextStyles.label,
                                    ),
                                    data: (placeName) => Text(
                                      placeName ?? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                                    style: AppTextStyles.micro.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Destination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Search filter
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search hospitals...',
                      hintStyle: AppTextStyles.micro,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 8),
                  _buildHospitalList(positionAsync),
                  const SizedBox(height: 8),
                  // Choose on Map button
                  OutlinedButton.icon(
                    onPressed: () async {
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
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Choose on Map'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: AppColors.secondary),
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Route Preview Card
            if (_selectedHospital != null)
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.map, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance: ${_selectedHospital!.distanceKm.toStringAsFixed(1)} km', style: AppTextStyles.label),
                        Text('Estimated Time: ${_selectedHospital!.eta}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Start Mission Button
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/dashboard'),
              child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
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
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedHospital = h),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: isSelected ? AppColors.secondary : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppColors.secondary.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name, style: AppTextStyles.label),
                                Text(
                                  '${h.distanceKm.toStringAsFixed(1)} km - ${h.eta}',
                                  style: AppTextStyles.micro,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
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
