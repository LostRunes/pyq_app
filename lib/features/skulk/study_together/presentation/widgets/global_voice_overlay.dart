import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/study_together_providers.dart';
import '../../../../../app/router.dart';

/// Drop this into MaterialApp.builder as a Stack wrapper.
/// It watches voice state directly and renders the floating bubble
/// above all routes without any OverlayEntry complexity.
class GlobalVoiceOverlayStack extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalVoiceOverlayStack({required this.child, super.key});

  @override
  ConsumerState<GlobalVoiceOverlayStack> createState() =>
      _GlobalVoiceOverlayStackState();
}

class _GlobalVoiceOverlayStackState
    extends ConsumerState<GlobalVoiceOverlayStack> {
  Offset? _position;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceRoomNotifierProvider);
    final isScreenActive = ref.watch(voiceRoomScreenActiveProvider);

    final showBubble = voiceState.status == VoiceConnectionStatus.connected &&
        !isScreenActive &&
        voiceState.activeRoom != null;

    if (kDebugMode) {
      debugPrint(
        '[VoiceBubble] showBubble=$showBubble '
        'status=${voiceState.status} '
        'isScreenActive=$isScreenActive '
        'room=${voiceState.activeRoom?.id}',
      );
    }

    if (!showBubble) {
      // Reset expanded state when bubble hides
      if (_isExpanded) _isExpanded = false;
      return widget.child;
    }

    final size = MediaQuery.of(context).size;
    _position ??= Offset(size.width - 80, size.height - 180);

    return Stack(
      children: [
        // Main app content fills the full stack
        Positioned.fill(child: widget.child),
        // Floating draggable bubble
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: GestureDetector(
            onPanUpdate: (d) {
              setState(() {
                final newX = (_position!.dx + d.delta.dx)
                    .clamp(0.0, size.width - (_isExpanded ? 224.0 : 64.0));
                final newY = (_position!.dy + d.delta.dy)
                    .clamp(0.0, size.height - 80.0);
                _position = Offset(newX, newY);
              });
            },
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1B24).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.97),
                  borderRadius:
                      BorderRadius.circular(_isExpanded ? 28 : 32),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isExpanded
                    ? _buildExpandedPill(context, voiceState)
                    : _buildCollapsedBubble(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedBubble(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.volume_up_rounded,
                color: theme.colorScheme.primary, size: 26),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1B24)
                        : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPill(BuildContext context, VoiceRoomState voiceState) {
    final theme = Theme.of(context);
    final notifier = ref.read(voiceRoomNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            icon: voiceState.isLocalMuted
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            color: voiceState.isLocalMuted
                ? Colors.red[400]!
                : theme.colorScheme.primary,
            onTap: notifier.toggleMute,
          ),
          _Btn(
            icon: Icons.open_in_new_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            onTap: () {
              setState(() => _isExpanded = false);
              AppRouter.navigatorKey.currentState?.pushNamed(
                '/study-together/chat',
                arguments: voiceState.activeRoom,
              );
            },
          ),
          _Btn(
            icon: Icons.call_end_rounded,
            color: Colors.white,
            background: Colors.red[600]!,
            onTap: () {
              setState(() => _isExpanded = false);
              notifier.leaveVoice();
            },
          ),
          _Btn(
            icon: Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            onTap: () => setState(() => _isExpanded = false),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Tooltip is intentionally omitted: this widget lives in MaterialApp.builder,
    // above the Navigator, so no Overlay ancestor exists for Tooltip to use.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
