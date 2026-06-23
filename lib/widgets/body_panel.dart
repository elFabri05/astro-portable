import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/celestial_body_definition.dart';
import '../providers/chart_provider.dart';

class InlineBodySelector extends ConsumerWidget {
  const InlineBodySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(chartProvider).enabledBodyIds;
    final notifier = ref.read(chartProvider.notifier);

    return Container(
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Celestial Bodies',
              style: TextStyle(
                  color: Color(0xFFCCDDEE),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _Section(
              title: 'Classic Planets & Nodes',
              category: BodyCategory.classic,
              extra: const [BodyCategory.node],
              enabled: enabled,
              onToggle: notifier.toggleBody),
          _Section(
              title: 'Main Asteroids',
              category: BodyCategory.mainAsteroid,
              enabled: enabled,
              onToggle: notifier.toggleBody),
          _Section(
              title: 'Centaurs',
              category: BodyCategory.centaur,
              enabled: enabled,
              onToggle: notifier.toggleBody),
          _Section(
              title: 'Trans-Neptunian Objects',
              category: BodyCategory.tno,
              enabled: enabled,
              onToggle: notifier.toggleBody),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final BodyCategory category;
  final List<BodyCategory> extra;
  final Set<String> enabled;
  final void Function(String) onToggle;

  const _Section({
    required this.title,
    required this.category,
    this.extra = const [],
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bodies = kAllBodies
        .where((b) => b.category == category || extra.contains(b.category))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFF667799),
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final body in bodies)
              _BodyChip(
                def: body,
                isOn: enabled.contains(body.id),
                onTap: () => onToggle(body.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _BodyChip extends StatelessWidget {
  final CelestialBodyDef def;
  final bool isOn;
  final VoidCallback onTap;

  const _BodyChip({required this.def, required this.isOn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? def.color.withOpacity(0.22) : const Color(0xFF0A1520),
          border: Border.all(
            color: isOn ? def.color.withOpacity(0.8) : const Color(0xFF223344),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              def.glyph,
              style: TextStyle(
                  color: isOn ? def.color : const Color(0xFF445566),
                  fontSize: def.glyph.length == 1 ? 14 : 10,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 5),
            Text(
              def.name,
              style: TextStyle(
                  color: isOn
                      ? const Color(0xFFCCDDEE)
                      : const Color(0xFF445566),
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
