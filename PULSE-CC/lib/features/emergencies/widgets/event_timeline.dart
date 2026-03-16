import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/active_mission.dart';

class EventTimeline extends StatelessWidget {
  final List<MissionEvent> events;

  const EventTimeline({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time column
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  DateFormat('HH:mm').format(event.timestamp),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
              
              // Timeline line and dot
              Container(
                width: 16,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: CustomPaint(
                          painter: TimelineLinePainter(color: _getEventColor(event.type)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Message column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.message,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (event.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.subtitle!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.info:
        return AppColors.primary;
      case EventType.warning:
        return AppColors.amber;
      case EventType.cleared:
        return AppColors.signalGreen;
      case EventType.rerouted:
        return AppColors.danger;
    }
  }
}

class TimelineLinePainter extends CustomPainter {
  final Color color;

  TimelineLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(4, 0), Offset(4, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
