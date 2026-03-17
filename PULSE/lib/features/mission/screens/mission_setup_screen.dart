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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 1. Vehicle Info - compact
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(user?.vehicleId ?? 'N/A', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Text(user?.name ?? '', style: AppTextStyles.micro),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Incident Details - compact
            SectionCard(
              title: 'INCIDENT',
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                         isDense: true,
                         items: _incidentTypes.map((type) {
                           return DropdownMenuItem(value: type, child: Text(type, style: AppTextStyles.label));
                         }).toList(),
                         onChanged: (v) => setState(() => _selectedIncident = v!),
                       ),
                     ),
                   ),
                   const SizedBox(height: 10),
                   Row(
                     children: _priorities.map((p) {
                       final isSelected = _selectedPriority == p;
                       return Expanded(
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 3),
                           child: InkWell(
                             onTap: () => setState(() => _selectedPriority = p),
                             child: Container(
                               padding: const EdgeInsets.symmetric(vertical: 8),
                               decoration: BoxDecoration(
                                 color: isSelected ? AppColors.primary : Colors.white,
                                 border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
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
            const SizedBox(height: 12),

            // 3. Destination Selection
            SectionCard(
              title: 'DESTINATION',
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current location - compact
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primary, size: 14),
                        const SizedBox(width: 8),
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
                                  style: AppTextStyles.micro.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search filter
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search hospitals...',
                      hintStyle: AppTextStyles.micro,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 8),
                  _buildHospitalList(positionAsync),
                  const SizedBox(height: 6),
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
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Choose on Map', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(36),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Route Preview Card - smaller
            if (_selectedHospital != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.route, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_selectedHospital!.distanceKm.toStringAsFixed(1)} km', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('ETA: ${_selectedHospital!.eta}', style: AppTextStyles.micro),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 8),
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
