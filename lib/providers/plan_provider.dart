import 'package:flutter/material.dart';
import '../models/planned_workout.dart';

/// Training plan provider. Stub implementation — the real plan generator
/// lands with the Plan spec.
class PlanProvider extends ChangeNotifier {
  PlannedWorkout? today() => null;
  String? progressSummary() => null;
}
