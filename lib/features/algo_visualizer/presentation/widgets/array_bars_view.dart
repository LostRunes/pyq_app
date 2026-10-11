import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/algo_visualizer_providers.dart';

class ArrayBarsView extends ConsumerWidget {
  const ArrayBarsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(algoVizProvider);
    final arr = s.displayArray;
    if (arr.isEmpty) return const Center(child: Text('Empty array'));
    final maxV = arr.reduce((a, b) => a > b ? a : b).toDouble().clamp(1.0, 999.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color barColor(int i) {
      if (s.sorted.contains(i)) return const Color(0xFF10B981);
      if (s.swap.contains(i)) return const Color(0xFFEF4444);
      if (s.compare.contains(i)) return const Color(0xFFF59E0B);
      if (s.pivot == i) return const Color(0xFF8B5CF6);
      if (s.pointerM == i) return const Color(0xFF6366F1);
      if (s.rangeStart != null && s.rangeEnd != null && (i < s.rangeStart! || i > s.rangeEnd!)) {
        return (isDark ? Colors.white : Colors.black).withOpacity(0.15);
      }
      return const Color(0xFF6366F1);
    }

    return Column(
      children: [
        // pointer labels (binary search: lo/mid/hi, quick sort: left/right).
        // Always reserve the same height so the bars below never jump
        // and overflow when pointers appear mid-partition.
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            height: 15,
            child: (s.pointerL != null || s.pointerM != null || s.pointerR != null)
                ? Text('lo=${s.pointerL ?? '-'}  mid=${s.pointerM ?? '-'}  hi=${s.pointerR ?? '-'}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54))
                : null,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reserve space for value label (~14) + gaps (6) + index label (~12).
              const reservedLabels = 36.0;
              final maxBarH =
                  (constraints.maxHeight - reservedLabels).clamp(60.0, 200.0);
              const minBarH = 24.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < arr.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 14,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${arr[i]}', style: TextStyle(fontSize: 10,
                                  color: isDark ? Colors.white70 : Colors.black54)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              height: minBarH + (maxBarH - minBarH) * (arr[i] / maxV),
                              decoration: BoxDecoration(
                                color: barColor(i),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 12,
                              child: Text('$i', style: TextStyle(fontSize: 9,
                                color: isDark ? Colors.white38 : Colors.black38)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}