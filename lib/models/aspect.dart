import 'package:flutter/material.dart';

enum AspectType { conjunction, sextile, square, trine, opposition }

class Aspect {
  final String bodyIdA;
  final String bodyIdB;
  final AspectType type;
  // Exact angular difference (0–180).
  final double orb;

  const Aspect({
    required this.bodyIdA,
    required this.bodyIdB,
    required this.type,
    required this.orb,
  });
}

class AspectDefinition {
  final AspectType type;
  final double angle;  // exact angle in degrees
  final double orb;   // allowed deviation in degrees
  final Color color;

  const AspectDefinition({
    required this.type,
    required this.angle,
    required this.orb,
    required this.color,
  });
}

const List<AspectDefinition> kAspectDefs = [
  AspectDefinition(type: AspectType.conjunction, angle: 0,
      orb: 8, color: Color(0xFFE0E0E0)),
  AspectDefinition(type: AspectType.sextile, angle: 60,
      orb: 4, color: Color(0xFF87CEEB)),
  AspectDefinition(type: AspectType.square, angle: 90,
      orb: 6, color: Color(0xFFFF4444)),
  AspectDefinition(type: AspectType.trine, angle: 120,
      orb: 6, color: Color(0xFF4488FF)),
  AspectDefinition(type: AspectType.opposition, angle: 180,
      orb: 8, color: Color(0xFFCC2222)),
];

/// Angular separation between two ecliptic longitudes, in the range 0–180.
double angularSeparation(double lonA, double lonB) {
  double diff = (lonA - lonB).abs() % 360;
  if (diff > 180) diff = 360 - diff;
  return diff;
}

List<Aspect> computeAspects(List<double> longitudes, List<String> ids) {
  final aspects = <Aspect>[];
  for (int i = 0; i < ids.length; i++) {
    for (int j = i + 1; j < ids.length; j++) {
      final sep = angularSeparation(longitudes[i], longitudes[j]);
      for (final def in kAspectDefs) {
        final deviation = (sep - def.angle).abs();
        if (deviation <= def.orb) {
          aspects.add(Aspect(
            bodyIdA: ids[i],
            bodyIdB: ids[j],
            type: def.type,
            orb: deviation,
          ));
          break; // only match the tightest aspect
        }
      }
    }
  }
  return aspects;
}
