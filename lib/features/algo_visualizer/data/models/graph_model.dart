import 'package:flutter/widgets.dart' show Offset;

class GraphNode {
  const GraphNode({required this.id, required this.label, required this.position});
  final int id;
  final String label;
  final Offset position;
}

class GraphEdge {
  const GraphEdge({required this.from, required this.to, required this.weight});
  final int from;
  final int to;
  final double weight;
}

class GraphModel {
  const GraphModel({required this.nodes, required this.edges});
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  String labelOf(int id) => nodes[id].label;

  GraphNode node(int id) => nodes[id];

  Iterable<GraphEdge> incident(int id) =>
      edges.where((e) => e.from == id || e.to == id);

  int other(GraphEdge edge, int id) => edge.from == id ? edge.to : edge.from;

  static String edgeKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';
}

const GraphModel demoGraph = GraphModel(
  nodes: [
    GraphNode(id: 0, label: 'A', position: Offset(0.50, 0.08)),
    GraphNode(id: 1, label: 'B', position: Offset(0.24, 0.34)),
    GraphNode(id: 2, label: 'C', position: Offset(0.76, 0.34)),
    GraphNode(id: 3, label: 'D', position: Offset(0.12, 0.70)),
    GraphNode(id: 4, label: 'E', position: Offset(0.44, 0.60)),
    GraphNode(id: 5, label: 'F', position: Offset(0.66, 0.72)),
    GraphNode(id: 6, label: 'G', position: Offset(0.90, 0.62)),
  ],
  edges: [
    GraphEdge(from: 0, to: 1, weight: 4),
    GraphEdge(from: 0, to: 2, weight: 5),
    GraphEdge(from: 1, to: 3, weight: 6),
    GraphEdge(from: 1, to: 4, weight: 3),
    GraphEdge(from: 2, to: 4, weight: 2),
    GraphEdge(from: 2, to: 6, weight: 7),
    GraphEdge(from: 2, to: 5, weight: 8),
    GraphEdge(from: 3, to: 4, weight: 2),
    GraphEdge(from: 4, to: 5, weight: 4),
    GraphEdge(from: 5, to: 6, weight: 3),
  ],
);