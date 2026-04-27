/// High-level state of the Record flow's SessionController.
enum RecordState {
  idle,
  preStart,
  countdown,
  recording,
  paused,
  confirming,
  saving,
  summary,
  error,
}

/// Why a run is currently paused.
enum PauseReason { manual, auto, permissionRevoke }

/// Terminal error conditions.
enum RecordError { permissionDenied, permissionPermanentlyDenied, gpsUnavailable, unknown }
