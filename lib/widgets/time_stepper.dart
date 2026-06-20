import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chart_provider.dart';

class TimeStepperBar extends ConsumerWidget {
  const TimeStepperBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chartProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stepper(label: 'Hour',
            onUp: () => notifier.stepHour(1),
            onDown: () => notifier.stepHour(-1)),
        _Stepper(label: 'Day',
            onUp: () => notifier.stepDay(1),
            onDown: () => notifier.stepDay(-1)),
        _Stepper(label: 'Month',
            onUp: () => notifier.stepMonth(1),
            onDown: () => notifier.stepMonth(-1)),
        _Stepper(label: 'Year',
            onUp: () => notifier.stepYear(1),
            onDown: () => notifier.stepYear(-1)),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _Stepper({
    required this.label,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(icon: Icons.keyboard_arrow_up, onTap: onUp),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8899BB), fontSize: 10, letterSpacing: 0.5)),
        _ArrowButton(icon: Icons.keyboard_arrow_down, onTap: onDown),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFFAABBCC), size: 22),
      ),
    );
  }
}
