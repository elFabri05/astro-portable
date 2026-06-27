import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';

import '../models/body_position.dart';
import '../models/celestial_body_definition.dart';

final SwephFlag _baseFlags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED;
final SwephFlag _moshierFlags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SPEED;

// Individual asteroid / TNO .se1 files bundled in our assets/ephe/ directory.
// Both 5-digit and 6-digit forms are included for compatibility with different
// libsweph versions (SE naming changed from se#####.se1 to se######.se1).
const List<String> _kOurEpheAssets = [
  'assets/ephe/s136108.se1',   // Haumea
  'assets/ephe/s136199.se1',   // Eris
  'assets/ephe/s136472.se1',   // Makemake
  'assets/ephe/se007066.se1',  // Nessus   (6-digit)
  'assets/ephe/se010199.se1',  // Chariklo (6-digit)
  'assets/ephe/se020000.se1',  // Varuna   (6-digit)
  'assets/ephe/se028978.se1',  // Ixion    (6-digit)
  'assets/ephe/se050000.se1',  // Quaoar   (6-digit)
  'assets/ephe/se090377.se1',  // Sedna    (6-digit)
  'assets/ephe/se090482.se1',  // Orcus    (6-digit)
  'assets/ephe/se07066.se1',   // Nessus   (5-digit fallback)
  'assets/ephe/se10199.se1',   // Chariklo (5-digit fallback)
  'assets/ephe/se20000.se1',   // Varuna   (5-digit fallback)
  'assets/ephe/se28978.se1',   // Ixion    (5-digit fallback)
  'assets/ephe/se50000.se1',   // Quaoar   (5-digit fallback)
  'assets/ephe/se90377.se1',   // Sedna    (5-digit fallback)
  'assets/ephe/se90482.se1',   // Orcus    (5-digit fallback)
];

class EphemerisService {
  EphemerisService._();
  static final EphemerisService instance = EphemerisService._();

  bool _initialized = false;

  /// Call once at startup.  Initialises the native sweph library.
  Future<void> initialize() async {
    if (_initialized) return;

    // The sweph package's saveEpheAssets() calls saveEpheFile() without
    // awaiting it, creating a race: swe_set_ephe_path() runs before the
    // files finish writing on the first install.  We extract all assets
    // ourselves (properly awaited) then call Sweph.init(epheAssets: [])
    // which only loads the native library and sets swe_set_ephe_path —
    // the empty list skips the broken extraction loop entirely.
    if (!kIsWeb) {
      try {
        await _extractAllEpheAssets();
      } catch (e) {
        debugPrint('[Ephemeris] Asset extraction failed: $e');
      }
    }

    try {
      await Sweph.init(epheAssets: []);
    } catch (e) {
      debugPrint('[Ephemeris] Sweph.init failed: $e');
    }

    _initialized = true;
  }

  Future<void> _extractAllEpheAssets() async {
    final appSupportDir = (await getApplicationSupportDirectory()).path;
    final epheFilesPath = p.join(appSupportDir, 'ephe_files');
    Directory(epheFilesPath).createSync(recursive: true);

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      // Desktop: read directly from the on-disk flutter_assets directory —
      // faster and avoids rootBundle buffering quirks on some builds.
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final flutterAssets = p.join(exeDir, 'data', 'flutter_assets');
      _copyEpheDir(
        p.join(flutterAssets, 'packages', 'sweph', 'assets', 'ephe'),
        epheFilesPath,
      );
      _copyEpheDir(
        p.join(flutterAssets, 'assets', 'ephe'),
        epheFilesPath,
      );
    } else {
      // Android / iOS: extract via rootBundle (properly awaited).
      final allAssets = [...Sweph.bundledEpheAssets, ..._kOurEpheAssets];
      for (final assetPath in allAssets) {
        final destName = p.basename(assetPath);
        final destFile = File(p.join(epheFilesPath, destName));
        if (destFile.existsSync()) continue;
        try {
          final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
          await destFile.writeAsBytes(bytes);
          debugPrint('[Ephemeris] Extracted $destName');
        } catch (e) {
          debugPrint('[Ephemeris] Failed to extract $destName: $e');
        }
      }
    }
  }

  static void _copyEpheDir(String src, String dest) {
    final dir = Directory(src);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.endsWith('.se1') && !name.endsWith('.txt')) continue;
      final destFile = File(p.join(dest, name));
      if (!destFile.existsSync()) {
        destFile.writeAsBytesSync(entity.readAsBytesSync());
        debugPrint('[Ephemeris] Extracted $name');
      }
    }
  }

  // ── Julian Day ──────────────────────────────────────────────────────

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
        final pos = _computeBody('true_node', jd);
        if (pos != null) northNodePos = pos;
        continue;
      }
      if (id == 'south_node') continue;

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
    if (def.sweId == kSouthNodeSyntheticId) return null;

    try {
      final coord = Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _baseFlags);
      return _fromCoord(bodyId, coord);
    } catch (e) {
      debugPrint('[Ephemeris] SWIEPH failed for $bodyId (sweId=${def.sweId}): $e');

      if (def.sweId >= 10000) return null;

      if (def.sweId <= 9) {
        try {
          final coord =
              Sweph.swe_calc_ut(jd, HeavenlyBody(def.sweId), _moshierFlags);
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
