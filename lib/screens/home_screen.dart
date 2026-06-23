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

    // Reserve enough of the viewport for the chart to be useful, while leaving
    // a visible peek of the body selector so the user knows to scroll down.
    final stickyHeight = MediaQuery.of(context).size.height * 0.67;

    return Scaffold(
      backgroundColor: const Color(0xFF060F18),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _ChartSliverDelegate(
                height: stickyHeight,
                localTime: localTime,
                isComputing: state.isComputing,
                onJump: () => showDialog(
                  context: context,
                  builder: (_) => const DateJumpDialog(),
                ),
                onNow: notifier.resetToNow,
                chartState: state,
              ),
            ),
            const SliverToBoxAdapter(
              child: InlineBodySelector(),
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed-height pinned sliver that holds the header bar, chart wheel, and
// time steppers. minExtent == maxExtent prevents any collapsing on scroll.
class _ChartSliverDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final DateTime localTime;
  final bool isComputing;
  final VoidCallback onJump;
  final VoidCallback onNow;
  final ChartState chartState;

  _ChartSliverDelegate({
    required this.height,
    required this.localTime,
    required this.isComputing,
    required this.onJump,
    required this.onNow,
    required this.chartState,
  });

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF060F18),
      child: Column(
        children: [
          _Header(
            localTime: localTime,
            isComputing: isComputing,
            onJump: onJump,
            onNow: onNow,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomPaint(
                painter: WheelPainter(chartState),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF0A1520),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const TimeStepperBar(),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ChartSliverDelegate old) => true;
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
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Color(0xFF556677))),
            ),
          TextButton.icon(
            onPressed: onJump,
            icon: const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF7799BB)),
            label: const Text('Jump',
                style: TextStyle(color: Color(0xFF7799BB), fontSize: 12)),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8)),
          ),
          TextButton.icon(
            onPressed: onNow,
            icon: const Icon(Icons.my_location,
                size: 14, color: Color(0xFF55AA88)),
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
