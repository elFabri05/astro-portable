import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart';

import '../models/body_position.dart';
import '../models/celestial_body_definition.dart';

final SwephFlag _baseFlags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
final SwephFlag _moshierFlags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SPEED;

class EphemerisService {
  EphemerisService._();
  static final EphemerisService instance = EphemerisService._();

  bool _initialized = false;

  /// Call once at startup.  Initialises the native sweph library.
  Future<void> initialize() async {
    if (_initialized) return;
    // Extract the three bundled sweph data files to the app's support directory
    // and point libswe at them via swe_set_ephe_path.
    //
    // seas_18.se1  → bodies 15–20: Chiron, Pholus, Ceres, Pallas, Juno, Vesta
    // sepl_18.se1  → bodies  0–14: Sun … Pluto, True Node, Lilith, etc.
    // semo_18.se1  → Moon
    //
    // Numbered bodies (sweId ≥ 10000) need individual seNNNNNN.se1 files which
    // are NOT bundled here; they will fail gracefully at compute time.
    // Do NOT add asset paths that don't exist: rootBundle.load() throws for
    // missing paths and that would prevent swe_set_ephe_path from ever being
    // called, breaking every non-Moshier computation.
    await Sweph.init(epheAssets: List<String>.from(Sweph.bundledEpheAssets));
    _initialized = true;
  }

  // ── Julian Day ──────────────────────────────────────────────────────

  /// Convert a UTC [DateTime] to Julian Day Number (UT), which is what
  /// swe_calc_ut expects.
  double toJulianDayUT(DateTime utc) {
    final hour = utc.hour + utc.minute / 60.0 + utc.second / 3600.0;
    return Sweph.swe_julday(
      utc.year,
      utc.month,
      utc.day,
      hour,
      CalendarType.SE_GREG_CAL,
    );
  }

  // ── Body computation ─────────────────────────────────────────────────

  /// Compute positions of all [bodyIds] for the given UTC [dateTime].
  /// Bodies that cannot be computed (e.g., missing ephemeris file) are
  /// silently omitted.
  List<BodyPosition> computeAll(DateTime utcTime, Iterable<String> bodyIds) {
    final jd = toJulianDayUT(utcTime);
    final results = <BodyPosition>[];

    bool needNorthNode = false;
    BodyPosition? northNodePos;
    final sortedIds = bodyIds.toList();
    if (sortedIds.contains('south_node')) {
      needNorthNode = true;
      if (!sortedIds.contains('true_node')) {
        sortedIds.add('__north_node_internal');
      }
    }

    for (final id in sortedIds) {
      if (id == '__north_node_internal') {
        // Internal request to get north node for south node derivation.
        final pos = _computeBody('true_node', jd);
        if (pos != null) northNodePos = pos;
        continue;
      }
      if (id == 'south_node') continue; // handled after the loop

      final pos = _computeBody(id, jd);
      if (pos != null) {
        results.add(pos);
        if (id == 'true_node') northNodePos = pos;
      }
    }

    if (needNorthNode) {
      final nnLon = northNodePos?.longitude;
      if (nnLon != null) {
        final snLon = (nnLon + 180.0) % 360.0;
        results.add(BodyPosition(
          bodyId: 'south_node',
          longitude: snLon,
          latitude: 0.0,
          distance: northNodePos!.distance,
          speedLon: northNodePos.speedLon,
          isRetrograde: northNodePos.isRetrograde,
        ));
      }
    }

    return results;
  }

  BodyPosition? _computeBody(String bodyId, double jd) {
    final def = kBodyById[bodyId];
    if (def == null) return null;
    if (def.sweId == kSouthNodeSyntheticId) return null; // handled separately

    try {
      final coord = Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _baseFlags);
      return _fromCoord(bodyId, coord);
    } catch (e) {
      debugPrint('[Ephemeris] SWIEPH failed for $bodyId (sweId=${def.sweId}): $e');

      if (def.sweId >= 10000) {
        // Numbered body: needs an individual seNNNNNN.se1 file that is not
        // bundled. Moshier cannot compute it either.
        final mpc = def.sweId - 10000;
        debugPrint('[Ephemeris]   → missing ast${mpc ~/ 1000}/se${mpc.toString().padLeft(6, '0')}.se1');
        return null;
      }

      // Moshier covers only the classic planets (sweId 0–9) and requires no
      // data files.  Bodies 10–22 (nodes, Chiron, main asteroids, etc.) are
      // NOT in Moshier; trying them would just produce a second silent failure.
      if (def.sweId <= 9) {
        try {
          final coord =
              Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _moshierFlags);
          debugPrint('[Ephemeris] Moshier fallback succeeded for $bodyId');
          return _fromCoord(bodyId, coord);
        } catch (e2) {
          debugPrint('[Ephemeris] Moshier also failed for $bodyId: $e2');
        }
      }
      return null;
    }
  }

  BodyPosition _fromCoord(String bodyId, CoordinatesWithSpeed coord) {
    final speed = coord.speedInLongitude;
    return BodyPosition(
      bodyId: bodyId,
      longitude: coord.longitude % 360.0,
      latitude: coord.latitude,
      distance: coord.distance,
      speedLon: speed,
      isRetrograde: speed < 0,
    );
  }

}
