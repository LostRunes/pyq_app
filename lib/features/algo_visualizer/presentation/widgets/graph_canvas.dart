import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/graph_model.dart';
import '../providers/algo_visualizer_providers.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(algoVizProvider);
    return LayoutBuilder(builder: (context, c) {
      return RepaintBoundary(
        child: CustomPaint(
          size: Size(c.maxWidth, c.maxHeight),
          painter: _GraphPainter(
            graph: demoGraph,
            visited: s.visited,
            current: s.currentNode,
            activeEdge: s.activeEdge,
            distances: s.distances,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      );
    });
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({required this.graph, required this.visited, required this.current,
    required this.activeEdge, required this.distances, required this.isDark});
  final GraphModel graph;
  final Set<int> visited;
  final int? current;
  final List<int> activeEdge;
  final Map<int, double> distances;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    Offset pos(int id) {
      final p = graph.node(id).position;
      return Offset(p.dx * size.width, p.dy * size.height + 10);
    }
    // edges
    for (final e in graph.edges) {
      final a = pos(e.from), b = pos(e.to);
      final active = activeEdge.length == 2 &&
          ((activeEdge[0] == e.from && activeEdge[1] == e.to) ||
           (activeEdge[0] == e.to && activeEdge[1] == e.from));
      final paint = Paint()
        ..color = active ? const Color(0xFFF59E0B) : (isDark ? Colors.white24 : Colors.black26)
        ..strokeWidth = active ? 4 : 2;
      canvas.drawLine(a, b, paint);
      // weight
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final tp = TextPainter(
        text: TextSpan(text: '${e.weight.toInt()}',
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54,
            backgroundColor: isDark ? const Color(0xFF171330) : Colors.white)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
    }
    // nodes
    for (final n in graph.nodes) {
      final c = pos(n.id);
      final isCur = current == n.id;
      final isVis = visited.contains(n.id);
      final color = isCur ? const Color(0xFFF59E0B)
          : isVis ? const Color(0xFF10B981) : const Color(0xFF6366F1);
      canvas.drawCircle(c, isCur ? 22 : 18,
        Paint()..color = color.withOpacity(0.25));
      canvas.drawCircle(c, isCur ? 18 : 15, Paint()..color = color);
      final label = '${n.label}${distances.containsKey(n.id) ? '\n${distances[n.id]!.toStringAsFixed(0)}' : ''}';
      final tp = TextPainter(
        text: TextSpan(text: label,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: 60);
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.visited != visited || old.current != current ||
      old.activeEdge != activeEdge || old.distances != distances;
}