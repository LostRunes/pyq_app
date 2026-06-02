import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/doubt.dart';
import '../providers/skulk_providers.dart';
import 'report_bottom_sheet.dart';

class DoubtCard extends ConsumerWidget {
  final Doubt doubt;
  final VoidCallback onTap;

  const DoubtCard({
    super.key,
    required this.doubt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voteState = ref.watch(userVotesProvider);
    final isUpvoted = voteState.value?[doubt.id] ?? false;

    final cardBorder = isDark ? const Color(0xFF3E2361) : Colors.grey[200]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1125) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: doubt.isSolved
                ? (isDark ? Colors.green.withOpacity(0.4) : Colors.green.withOpacity(0.3))
                : cardBorder,
            width: doubt.isSolved ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: doubt.isSolved
                  ? Colors.green.withOpacity(0.04)
                  : (isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03)),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Author + solved badge + report menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(
                    (doubt.authorAvatarUrl != null && doubt.authorAvatarUrl!.isNotEmpty)
                        ? doubt.authorAvatarUrl!
                        : 'assets/images/pikachu.png',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doubt.authorDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[200] : Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🔥 ${doubt.authorReputation}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '@${doubt.authorUsername} • ${_formatRelativeTime(doubt.createdAt)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (doubt.isSolved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Solved',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                // ⋮ Report menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18,
                      color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  onSelected: (value) {
                    if (value == 'report') {
                      ReportBottomSheet.show(
                        context,
                        target: ReportTarget.doubt,
                        targetId: doubt.id,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Text('Report', style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Cozy subject chip
            if (doubt.subjectName.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _subjectColor(doubt.subjectName).withOpacity(isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _subjectColor(doubt.subjectName).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📘 ', style: const TextStyle(fontSize: 10)),
                    Flexible(
                      child: Text(
                        doubt.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _subjectColor(doubt.subjectName),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Title
            Text(
              doubt.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.25,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 6),

            // Description body preview
            Text(
              doubt.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),

            if (doubt.imageUrls.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  getThumbnailUrl(doubt.imageUrls.first),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Row 3: Tags
            if (doubt.tags.isNotEmpty)
              SizedBox(
                height: 24,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: doubt.tags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final tag = doubt.tags[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF271B36) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 22),

            // Row 4: Actions
            Row(
              children: [
                // Upvote
                InkWell(
                  onTap: () {
                    ref.read(userVotesProvider.notifier).toggleDoubtVote(doubt.id);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUpvoted
                          ? (isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.1))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUpvoted ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
                          size: 16,
                          color: isUpvoted ? Colors.amber[600] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doubt.upvotesCount}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUpvoted ? Colors.amber[600] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Answers count
                Row(
                  children: [
                    Icon(
                      doubt.answersCount > 0
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: doubt.answersCount > 0 ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doubt.answersCount == 1
                          ? '1 solution'
                          : '${doubt.answersCount} solutions',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: doubt.answersCount > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Comments count
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${doubt.commentsCount}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Consistent color per subject name, using hash for determinism.
  static Color _subjectColor(String subjectName) {
    final colors = [
      const Color(0xFF8B5CF6), // violet
      const Color(0xFF3B82F6), // blue
      const Color(0xFF10B981), // emerald
      const Color(0xFFF59E0B), // amber
      const Color(0xFFEF4444), // red
      const Color(0xFFEC4899), // pink
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF84CC16), // lime
    ];
    final idx = subjectName.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

String getThumbnailUrl(String url) {
  return url.replaceFirst(
    '/upload/',
    '/upload/w_500,q_70,f_webp/',
  );
}
