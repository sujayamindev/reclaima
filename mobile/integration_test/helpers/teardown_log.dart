import 'package:flutter/foundation.dart';

/// Tracks resources created during a test run so they can be cleaned up even if
/// the run aborts before the app-driven deletion phase.
///
/// For the auth slice the only tracked resource is the test account, but later
/// slices (receipts, claims) register S3 objects and backend records here and
/// reuse the same best-effort [cleanUp] pass.
class TeardownLog {
  final List<_CleanupEntry> _entries = [];

  /// Registers a cleanup [action] for a created [resource] (description used in
  /// logs). Cleanup actions run in reverse order of registration.
  void register(String resource, Future<void> Function() action) {
    _entries.add(_CleanupEntry(resource, action));
  }

  /// Runs every registered cleanup action (most-recent first), swallowing
  /// individual failures so one bad cleanup doesn't block the rest.
  Future<void> cleanUp() async {
    for (final entry in _entries.reversed) {
      try {
        await entry.action();
        debugPrint('[TeardownLog] cleaned up: ${entry.resource}');
      } catch (e) {
        debugPrint('[TeardownLog] failed to clean up ${entry.resource}: $e');
      }
    }
    _entries.clear();
  }
}

class _CleanupEntry {
  _CleanupEntry(this.resource, this.action);

  final String resource;
  final Future<void> Function() action;
}
