import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';
import '../../../shared/widgets/pulse_card.dart';

class IntersectionQuickControl extends StatelessWidget {
  final Intersection intersection;
  final Function(SignalPhase) onForce;
  final VoidCallback onRestore;

  const IntersectionQuickControl({
    super.key,
    required this.intersection,
    required this.onForce,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INTERSECTION CONTROL',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(Icons.hub_outlined, color: AppColors.textHint, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            intersection.name,
            style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  label: 'FORCE GREEN',
                  color: AppColors.signalGreen,
                  icon: Icons.traffic_outlined,
                  onTap: () => onForce(SignalPhase.green),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ControlButton(
                  label: 'FORCE RED',
                  color: AppColors.danger,
                  icon: Icons.traffic_outlined,
                  onTap: () => onForce(SignalPhase.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
            label: Text(
              'RESTORE AUTO CONTROL',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
