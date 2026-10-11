import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/algo_visualizer_providers.dart';

class StatusPanel extends ConsumerWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(algoVizProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final st = s.stats;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(s.meta.complexity, style: const TextStyle(fontSize: 11,
                  color: Color(0xFF818CF8), fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Text('Step ${s.cursor}/${s.events.length}',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: s.progress,
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.15)),
          const SizedBox(height: 8),
          Text(s.message, style: TextStyle(fontSize: 13,
            color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          if (st != null) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              _stat('Cmp', st.comparisons), _stat('Swap', st.swaps),
              _stat('Write', st.writes), _stat('Visit', st.visits),
              _stat('Edge', st.edgeExaminations),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _stat(String k, int v) =>
      Text('$k: $v', style: const TextStyle(fontSize: 11, color: Colors.grey));
}