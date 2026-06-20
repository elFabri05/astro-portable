import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/aspect.dart';
import '../models/body_position.dart';
import '../models/celestial_body_definition.dart';
import '../providers/chart_provider.dart';

// ── Coordinate helpers ───────────────────────────────────────────────────
//
// Convention: 0° Aries is at the 9-o'clock position (left).
// Ecliptic longitude increases counterclockwise on screen.
//
//   canvas angle = π - L × π/180
//
// Verification:
//   L=0   (Aries)     → angle π     → LEFT   (9 o'clock) ✓
//   L=90  (Cancer)    → angle π/2   → BOTTOM (6 o'clock) ✓
//   L=180 (Libra)     → angle 0     → RIGHT  (3 o'clock) ✓
//   L=270 (Capricorn) → angle -π/2  → TOP   (12 o'clock) ✓

Offset _lonToOffset(Offset center, double r, double longitude) {
  final a = math.pi - longitude * math.pi / 180.0;
  return Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
}

// ── Zodiac data ───────────────────────────────────────────────────────────

const List<String> _kSignGlyphs = [
  '♈', '♉', '♊', '♋', '♌', '♍',
  '♎', '♏', '♐', '♑', '♒', '♓',
];

// Traditional elemental colors (semi-transparent fills for zodiac segments).
const List<Color> _kSignColors = [
  Color(0x33FF6633), // Aries   – fire
  Color(0x3366AA44), // Taurus  – earth
  Color(0x3366BBDD), // Gemini  – air
  Color(0x334466CC), // Cancer  – water
  Color(0x33FF6633), // Leo     – fire
  Color(0x3366AA44), // Virgo   – earth
  Color(0x3366BBDD), // Libra   – air
  Color(0x334466CC), // Scorpio – water
  Color(0x33FF6633), // Sagittarius – fire
  Color(0x3366AA44), // Capricorn   – earth
  Color(0x3366BBDD), // Aquarius    – air
  Color(0x334466CC), // Pisces      – water
];

// ── Painter ───────────────────────────────────────────────────────────────

class WheelPainter extends CustomPainter {
  final ChartState chartState;

  const WheelPainter(this.chartState);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = math.min(cx, cy) - 6;

    // Radii as fractions of outerR.
    final rOuter = outerR;
    final rTickOuter = outerR * 0.97;
    final rZodiacOuter = outerR * 0.88;
    final rZodiacInner = outerR * 0.72;
    final rBodyLine = outerR * 0.68;    // where the "pointer" tick sits
    final rGlyph = outerR * 0.60;      // glyph centre radius
    final rAspect = outerR * 0.48;     // aspect circle

    // ── Background ─────────────────────────────────────────────────────
    final bgPaint = Paint()..color = const Color(0xFF0D1B2A);
    canvas.drawCircle(center, rOuter, bgPaint);

    // ── Zodiac ring ────────────────────────────────────────────────────
    _drawZodiacRing(canvas, center, rZodiacOuter, rZodiacInner);

    // ── Degree tick marks in the outer band (rTickOuter → rZodiacOuter) ─
    _drawDegreeMarks(canvas, center, rTickOuter, rZodiacOuter);

    // ── Sign glyphs ────────────────────────────────────────────────────
    _drawSignGlyphs(canvas, center,
        (rZodiacOuter + rTickOuter) / 2, rZodiacOuter, rZodiacInner);

    // ── Reference circles ──────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = const Color(0xFF334466)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, rOuter, ringPaint);
    canvas.drawCircle(center, rZodiacOuter, ringPaint);
    canvas.drawCircle(center, rZodiacInner, ringPaint);
    canvas.drawCircle(center, rAspect,
        Paint()..color = const Color(0xFF223355)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // ── Aspect lines ───────────────────────────────────────────────────
    if (chartState.positions.isNotEmpty) {
      _drawAspectLines(canvas, center, rAspect, chartState.positions,
          chartState.aspects);
    }

    // ── Bodies ─────────────────────────────────────────────────────────
    for (final pos in chartState.positions) {
      _drawBody(canvas, center, pos, rZodiacInner, rBodyLine, rGlyph);
    }
  }

  // ── Zodiac ring segments ──────────────────────────────────────────────

  void _drawZodiacRing(
      Canvas canvas, Offset center, double rOuter, double rInner) {
    final rect = Rect.fromCircle(center: center, radius: rOuter);
    final innerRect = Rect.fromCircle(center: center, radius: rInner);
    for (int i = 0; i < 12; i++) {
      // Segment fill
      final fillPaint = Paint()
        ..color = _kSignColors[i]
        ..style = PaintingStyle.fill;
      final path = Path()
        ..arcTo(rect, _startAngle(i), -math.pi / 6, false)
        ..arcTo(innerRect, _startAngle(i + 1), math.pi / 6, false)
        ..close();
      canvas.drawPath(path, fillPaint);

      // Radial divider at each 30° boundary
      final divPaint = Paint()
        ..color = const Color(0xFF334466)
        ..strokeWidth = 0.8;
      final pOuter = _lonToOffset(center, rOuter, i * 30.0);
      final pInner = _lonToOffset(center, rInner, i * 30.0);
      canvas.drawLine(pOuter, pInner, divPaint);
    }
  }

  static double _startAngle(int signIndex) =>
      math.pi - signIndex * math.pi / 6;

