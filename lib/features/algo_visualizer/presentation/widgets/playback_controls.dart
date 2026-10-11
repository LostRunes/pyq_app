import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/algo_visualizer_providers.dart';

class PlaybackControls extends ConsumerWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(algoVizProvider);
    final n = ref.read(algoVizProvider.notifier);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(onPressed: s.cursor > 0 ? n.prev : null,
              icon: const Icon(Icons.skip_previous_rounded)),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: s.playing ? n.pause : n.play,
              icon: Icon(s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: s.cursor < s.events.length ? n.next : null,
              icon: const Icon(Icons.skip_next_rounded)),
            const SizedBox(width: 8),
            IconButton.outlined(onPressed: n.reset,
              icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.slow_motion_video_rounded, size: 18),
            Expanded(
              child: Slider(
                value: s.speedMs.toDouble(), min: 100, max: 2000, divisions: 19,
                label: '${s.speedMs}ms/step',
                onChanged: (v) => n.setSpeed(v.toInt()),
              ),
            ),
            const Icon(Icons.fast_forward_rounded, size: 18),
            SizedBox(width: 64, child: Text('${s.speedMs}ms',
              textAlign: TextAlign.end, style: const TextStyle(fontSize: 11))),
          ],
        ),
      ],
    );
  }
}