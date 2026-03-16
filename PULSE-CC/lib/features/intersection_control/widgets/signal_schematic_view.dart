import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/intersection.dart';

class SignalSchematicView extends StatelessWidget {
  final String selectedLane;
  final Intersection intersection;
  final Function(String lane) onLaneSelected;

  const SignalSchematicView({
    super.key,
    required this.selectedLane,
    required this.intersection,
    required this.onLaneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road Cross Background
          Container(
            width: 70,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 240,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // Center Junction
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(
                4,
                (_) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFC0C0C0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // NORTH
          Positioned(
            top: 20,
            child: _DirectionalSignal(
              lane: 'NORTH',
              isSelected: selectedLane == 'NORTH',
              onTap: () => onLaneSelected('NORTH'),
            ),
          ),

          // SOUTH
          Positioned(
            bottom: 20,
            child: _DirectionalSignal(
              lane: 'SOUTH',
              isSelected: selectedLane == 'SOUTH',
              onTap: () => onLaneSelected('SOUTH'),
            ),
          ),

          // WEST
          Positioned(
            left: 20,
            child: _DirectionalSignal(
              lane: 'WEST',
              isSelected: selectedLane == 'WEST',
              onTap: () => onLaneSelected('WEST'),
            ),
          ),

          // EAST
          Positioned(
            right: 20,
            child: _DirectionalSignal(
              lane: 'EAST',
              isSelected: selectedLane == 'EAST',
              onTap: () => onLaneSelected('EAST'),
            ),
          ),

          // Selection callout
          if (selectedLane != '')
            Positioned(
              top: selectedLane == 'NORTH' ? 68 : null,
              bottom: selectedLane == 'SOUTH' ? 68 : null,
              left: selectedLane == 'WEST' ? 68 : null,
              right: selectedLane == 'EAST' ? 68 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.signalGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.signalGreen.withOpacity(0.2)),
                ),
                child: Text(
                  'SELECTED SIGNAL',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.signalGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectionalSignal extends StatelessWidget {
  final String lane;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectionalSignal({
    required this.lane,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.signalGreen, width: 2) : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.traffic,
          size: 24,
          color: isSelected ? AppColors.signalGreen : AppColors.textHint,
        ),
      ),
    );
  }
}

extension on Widget {
  Widget animateOnDirection(String direction) {
    // Basic positioning animation could be added here if needed
    return this;
  }
}