  // ── Degree ticks ──────────────────────────────────────────────────────

  void _drawDegreeMarks(
      Canvas canvas, Offset center, double rOuter, double rZodiacOuter) {
    for (int deg = 0; deg < 360; deg++) {
      double tickLen;
      double strokeW;
      Color col;
      if (deg % 30 == 0) {
        tickLen = (rZodiacOuter - rOuter) * 0.9;
        strokeW = 1.2;
        col = const Color(0xFF667799);
      } else if (deg % 10 == 0) {
        tickLen = (rZodiacOuter - rOuter) * 0.55;
        strokeW = 0.9;
        col = const Color(0xFF445566);
      } else if (deg % 5 == 0) {
        tickLen = (rZodiacOuter - rOuter) * 0.38;
        strokeW = 0.7;
        col = const Color(0xFF334455);
      } else {
        tickLen = (rZodiacOuter - rOuter) * 0.20;
        strokeW = 0.5;
        col = const Color(0xFF223344);
      }
      final paint = Paint()
        ..color = col
        ..strokeWidth = strokeW;
      final pOuter = _lonToOffset(center, rZodiacOuter, deg.toDouble());
      final pInner =
          _lonToOffset(center, rZodiacOuter - tickLen, deg.toDouble());
      canvas.drawLine(pOuter, pInner, paint);
    }
  }

  // ── Sign glyphs ───────────────────────────────────────────────────────

  void _drawSignGlyphs(Canvas canvas, Offset center, double rLabel,
      double rOuter, double rInner) {
    for (int i = 0; i < 12; i++) {
      final midLon = i * 30.0 + 15.0;
      final pos = _lonToOffset(center, (rOuter + rInner) / 2, midLon);
      _drawCenteredText(canvas, pos, _kSignGlyphs[i],
          const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13));
    }
  }

  // ── Aspect lines ──────────────────────────────────────────────────────

  void _drawAspectLines(Canvas canvas, Offset center, double rAspect,
      List<BodyPosition> positions, List<Aspect> aspects) {
    // Build longitude lookup
    final lonByBodyId = {for (final p in positions) p.bodyId: p.longitude};

    for (final aspect in aspects) {
      final lonA = lonByBodyId[aspect.bodyIdA];
      final lonB = lonByBodyId[aspect.bodyIdB];
      if (lonA == null || lonB == null) continue;

      final def = kAspectDefs
          .firstWhere((d) => d.type == aspect.type);

      // Opacity diminishes with orb (tight aspect = more opaque).
      final alpha = ((1 - aspect.orb / def.orb) * 0.55).clamp(0.1, 0.55);
      final paint = Paint()
        ..color = def.color.withOpacity(alpha)
        ..strokeWidth = 1.0;

      canvas.drawLine(
        _lonToOffset(center, rAspect, lonA),
        _lonToOffset(center, rAspect, lonB),
        paint,
      );
    }
  }

  // ── Single body ────────────────────────────────────────────────────────

  void _drawBody(Canvas canvas, Offset center, BodyPosition pos,
      double rZodiacInner, double rBodyLine, double rGlyph) {
    final def = kBodyById[pos.bodyId];
    if (def == null) return;

    // Dot at actual longitude on the inner zodiac circle boundary.
    final dotPos = _lonToOffset(center, rZodiacInner - 3, pos.longitude);
    final dotPaint = Paint()..color = def.color;
    canvas.drawCircle(dotPos, 2.5, dotPaint);

    // Connector line from zodiac inner edge to glyph position
    // (only drawn when the display longitude differs from actual).
    final glyphPos = _lonToOffset(center, rGlyph, pos.displayLongitude);
    final lineEnd = _lonToOffset(center, rBodyLine, pos.displayLongitude);

    if ((pos.displayLongitude - pos.longitude).abs() > 2) {
      final linePaint = Paint()
        ..color = def.color.withOpacity(0.4)
        ..strokeWidth = 0.7;
      canvas.drawLine(dotPos, lineEnd, linePaint);
    }

    // Tick mark at display longitude on the body line circle.
    final tickPaint = Paint()
      ..color = def.color.withOpacity(0.7)
      ..strokeWidth = 1.0;
    final tickOuter = _lonToOffset(center, rBodyLine, pos.displayLongitude);
    final tickInner =
        _lonToOffset(center, rBodyLine - 5, pos.displayLongitude);
    canvas.drawLine(tickOuter, tickInner, tickPaint);

    // Glyph (with retrograde suffix).
    final glyph =
        pos.isRetrograde ? '${def.glyph}R' : def.glyph;
    _drawCenteredText(
      canvas,
      glyphPos,
      glyph,
      TextStyle(
        color: def.color,
        fontSize: def.glyph.length == 1 ? 12.0 : 9.0,
        fontWeight: FontWeight.w600,
      ),
    );

    // Degree-within-sign label below the glyph.
    final degStr =
        '${pos.degreeInSign}°${pos.minuteInDegree.toString().padLeft(2, '0')}\'';
    _drawCenteredText(
      canvas,
      glyphPos.translate(0, 13),
      degStr,
      const TextStyle(color: Color(0xFF8899AA), fontSize: 7.5),
    );
  }

  // ── Text helper ───────────────────────────────────────────────────────

  void _drawCenteredText(Canvas canvas, Offset center, String text,
      TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.chartState != chartState;
}
