import 'record_state.dart';

/// User-facing error copy. One source of truth so product copy
/// review happens in a single file.
class RecordErrorsCopy {
  RecordErrorsCopy._();

  static const firstDenyTitle = 'Location needed';
  static const firstDenyBody = 'Trego needs your location to track runs.';
  static const firstDenyPrimary = 'Try again';
  static const firstDenySecondary = 'Not now';

  static const permanentDenyTitle = 'Location needed';
  static const permanentDenyBody =
      "Trego needs your location to track runs. You'll need to grant access in Settings.";
  static const permanentDenyPrimary = 'Open Settings';
  static const permanentDenySecondary = 'Not now';

  static const gpsUnavailableTitle = 'No GPS signal';
  static const gpsUnavailableBody =
      "Can't get a GPS fix. Try moving outside or into an open area.";
  static const gpsUnavailablePrimary = 'Retry';
  static const gpsUnavailableSecondary = 'Cancel';

  static const revokedBanner = 'Location disabled — tap to fix or end run.';
  static const offlineBanner = "Offline — will save when you're online.";
  static const revokedSummaryBanner = 'Incomplete — location disabled partway through.';
  static const unexpectedTitle = 'Recording stopped';
  static const unexpectedBody =
      "We hit an error. Your run has been saved up to now.";
  static const unexpectedPrimary = 'View summary';
}

/// Lookup from [RecordError] to a (title, body, primary, secondary) tuple.
({String title, String body, String primary, String secondary}) copyFor(RecordError e) {
  switch (e) {
    case RecordError.permissionDenied:
      return (
        title: RecordErrorsCopy.firstDenyTitle,
        body: RecordErrorsCopy.firstDenyBody,
        primary: RecordErrorsCopy.firstDenyPrimary,
        secondary: RecordErrorsCopy.firstDenySecondary,
      );
    case RecordError.permissionPermanentlyDenied:
      return (
        title: RecordErrorsCopy.permanentDenyTitle,
        body: RecordErrorsCopy.permanentDenyBody,
        primary: RecordErrorsCopy.permanentDenyPrimary,
        secondary: RecordErrorsCopy.permanentDenySecondary,
      );
    case RecordError.gpsUnavailable:
      return (
        title: RecordErrorsCopy.gpsUnavailableTitle,
        body: RecordErrorsCopy.gpsUnavailableBody,
        primary: RecordErrorsCopy.gpsUnavailablePrimary,
        secondary: RecordErrorsCopy.gpsUnavailableSecondary,
      );
    case RecordError.unknown:
      return (
        title: RecordErrorsCopy.unexpectedTitle,
        body: RecordErrorsCopy.unexpectedBody,
        primary: RecordErrorsCopy.unexpectedPrimary,
        secondary: '',
      );
  }
}
