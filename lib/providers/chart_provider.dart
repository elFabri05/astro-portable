import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/aspect.dart';
import '../models/body_position.dart';
import '../models/celestial_body_definition.dart';
import '../services/ephemeris_service.dart';

// ── State ───────────────────────────────────────────────────────────────

@immutable
class ChartState {
  final DateTime utcTime;
  final Set<String> enabledBodyIds;
  final List<BodyPosition> positions;
  final List<Aspect> aspects;
  final bool isComputing;

  const ChartState({
    required this.utcTime,
    required this.enabledBodyIds,
    this.positions = const [],
    this.aspects = const [],
    this.isComputing = false,
  });

  ChartState copyWith({
    DateTime? utcTime,
    Set<String>? enabledBodyIds,
    List<BodyPosition>? positions,
    List<Aspect>? aspects,
    bool? isComputing,
  }) =>
      ChartState(
        utcTime: utcTime ?? this.utcTime,
        enabledBodyIds: enabledBodyIds ?? this.enabledBodyIds,
        positions: positions ?? this.positions,
        aspects: aspects ?? this.aspects,
        isComputing: isComputing ?? this.isComputing,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────

class ChartNotifier extends StateNotifier<ChartState> {
  ChartNotifier()
      : super(ChartState(
          utcTime: DateTime.now().toUtc(),
          enabledBodyIds: Set.unmodifiable(kDefaultOnIds),
        )) {
    _recompute();
  }

  // ── Public API ─────────────────────────────────────────────────────

  void stepHour(int delta) => _applyTime(state.utcTime.add(Duration(hours: delta)));
  void stepDay(int delta) => _applyTime(state.utcTime.add(Duration(days: delta)));

  void stepMonth(int delta) {
    final t = state.utcTime;
    final totalMonths = t.year * 12 + (t.month - 1) + delta;
    final newYear = totalMonths ~/ 12;
    final newMonth = totalMonths % 12 + 1;
    final lastDay = DateTime.utc(newYear, newMonth + 1, 0).day;
    final newDay = t.day.clamp(1, lastDay);
    _applyTime(DateTime.utc(newYear, newMonth, newDay, t.hour, t.minute, t.second));
  }

  void stepYear(int delta) {
    final t = state.utcTime;
    final newYear = t.year + delta;
    // Clamp Feb 29 to Feb 28 in non-leap years.
    final lastDay = DateTime.utc(newYear, t.month + 1, 0).day;
    final newDay = t.day.clamp(1, lastDay);
    _applyTime(DateTime.utc(newYear, t.month, newDay, t.hour, t.minute, t.second));
  }

  /// Jump to [localDate] while keeping the current local wall-clock time-of-day.
  void jumpToDate(DateTime localDate) {
    final localNow = state.utcTime.toLocal();
    final merged = DateTime(
      localDate.year, localDate.month, localDate.day,
      localNow.hour, localNow.minute, localNow.second,
    );
    _applyTime(merged.toUtc());
  }

  void resetToNow() => _applyTime(DateTime.now().toUtc());

  void toggleBody(String bodyId) {
    final enabled = Set<String>.from(state.enabledBodyIds);
    if (enabled.contains(bodyId)) {
      enabled.remove(bodyId);
    } else {
      enabled.add(bodyId);
    }
    state = state.copyWith(enabledBodyIds: Set.unmodifiable(enabled));
    _recompute();
  }

  // ── Internal ───────────────────────────────────────────────────────

  void _applyTime(DateTime utc) {
    state = state.copyWith(utcTime: utc);
    _recompute();
  }

  void _recompute() {
    state = state.copyWith(isComputing: true);
    // All Swiss Ephemeris calls are synchronous but fast (~1 ms total).
    // Run in a microtask so the UI can render the "computing" state first.
    Future.microtask(() {
      final positions = EphemerisService.instance
          .computeAll(state.utcTime, state.enabledBodyIds);

      final fanned = _applyFanOut(positions);

      final ids = fanned.map((p) => p.bodyId).toList();
      final lons = fanned.map((p) => p.longitude).toList();
      final aspects = computeAspects(lons, ids);

      state = state.copyWith(
        positions: fanned,
        aspects: aspects,
        isComputing: false,
      );
    });
  }

  // ── Fan-out collision avoidance ────────────────────────────────────

  static const double _minSeparationDeg = 8.0;

  List<BodyPosition> _applyFanOut(List<BodyPosition> positions) {
    if (positions.length <= 1) return positions;

    // Sort by longitude, keeping the original objects paired with indices.
    final indexed = positions
        .asMap()
        .entries
        .toList()
      ..sort((a, b) => a.value.longitude.compareTo(b.value.longitude));

    // Group into clusters where adjacent bodies are within _minSeparationDeg.
    final clusters = <List<MapEntry<int, BodyPosition>>>[];
    var current = [indexed.first];

    for (int i = 1; i < indexed.length; i++) {
      final gap =
          indexed[i].value.longitude - indexed[i - 1].value.longitude;
      // Also handle wrap-around at 360°.
      if (gap < _minSeparationDeg) {
        current.add(indexed[i]);
      } else {
        clusters.add(current);
        current = [indexed[i]];
      }
    }
    clusters.add(current);

    // Check for a wrap-around cluster spanning 0°/360°.
    if (clusters.length >= 2) {
      final first = clusters.first.first.value.longitude;
      final last = clusters.last.last.value.longitude;
      if ((360.0 - last + first) < _minSeparationDeg) {
        // Merge last cluster into first.
        clusters.first.insertAll(0, clusters.removeLast());
      }
    }

    // Build display-longitude map.
    final displayLon = <int, double>{};
    for (final cluster in clusters) {
      if (cluster.length == 1) {
        displayLon[cluster.first.key] = cluster.first.value.longitude;
      } else {
        final centroid = cluster
                .map((e) => e.value.longitude)
                .reduce((a, b) => a + b) /
            cluster.length;
        final spread = math.max(
            _minSeparationDeg * (cluster.length - 1),
            _minSeparationDeg);
        final half = spread / 2;
        for (int i = 0; i < cluster.length; i++) {
          final offset = cluster.length == 1
              ? 0.0
              : -half + (spread * i / (cluster.length - 1));
          displayLon[cluster[i].key] = (centroid + offset) % 360.0;
        }
      }
    }

    return [
      for (int i = 0; i < positions.length; i++)
        positions[i].withDisplayLongitude(displayLon[i] ?? positions[i].longitude)
    ];
  }
}

// ── Provider ─────────────────────────────────────────────────────────────

final chartProvider = StateNotifierProvider<ChartNotifier, ChartState>(
  (_) => ChartNotifier(),
);
