import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/comment.dart';
import '../providers/skulk_providers.dart';
import 'report_bottom_sheet.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String doubtId;
  final String? answerId; // If null, this is for the main doubt post. Otherwise, for the answer.
  final String title;

  const CommentSection({
    super.key,
    required this.doubtId,
    this.answerId,
    required this.title,
  });

  /// Opens the CommentSection as a cozy sliding bottom sheet
  static void show(BuildContext context, String doubtId, String? answerId, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CommentSection(doubtId: doubtId, answerId: answerId, title: title),
      ),
    );
  }

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(commentsNotifierProvider(widget.doubtId).notifier)
          .addComment(body, answerId: widget.answerId);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showEditCommentDialog(Comment comment) {
    final editController = TextEditingController(text: comment.body);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Comment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Edit your comment...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = editController.text.trim();
                if (text.isNotEmpty) {
                  await ref
                      .read(commentsNotifierProvider(widget.doubtId).notifier)
                      .editComment(comment.id, text);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allComments = ref.watch(commentsNotifierProvider(widget.doubtId));

    // Filter comments based on whether they are for the main doubt or a specific answer
    final comments = allComments.where((c) {
      if (widget.answerId == null) {
        return c.answerId == null;
      } else {
        return c.answerId == widget.answerId;
      }
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle indicator
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: isDark ? Colors.grey[750] : Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No comments yet.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                      final isOwnComment = currentUserId != null && currentUserId == c.userId;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: AssetImage(
                              (c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty)
                                  ? c.authorAvatarUrl!
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
                                        c.authorDisplayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatRelativeTime(c.createdAt),
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.body,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.grey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _showEditCommentDialog(c);
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text('Delete Comment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to delete this comment?', style: GoogleFonts.outfit()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(commentsNotifierProvider(widget.doubtId).notifier)
                                      .deleteComment(c.id);
                                }
                              } else if (value == 'report') {
                                ReportBottomSheet.show(
                                  context,
                                  target: ReportTarget.comment,
                                  targetId: c.id,
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              if (isOwnComment) ...[
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text('Edit', style: GoogleFonts.outfit(fontSize: 12)),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Text('Delete', style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent)),
                                  ]),
                                ),
                              ],
                              PopupMenuItem(
                                value: 'report',
                                child: Row(children: [
                                  const Icon(Icons.flag_outlined, size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text('Report', style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Compose Box
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _commentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Add a helpful comment...',
                          hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitComment,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
