import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers.dart';
import '../../../../utils/auth_dialog.dart';
import '../../data/models/solution.dart';
import '../providers/skulk_providers.dart';
import 'report_bottom_sheet.dart';
import '../../../../widgets/common/cloudinary_image_gallery.dart';

class SolutionTile extends ConsumerWidget {
  final Solution solution;
  final bool isDoubtOwner;
  final VoidCallback onToggleAccept;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCommentTap;

  const SolutionTile({
    super.key,
    required this.solution,
    required this.isDoubtOwner,
    required this.onToggleAccept,
    required this.onEdit,
    required this.onDelete,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voteState = ref.watch(userVotesProvider);
    final isUpvoted = voteState.value?[solution.id] ?? false;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnSolution =
        currentUserId != null && currentUserId == solution.userId;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final acceptedBg = isDark
        ? Colors.green.withOpacity(0.06)
        : Colors.green.withOpacity(0.03);
    final acceptedBorder = isDark
        ? Colors.green.withOpacity(0.4)
        : Colors.green.withOpacity(0.3);
    final regularBorder = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: solution.isAccepted ? acceptedBg : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: solution.isAccepted ? acceptedBorder : regularBorder,
          width: solution.isAccepted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(
                  (solution.authorAvatarUrl != null &&
                          solution.authorAvatarUrl!.isNotEmpty)
                      ? solution.authorAvatarUrl!
                      : 'assets/images/pikachu.png',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            solution.authorDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blue.withOpacity(0.15)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🔥 ${solution.authorReputation}',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue[400],
                            ),
                          ),
                        ),
                        if (solution.isAccepted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'ACCEPTED',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${solution.authorUsername} • ${_formatRelativeTime(solution.createdAt)}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit/Delete for Owner | Report for others
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  } else if (value == 'report') {
                    if (ref.read(isGuestProvider)) {
                      showLoginRequiredDialog(context, 'report content');
                    } else {
                      ReportBottomSheet.show(
                        context,
                        target: ReportTarget.solution,
                        targetId: solution.id,
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (isOwnSolution) ...[
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Solution',
                            style: GoogleFonts.outfit(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Report',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Solution Text Body
          Text(
            solution.body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: isDark ? Colors.grey[200] : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),

          if (solution.imageUrls.isNotEmpty) ...[
            CloudinaryImageGallery(imageUrls: solution.imageUrls, height: 140),
            const SizedBox(height: 12),
          ],

          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.grey[850] : Colors.grey[100],
          ),
          const SizedBox(height: 10),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Upvote Toggle Button
                  InkWell(
                    onTap: () {
                      if (ref.read(isGuestProvider)) {
                        showLoginRequiredDialog(context, 'upvote solutions');
                      } else {
                        ref
                            .read(userVotesProvider.notifier)
                            .toggleSolutionVote(solution.id, solution.postId);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isUpvoted
                            ? (isDark
                                  ? Colors.amber.withOpacity(0.15)
                                  : Colors.amber.withOpacity(0.1))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUpvoted
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_upward_outlined,
                            size: 16,
                            color: isUpvoted ? Colors.amber[600] : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${solution.upvotesCount}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isUpvoted
                                  ? Colors.amber[600]
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Comment Count trigger
                  InkWell(
                    onTap: onCommentTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Comment',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Accept Checkbox Action (Only visible to Doubt owner, or glowing accept button)
              if (isDoubtOwner)
                TextButton.icon(
                  onPressed: onToggleAccept,
                  style: TextButton.styleFrom(
                    foregroundColor: solution.isAccepted
                        ? Colors.grey
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  icon: Icon(
                    solution.isAccepted
                        ? Icons.remove_circle_outline
                        : Icons.check_circle_rounded,
                    size: 16,
                  ),
                  label: Text(
                    solution.isAccepted ? 'Unaccept' : 'Accept Solution',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
