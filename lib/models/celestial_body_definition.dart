import 'package:flutter/material.dart';

enum BodyCategory { classic, node, mainAsteroid, centaur, tno }

class CelestialBodyDef {
  final String id;
  final String name;
  // Swiss Ephemeris integer body ID.  For minor planets: 10000 + MPC number.
  final int sweId;
  // Unicode glyph or 3-letter abbreviation used on the canvas.
  final String glyph;
  final Color color;
  final BodyCategory category;
  final bool defaultOn;

  const CelestialBodyDef({
    required this.id,
    required this.name,
    required this.sweId,
    required this.glyph,
    required this.color,
    required this.category,
    this.defaultOn = false,
  });
}

// SE_AST_OFFSET = 10000 (minor planets accessed via 10000 + MPC number)
const int _ast = 10000;

// Swiss Ephemeris body IDs for built-in bodies
const int _SE_SUN = 0;
const int _SE_MOON = 1;
const int _SE_MERCURY = 2;
const int _SE_VENUS = 3;
const int _SE_MARS = 4;
const int _SE_JUPITER = 5;
const int _SE_SATURN = 6;
const int _SE_URANUS = 7;
const int _SE_NEPTUNE = 8;
const int _SE_PLUTO = 9;
const int _SE_TRUE_NODE = 11; // True North Node; South Node = opposite
const int _SE_MEAN_APOG = 12; // Black Moon Lilith (mean apogee)
const int _SE_CHIRON = 15;
const int _SE_PHOLUS = 16;
const int _SE_CERES = 17;
const int _SE_PALLAS = 18;
const int _SE_JUNO = 19;
const int _SE_VESTA = 20;

/// Special synthetic ID: the South Node is always 180° opposite the true node.
/// The ephemeris service derives it from _SE_TRUE_NODE.
const int kSouthNodeSyntheticId = -11;

