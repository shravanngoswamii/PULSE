import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/widgets/pulse_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../simulation_controller.dart';

class SimulationEventLog extends StatefulWidget {
  final List<SimulationEvent> events;
  final SimulationStatus status;

  const SimulationEventLog({
    super.key,
    required this.events,
    required this.status,
  });

  @override
  State<SimulationEventLog> createState() => _SimulationEventLogState();
}

class _SimulationEventLogState extends State<SimulationEventLog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(SimulationEventLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length > oldWidget.events.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulation Event Log',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.status == SimulationStatus.running)
                const StatusBadge(type: BadgeType.live)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'IDLE',
                    style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (widget.events.isEmpty)
            _buildEmptyState()
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.events.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, thickness: 0.5),
                itemBuilder: (context, index) {
                  final event = widget.events[index];
                  return _buildEventRow(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.terminal, color: AppColors.textHint, size: 32),
            const SizedBox(height: 8),
            Text(
              'No events yet',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
            ),
            Text(
              'Press START to begin simulation',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventRow(SimulationEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: 44, // Minimum height implicitly or flexible
          color: _getEventColor(event.type),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(event.timestamp),
                      style: AppTypography.mono.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                ..._buildMessageLines(event.message),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMessageLines(String message) {
    final lines = message.split('\n');
    return [
      Text(
        lines[0],
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (lines.length > 1)
        Text(
          lines[1],
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
    ];
  }

  Color _getEventColor(SimEventType type) {
    switch (type) {
      case SimEventType.dispatch:
        return AppColors.primary;
      case SimEventType.prediction:
        return AppColors.amber;
      case SimEventType.cleared:
        return AppColors.signalGreen;
      case SimEventType.alert:
        return AppColors.danger;
      case SimEventType.recovery:
        return const Color(0xFF8B5CF6);
      case SimEventType.density:
        return AppColors.textHint;
    }
  }
}
