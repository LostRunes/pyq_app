import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../../data/algorithms/algorithm_registry.dart';
import '../../data/models/graph_model.dart';
import '../providers/algo_visualizer_providers.dart';
import '../widgets/array_bars_view.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/playback_controls.dart';
import '../widgets/status_panel.dart';

class AlgoVisualizerScreen extends ConsumerStatefulWidget {
  const AlgoVisualizerScreen({super.key});
  @override
  ConsumerState<AlgoVisualizerScreen> createState() => _AlgoVisualizerScreenState();
}

class _AlgoVisualizerScreenState extends ConsumerState<AlgoVisualizerScreen> {
  final _arrayCtrl = TextEditingController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _arrayCtrl.text = AlgorithmRegistry.defaultArray.join(', ');
  }

  @override
  void dispose() { _arrayCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(algoVizProvider);
    final n = ref.read(algoVizProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cats = ['All', 'Sorting', 'Searching', 'Graph'];
    final algos = AlgorithmRegistry.all
        .where((a) => _filter == 'All' || a.category == _filter).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Algo Visualizer',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // category filter — wires ALL 18 algos
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in cats)
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(c),
                    selected: _filter == c,
                    onSelected: (_) => setState(() => _filter = c))),
            ])),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: algos.any((a) => a.id == s.algorithmId) ? s.algorithmId : algos.first.id,
            decoration: const InputDecoration(labelText: 'Algorithm', border: OutlineInputBorder()),
            items: [for (final a in algos)
              DropdownMenuItem(value: a.id, child: Text('${a.name}  •  ${a.complexity}'))],
            onChanged: (v) {
              if (v != null) {
                n.selectAlgorithm(v);
                _arrayCtrl.text = ref.read(algoVizProvider).array.join(', ');
              }
            },
          ),
          Padding(padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(s.meta.description, style: GoogleFonts.outfit(fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54))),
          // editable input (Q2)
          if (!s.isGraph)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
              Expanded(child: TextField(controller: _arrayCtrl,
                decoration: InputDecoration(
                  labelText: s.isBinarySearch
                      ? 'Array (auto-sorted for binary search)'
                      : 'Array (comma separated, max 16)',
                  border: const OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.text)),
              IconButton(tooltip: 'Apply', onPressed: () {
                final vals = _arrayCtrl.text.split(RegExp(r'[^0-9]+'))
                    .where((e) => e.isNotEmpty).map(int.parse).toList();
                n.setArray(vals);
                _arrayCtrl.text = ref.read(algoVizProvider).array.join(', ');
              }, icon: const Icon(Icons.check_rounded)),
              IconButton(
                tooltip: s.isBinarySearch ? 'New random set' : 'Shuffle',
                onPressed: () {
                n.shuffleArray();
                _arrayCtrl.text = ref.read(algoVizProvider).array.join(', ');
              }, icon: const Icon(Icons.shuffle_rounded)),
              IconButton(tooltip: 'Random', onPressed: () {
                n.randomArray();
                _arrayCtrl.text = ref.read(algoVizProvider).array.join(', ');
              }, icon: const Icon(Icons.casino_rounded)),
            ]),
                if (s.isBinarySearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.searchTarget == null
                                ? 'Target: —'
                                : 'Target: ${s.searchTarget}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Binary search needs sorted data — shuffle deals a fresh set, then sorts it.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Row(children: [
              const Text('Start node: '),
              DropdownButton<int>(value: s.startNode,
                items: [for (final nd in demoGraph.nodes)
                  DropdownMenuItem(value: nd.id, child: Text(nd.label))],
                onChanged: (v) { if (v != null) n.setStartNode(v); }),
              const SizedBox(width: 8),
              Text('Graph: ${demoGraph.nodes.length} nodes, ${demoGraph.edges.length} edges',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          const SizedBox(height: 12),
          SizedBox(height: 280,
            child: Card(child: Padding(padding: const EdgeInsets.all(12),
              child: AnimatedSwitcher(duration: const Duration(milliseconds: 300),
                child: s.isGraph ? const GraphCanvas(key: ValueKey('g'))
                    : const ArrayBarsView(key: ValueKey('a')))))),
          const SizedBox(height: 12),
          const PlaybackControls(),
          const SizedBox(height: 8),
          const StatusPanel(),
        ],
      ),
    );
  }
}