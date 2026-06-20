import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

import '../models/body_position.dart';
import '../models/celestial_body_definition.dart';

// Swiss Ephemeris flag constants (bitfield).
const int _kSeflgSwieph = 2;   // use .se1 files
const int _kSeflgSpeed = 256;  // compute speed (for retrograde detection)
const int _kSeflgMoseph = 4;   // Moshier fallback (planets only, no files needed)

const int _baseFlags = _kSeflgSwieph | _kSeflgSpeed;
const int _moshierFlags = _kSeflgMoseph | _kSeflgSpeed;

class EphemerisService {
  EphemerisService._();
  static final EphemerisService instance = EphemerisService._();

  bool _initialized = false;

  /// Call once at startup.  Extracts bundled .se1 assets to the documents
  /// directory and points libswe at that directory.
  Future<void> initialize() async {
    if (_initialized) return;

    final epheDir = await _extractEphemerisAssets();
    Sweph.swe_set_ephe_path(epheDir);
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

    // We need the North Node position whenever the South Node is requested.
    bool needNorthNode = false;
    BodyPosition? northNodePos;
    final sortedIds = bodyIds.toList();
    if (sortedIds.contains('south_node')) {
      needNorthNode = true;
      if (!sortedIds.contains('true_node')) {
        // Ensure we compute the north node even if not explicitly requested.
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

  BodyPosition _fromCoord(String bodyId, CoordinateWithSpeed coord) {
    // CoordinateWithSpeed field names may vary by sweph package version:
    //   coord.speedLon  — used here (sweph ≥ 2.8)
    //   coord.speedLong — alternative name in some versions
    // If you get a compile error on coord.speedLon, rename it to coord.speedLong.
    final speed = coord.speedLon;
    return BodyPosition(
      bodyId: bodyId,
      longitude: coord.longitude % 360.0,
      latitude: coord.latitude,
      distance: coord.distance,
      speedLon: speed,
      isRetrograde: speed < 0,
    );
  }

  // ── Asset extraction ─────────────────────────────────────────────────

  Future<String> _extractEphemerisAssets() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final epheDir = Directory('${docsDir.path}/ephe');
    if (!epheDir.existsSync()) {
      epheDir.createSync(recursive: true);
    }

    // Discover which .se1 files are bundled as assets.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assetPaths = manifest
        .listAssets()
        .where((p) => p.startsWith('assets/ephe/') && p.endsWith('.se1'))
        .toList();

    for (final assetPath in assetPaths) {
      final fileName = assetPath.split('/').last;
      final dest = File('${epheDir.path}/$fileName');
      // Only copy if the file doesn't exist yet (avoids re-copying on every launch).
      if (!dest.existsSync()) {
        final data = await rootBundle.load(assetPath);
        await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
    }

    return epheDir.path;
  }
}
