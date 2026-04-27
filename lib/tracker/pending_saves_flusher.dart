import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'run_model.dart';

/// Abstraction so we can swap the save implementation in tests.
abstract class RunSaver {
  Future<void> save(Run run);
}

/// Default RunSaver that writes to the `users/{uid}/runs/` collection.
class FirestoreRunSaver implements RunSaver {
  @override
  Future<void> save(Run run) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(run.userId)
        .collection('runs')
        .add(run.toMap());
  }
}

/// Durable queue for runs whose initial Firestore write failed.
/// Queue lives in SharedPreferences. Capped at 20 entries (oldest-dropped).
class PendingSavesFlusher {
  static const _key = 'record.pendingSaves';
  static const _capacity = 20;

  final RunSaver _saver;

  PendingSavesFlusher({required RunSaver saver}) : _saver = saver;

  int _lastPendingCount = 0;
  int get pendingCount => _lastPendingCount;

  Future<void> enqueue(Run run) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toList();
    current.add(jsonEncode(_toJson(run)));
    while (current.length > _capacity) {
      current.removeAt(0);
    }
    await prefs.setStringList(_key, current);
    _lastPendingCount = current.length;
  }

  Future<int> flush() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = (prefs.getStringList(_key) ?? []).toList();
    if (queue.isEmpty) {
      _lastPendingCount = 0;
      return 0;
    }
    var saved = 0;
    final remaining = <String>[];
    for (final entry in queue) {
      try {
        await _saver.save(_fromJson(jsonDecode(entry) as Map<String, dynamic>));
        saved++;
      } catch (_) {
        remaining.add(entry); // keep it for next time
      }
    }
    await prefs.setStringList(_key, remaining);
    _lastPendingCount = remaining.length;
    return saved;
  }

  /// Start listening for connectivity changes and attempt one immediate flush.
  /// Wire in lib/app.dart at startup.
  Future<void> start() async {
    await flush();
    // Connectivity listener is added in the lib/app.dart wiring task (Task 21).
  }

  Map<String, dynamic> _toJson(Run run) {
    final map = run.toMap();
    // Timestamps from Firestore aren't JSON-serializable; use ISO strings.
    // FieldValue (e.g., serverTimestamp) is also non-encodable; drop it.
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      if (v is FieldValue) return; // skip server-side sentinels
      if (v is Timestamp) {
        result[k] = v.toDate().toIso8601String();
        return;
      }
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        result[k] = v
            .cast<Map<String, dynamic>>()
            .map((m) => m.map((kk, vv) => vv is Timestamp
                ? MapEntry(kk, vv.toDate().toIso8601String())
                : MapEntry(kk, vv)))
            .toList();
        return;
      }
      result[k] = v;
    });
    return result;
  }

  Run _fromJson(Map<String, dynamic> json) {
    final map = json.map((k, v) {
      if (v is String && _isIsoDate(v)) {
        return MapEntry(k, Timestamp.fromDate(DateTime.parse(v)));
      }
      if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
        return MapEntry(
          k,
          v
              .cast<Map<String, dynamic>>()
              .map((m) => m.map((kk, vv) => vv is String && _isIsoDate(vv)
                  ? MapEntry(kk, Timestamp.fromDate(DateTime.parse(vv)))
                  : MapEntry(kk, vv)))
              .toList(),
        );
      }
      return MapEntry(k, v);
    });
    return Run.fromMap(map, 'queued');
  }

  bool _isIsoDate(String s) => RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(s);
}
