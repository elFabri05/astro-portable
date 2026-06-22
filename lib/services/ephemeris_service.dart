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
    // Sweph.init() loads the native library and optionally copies bundled .se1
    // assets from the assets/ephe/ folder.  Pass asset paths if you bundle them.
    await Sweph.init();
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

    // HeavenlyBody(int) constructs an arbitrary body ID.
    // In sweph packages that use a sealed enum without a public constructor,
    // replace HeavenlyBody(id) with the named constant (e.g. HeavenlyBody.SE_SUN)
    // for ids 0–20, and check if the package exposes swe_calc_ut(double, int, int).
    try {
      final coord = Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _baseFlags);
      return _fromCoord(bodyId, coord);
    } catch (_) {
      // File missing or body out of ephemeris range — fall back to Moshier
      // (only works for bodies with sweId < 10000).
      if (def.sweId < 10000) {
        try {
          final coord =
              Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _moshierFlags);
          return _fromCoord(bodyId, coord);
        } catch (_) {
          return null;
        }
      }
      return null; // asteroid without its .se1 file — skip silently
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
