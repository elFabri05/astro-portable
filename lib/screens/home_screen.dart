import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../painters/wheel_painter.dart';
import '../providers/chart_provider.dart';
import '../widgets/body_panel.dart';
import '../widgets/date_jump_dialog.dart';
import '../widgets/time_stepper.dart';

final _dateFmt = DateFormat('EEE d MMM yyyy  HH:mm');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartProvider);
    final notifier = ref.read(chartProvider.notifier);
    final localTime = state.utcTime.toLocal();

    return Scaffold(
      backgroundColor: const Color(0xFF060F18),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            _Header(
              localTime: localTime,
              isComputing: state.isComputing,
              onJump: () => showDialog(
                context: context,
                builder: (_) => const DateJumpDialog(),
              ),
              onNow: notifier.resetToNow,
            ),

            // ── Chart wheel ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: WheelPainter(state),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // ── Time steppers ─────────────────────────────────────────────
            Container(
              color: const Color(0xFF0A1520),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const TimeStepperBar(),
            ),
          ],
        ),
      ),

      // ── FAB → body selection sheet ────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A3050),
        foregroundColor: const Color(0xFF88AACC),
        tooltip: 'Celestial bodies',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BodySelectionSheet(),
        ),
        child: const Icon(Icons.star_outline),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime localTime;
  final bool isComputing;
  final VoidCallback onJump;
  final VoidCallback onNow;

  const _Header({
    required this.localTime,
    required this.isComputing,
    required this.onJump,
    required this.onNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1520),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Date/time display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateFmt.format(localTime),
                  style: const TextStyle(
                      color: Color(0xFFCCDDEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  'UTC ${localTime.toUtc().toIso8601String().substring(0, 16)}',
                  style: const TextStyle(
                      color: Color(0xFF667788), fontSize: 10),
                ),
              ],
            ),
          ),

          if (isComputing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5,
                      color: Color(0xFF556677))),
            ),

          // Jump to date
          TextButton.icon(
            onPressed: onJump,
            icon: const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF7799BB)),
            label: const Text('Jump',
                style: TextStyle(color: Color(0xFF7799BB), fontSize: 12)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),

          // Back to now
          TextButton.icon(
            onPressed: onNow,
            icon: const Icon(Icons.my_location, size: 14,
                color: Color(0xFF55AA88)),
            label: const Text('Now',
                style: TextStyle(color: Color(0xFF55AA88), fontSize: 12)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
        ],
      ),
    );
  }
}
