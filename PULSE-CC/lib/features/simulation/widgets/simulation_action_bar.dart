import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../simulation_controller.dart';

class SimulationActionBar extends StatelessWidget {
  final SimulationStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const SimulationActionBar({
    super.key,
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = status == SimulationStatus.idle;
    final isRunning = status == SimulationStatus.running;
    final isPaused = status == SimulationStatus.paused;

    return Row(
      children: [
        // START Button
        Expanded(
          flex: 2,
          child: _buildActionButton(
            label: 'START',
            icon: Icons.play_arrow,
            onTap: (isIdle || isPaused) ? onStart : null,
            color: (isIdle || isPaused) ? AppColors.primary : AppColors.primaryLight,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        
        // PAUSE Button
        Expanded(
          flex: 2,
          child: _buildActionButton(
            label: 'PAUSE',
            icon: Icons.pause,
            onTap: isRunning ? onPause : null,
            color: isRunning ? AppColors.surface : AppColors.background,
            textColor: AppColors.textPrimary,
            showBorder: isRunning,
          ),
        ),
        const SizedBox(width: 10),
        
        // RESET Button
        Expanded(
          flex: 2,
          child: _buildActionButton(
            label: 'RESET',
            icon: Icons.refresh,
            onTap: onReset,
            color: AppColors.surface,
            textColor: AppColors.danger,
            showBorder: true,
            borderColor: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    required Color textColor,
    bool showBorder = false,
    Color? borderColor,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: (showBorder || borderColor != null)
                ? BorderSide(color: borderColor ?? AppColors.border)
                : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: textColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
