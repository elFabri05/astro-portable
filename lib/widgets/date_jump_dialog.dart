import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chart_provider.dart';

class DateJumpDialog extends ConsumerStatefulWidget {
  const DateJumpDialog({super.key});

  @override
  ConsumerState<DateJumpDialog> createState() => _DateJumpDialogState();
}

class _DateJumpDialogState extends ConsumerState<DateJumpDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    final local = ref.read(chartProvider).utcTime.toLocal();
    _year = local.year;
    _month = local.month;
    _day = local.day;
  }

  @override
  Widget build(BuildContext context) {
    final last = _lastDayOfMonth(_year, _month);
    if (_day > last) _day = last;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A2A3A),
      title: const Text('Jump to date',
          style: TextStyle(color: Color(0xFFCCDDEE))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RowStepper(
            label: 'Year',
            value: _year.toString(),
            onUp: () => setState(() => _year++),
            onDown: () => setState(() => _year--),
          ),
          const SizedBox(height: 8),
          _RowStepper(
            label: 'Month',
            value: _monthName(_month),
            onUp: () => setState(() => _month = _month % 12 + 1),
            onDown: () => setState(() => _month = (_month - 2 + 12) % 12 + 1),
          ),
          const SizedBox(height: 8),
          _RowStepper(
            label: 'Day',
            value: _day.toString().padLeft(2, '0'),
            onUp: () => setState(() => _day = _day % last + 1),
            onDown: () => setState(() => _day = (_day - 2 + last) % last + 1),
          ),
          const SizedBox(height: 4),
          Text('Time-of-day is preserved from the current chart.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF6688AA))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF224466)),
          onPressed: () {
            ref.read(chartProvider.notifier).jumpToDate(
                  DateTime(_year, _month, _day),
                );
            Navigator.pop(context);
          },
          child: const Text('Go', style: TextStyle(color: Color(0xFFCCDDEE))),
        ),
      ],
    );
  }

  static int _lastDayOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static String _monthName(int m) => _monthNames[m];
}

class _RowStepper extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _RowStepper({
    required this.label,
    required this.value,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13)),
        ),
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          color: const Color(0xFFAABBCC),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onDown,
        ),
        SizedBox(
          width: 60,
          child: Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFDDEEFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          color: const Color(0xFFAABBCC),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onUp,
        ),
      ],
    );
  }
}
