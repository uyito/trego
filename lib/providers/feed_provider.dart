import 'package:flutter/material.dart';
import '../models/activity.dart';

/// Activity feed provider. Stub implementation — the real feed lands
/// with the Feed spec.
class FeedProvider extends ChangeNotifier {
  List<Activity> friendsRecent({required int limit}) => const [];
}
