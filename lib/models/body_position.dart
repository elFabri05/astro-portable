import 'package:flutter/foundation.dart';

@immutable
class BodyPosition {
  final String bodyId;
  // Ecliptic longitude 0-360°; 0° = Aries, increases counterclockwise.
  final double longitude;
  final double latitude;
  final double distance; // AU
  // Negative speed means retrograde motion.
  final double speedLon;
  final bool isRetrograde;

  // Canvas display longitude after fan-out collision avoidance (may differ from longitude).
  final double displayLongitude;

  const BodyPosition({
    required this.bodyId,
    required this.longitude,
    required this.latitude,
    required this.distance,
    required this.speedLon,
    required this.isRetrograde,
    double? displayLongitude,
  }) : displayLongitude = displayLongitude ?? longitude;

  BodyPosition withDisplayLongitude(double dl) => BodyPosition(
    bodyId: bodyId,
    longitude: longitude,
    latitude: latitude,
    distance: distance,
    speedLon: speedLon,
    isRetrograde: isRetrograde,
    displayLongitude: dl,
  );

  /// Degree within the current sign (0–29).
  int get degreeInSign => longitude.floor() % 30;

  /// Minute within the current degree (0–59).
  int get minuteInDegree => ((longitude - longitude.floor()) * 60).floor();
}
