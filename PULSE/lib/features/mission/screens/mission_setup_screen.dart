import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/models/hospital_model.dart';
import 'package:pulse_ev/features/mission/providers/mission_provider.dart';
import 'package:pulse_ev/shared/widgets/app_button.dart';
import 'package:pulse_ev/shared/widgets/section_card.dart';
import 'package:pulse_ev/shared/widgets/loading_indicator.dart';
import 'package:pulse_ev/shared/widgets/error_view.dart';
import 'package:pulse_ev/features/auth/providers/user_provider.dart';

class MissionSetupScreen extends ConsumerStatefulWidget {
  const MissionSetupScreen({super.key});

  @override
  ConsumerState<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends ConsumerState<MissionSetupScreen> {
  String _selectedIncident = 'Medical Emergency';
  String _selectedPriority = 'Critical';
  HospitalModel? _selectedHospital;

  final List<String> _incidentTypes = [
    'Medical Emergency',
    'Accident',
    'Fire Response',
    'Police Support',
  ];

  final List<String> _priorities = ['Critical', 'High', 'Standard'];

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(hospitalsProvider);
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
                      Text('Vehicle: ${user?.vehicleId.split(' ').first ?? 'Ambulance'}', style: AppTextStyles.label),
                      Text('Vehicle ID: ${user?.vehicleId ?? 'A-12'}', style: AppTextStyles.micro),
                      Text('Driver: ${user?.name ?? 'John Doe'}', style: AppTextStyles.micro),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Incident Details
            SectionCard(
              title: '[INCIDENT DETAILS]',
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
              title: '[DESTINATION]',
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
                        Text('[GPS Location]', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Destination', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  hospitalsAsync.when(
                    loading: () => const AppLoadingIndicator(),
                    error: (err, _) => ErrorView(message: err.toString()),
                    data: (hospitals) {
                      if (_selectedHospital == null && hospitals.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           setState(() => _selectedHospital = hospitals.first);
                        });
                      }
                      return Column(
                        children: hospitals.map((h) {
                          final isSelected = _selectedHospital?.name == h.name;
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
                                    Expanded(child: Text(h.name, style: AppTextStyles.label)),
                                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
                        image: const DecorationImage(
                          image: NetworkImage('https://placeholder.com/map'), // Mock map preview
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(child: Icon(Icons.map, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance: ${_selectedHospital!.distance} km', style: AppTextStyles.label),
                        Text('Estimated Time: ${_selectedHospital!.eta}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                        Text('Signals to Override: ${_selectedHospital!.signalsToOverride}', style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Start Mission Button
            AppButton(
              text: '[START MISSION]',
              variant: ButtonVariant.emergency,
              onPressed: () async {
                if (_selectedHospital != null) {
                  final router = GoRouter.of(context);
                  await ref.read(missionProvider.notifier).startMission(
                    _selectedIncident,
                    _selectedPriority,
                    _selectedHospital!,
                  );
                  router.go('/mission/active');
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/dashboard'),
              child: Text('[CANCEL]', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
