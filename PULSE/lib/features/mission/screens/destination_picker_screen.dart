import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pulse_ev/config/app_theme.dart';
import 'package:pulse_ev/features/mission/screens/mission_setup_screen.dart';
import 'package:pulse_ev/shared/widgets/pulse_map.dart';

class DestinationPickerScreen extends ConsumerStatefulWidget {
  const DestinationPickerScreen({super.key});

  @override
  ConsumerState<DestinationPickerScreen> createState() =>
      _DestinationPickerScreenState();
}

class _DestinationPickerScreenState
    extends ConsumerState<DestinationPickerScreen> {
  LatLng? _pickedPoint;
  String _resolvedName = '';
  bool _isResolving = false;

  // Default map center – Indore; will snap to user location once available
  static const LatLng _defaultCenter = LatLng(22.7196, 75.8577);

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _pickedPoint = point;
      _resolvedName = '';
      _isResolving = true;
    });

    // Reverse-geocode through the provider
    final name = await ref.read(
      reverseGeocodeProvider((lat: point.latitude, lng: point.longitude)).future,
    );

    if (mounted) {
      setState(() {
        _resolvedName = name ?? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _isResolving = false;
      });
    }
  }

  void _confirmSelection() {
    if (_pickedPoint == null) return;
    context.pop<Map<String, dynamic>>({
      'name': _resolvedName.isNotEmpty
          ? _resolvedName
          : '${_pickedPoint!.latitude.toStringAsFixed(4)}, ${_pickedPoint!.longitude.toStringAsFixed(4)}',
      'lat': _pickedPoint!.latitude,
      'lng': _pickedPoint!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final userLatLng = positionAsync.valueOrNull != null
        ? LatLng(positionAsync.valueOrNull!.latitude, positionAsync.valueOrNull!.longitude)
        : null;

    final mapCenter = userLatLng ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          PulseMap(
            center: mapCenter,
            currentPosition: userLatLng,
            onTap: _onMapTap,
            extraMarkers: _pickedPoint != null
                ? [
                    Marker(
                      point: _pickedPoint!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.glow,
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ]
                : [],
          ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tap on the map to set destination',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet with confirm button ─────────────────────────────
          if (_pickedPoint != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isResolving
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resolving address…',
                                      style: AppTextStyles.label,
                                    ),
                                  ],
                                )
                              : Text(
                                  _resolvedName.isNotEmpty
                                      ? _resolvedName
                                      : '${_pickedPoint!.latitude.toStringAsFixed(5)}, '
                                          '${_pickedPoint!.longitude.toStringAsFixed(5)}',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Confirm button
                    GestureDetector(
                      onTap: _isResolving ? null : _confirmSelection,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _isResolving ? null : AppColors.primaryGradient,
                          color: _isResolving ? AppColors.border : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isResolving ? [] : AppShadows.glow,
                        ),
                        child: Center(
                          child: Text(
                            'CONFIRM DESTINATION',
                            style: AppTextStyles.label.copyWith(
                              color: _isResolving ? AppColors.textSecondary : Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Hint when nothing is picked ──────────────────────────────────
          if (_pickedPoint == null)
            Positioned(
              bottom: 32,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to drop a destination pin.',
                        style: AppTextStyles.label,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