const List<CelestialBodyDef> kAllBodies = [
  // ── Classic planets (always on) ─────────────────────────────────────
  CelestialBodyDef(id: 'sun', name: 'Sun', sweId: _SE_SUN,
      glyph: '☉', color: Color(0xFFFFD700),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'moon', name: 'Moon', sweId: _SE_MOON,
      glyph: '☽', color: Color(0xFFE0E0E0),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'mercury', name: 'Mercury', sweId: _SE_MERCURY,
      glyph: '☿', color: Color(0xFF9370DB),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'venus', name: 'Venus', sweId: _SE_VENUS,
      glyph: '♀', color: Color(0xFF00CED1),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'mars', name: 'Mars', sweId: _SE_MARS,
      glyph: '♂', color: Color(0xFFFF4500),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'jupiter', name: 'Jupiter', sweId: _SE_JUPITER,
      glyph: '♃', color: Color(0xFFFF8C00),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'saturn', name: 'Saturn', sweId: _SE_SATURN,
      glyph: '♄', color: Color(0xFFB0A090),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'uranus', name: 'Uranus', sweId: _SE_URANUS,
      glyph: '♅', color: Color(0xFF40E0D0),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'neptune', name: 'Neptune', sweId: _SE_NEPTUNE,
      glyph: '♆', color: Color(0xFF4169E1),
      category: BodyCategory.classic, defaultOn: true),
  CelestialBodyDef(id: 'pluto', name: 'Pluto', sweId: _SE_PLUTO,
      glyph: '♇', color: Color(0xFFAA66AA),
      category: BodyCategory.classic, defaultOn: true),

  // ── Nodes & Lilith (always on by default) ───────────────────────────
  CelestialBodyDef(id: 'true_node', name: 'North Node', sweId: _SE_TRUE_NODE,
      glyph: '☊', color: Color(0xFFDAA520),
      category: BodyCategory.node, defaultOn: true),
  CelestialBodyDef(id: 'south_node', name: 'South Node', sweId: kSouthNodeSyntheticId,
      glyph: '☋', color: Color(0xFFDAA520),
      category: BodyCategory.node, defaultOn: true),
  CelestialBodyDef(id: 'lilith', name: 'Lilith', sweId: _SE_MEAN_APOG,
      glyph: 'Lil', color: Color(0xFF778899),
      category: BodyCategory.node, defaultOn: true),

  // ── Main asteroids (optional) ────────────────────────────────────────
  CelestialBodyDef(id: 'ceres', name: 'Ceres', sweId: _SE_CERES,
      glyph: 'Cer', color: Color(0xFF8FBC8F),
      category: BodyCategory.mainAsteroid),
  CelestialBodyDef(id: 'pallas', name: 'Pallas', sweId: _SE_PALLAS,
      glyph: 'Pal', color: Color(0xFF20B2AA),
      category: BodyCategory.mainAsteroid),
  CelestialBodyDef(id: 'juno', name: 'Juno', sweId: _SE_JUNO,
      glyph: 'Jun', color: Color(0xFFDDA0DD),
      category: BodyCategory.mainAsteroid),
  CelestialBodyDef(id: 'vesta', name: 'Vesta', sweId: _SE_VESTA,
      glyph: 'Ves', color: Color(0xFFF0E68C),
      category: BodyCategory.mainAsteroid),
  CelestialBodyDef(id: 'hygiea', name: 'Hygiea', sweId: _ast + 10,
      glyph: 'Hyg', color: Color(0xFF90EE90),
      category: BodyCategory.mainAsteroid),

  // ── Centaurs (optional) ──────────────────────────────────────────────
  CelestialBodyDef(id: 'chiron', name: 'Chiron', sweId: _SE_CHIRON,
      glyph: 'Chi', color: Color(0xFFFF6347),
      category: BodyCategory.centaur),
  CelestialBodyDef(id: 'pholus', name: 'Pholus', sweId: _SE_PHOLUS,
      glyph: 'Pho', color: Color(0xFFFF7F50),
      category: BodyCategory.centaur),
  CelestialBodyDef(id: 'nessus', name: 'Nessus', sweId: _ast + 7066,
      glyph: 'Nes', color: Color(0xFFE9967A),
      category: BodyCategory.centaur),
  CelestialBodyDef(id: 'chariklo', name: 'Chariklo', sweId: _ast + 10199,
      glyph: 'Cha', color: Color(0xFFF4A460),
      category: BodyCategory.centaur),

  // ── Trans-Neptunian Objects (optional) ──────────────────────────────
  CelestialBodyDef(id: 'eris', name: 'Eris', sweId: _ast + 136199,
      glyph: 'Eri', color: Color(0xFFE75480),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'haumea', name: 'Haumea', sweId: _ast + 136108,
      glyph: 'Hau', color: Color(0xFFDB7093),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'makemake', name: 'Makemake', sweId: _ast + 136472,
      glyph: 'Mak', color: Color(0xFFC71585),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'sedna', name: 'Sedna', sweId: _ast + 90377,
      glyph: 'Sed', color: Color(0xFFDC143C),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'orcus', name: 'Orcus', sweId: _ast + 90482,
      glyph: 'Orc', color: Color(0xFFB22222),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'quaoar', name: 'Quaoar', sweId: _ast + 50000,
      glyph: 'Qua', color: Color(0xFFCD5C5C),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'ixion', name: 'Ixion', sweId: _ast + 28978,
      glyph: 'Ixi', color: Color(0xFFF08080),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'gonggong', name: 'Gonggong', sweId: _ast + 225088,
      glyph: 'Gon', color: Color(0xFFFA8072),
      category: BodyCategory.tno),
  CelestialBodyDef(id: 'varuna', name: 'Varuna', sweId: _ast + 20000,
      glyph: 'Var', color: Color(0xFFE9967A),
      category: BodyCategory.tno),
];

final Map<String, CelestialBodyDef> kBodyById = {
  for (final b in kAllBodies) b.id: b,
};

final Set<String> kDefaultOnIds = {
  for (final b in kAllBodies)
    if (b.defaultOn) b.id,
};
