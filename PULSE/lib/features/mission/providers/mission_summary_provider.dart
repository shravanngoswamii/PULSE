import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_ev/features/mission/models/mission_summary_model.dart';

final missionSummaryProvider = FutureProvider<MissionSummaryModel>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return MissionSummaryModel.mock();
});
