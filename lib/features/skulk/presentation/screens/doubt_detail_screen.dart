import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/solution.dart';
import '../providers/skulk_providers.dart';
import '../widgets/comment_section.dart';
import '../widgets/solution_tile.dart';
import '../../../../widgets/common/cloudinary_image_gallery.dart';
import '../../data/services/cloudinary_service.dart';
import '../../utils/image_utils.dart';

class DoubtDetailScreen extends ConsumerStatefulWidget {
  const DoubtDetailScreen({super.key});

  @override
  ConsumerState<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends ConsumerState<DoubtDetailScreen> {
  final TextEditingController _solutionController = TextEditingController();
  bool _isSubmittingSolution = false;

  final ImagePicker _picker = ImagePicker();
  List<File> selectedSolutionImages = [];

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      
      final file = response.file;
      if (file != null) {
        final compressed = await ImageUtils.compressImage(File(file.path));
        if (compressed != null) {
          setState(() {
            selectedSolutionImages = List.from(selectedSolutionImages)..add(compressed);
          });
        }
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  Future<void> pickSolutionImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      
      final compressedFiles = await Future.wait(
        images.map((img) => ImageUtils.compressImage(File(img.path))),
      );
      final validFiles = compressedFiles.whereType<File>().toList();
      
      if (!mounted) return;
      setState(() {
        selectedSolutionImages = List.from(selectedSolutionImages)..addAll(validFiles);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _showSolutionImageSourceBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Images to Solution',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary),
                  title: Text('Take Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final image = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image == null) return;
                      
                      final compressed = await ImageUtils.compressImage(File(image.path));
                      if (compressed == null) return;
                      
                      if (!mounted) return;
                      setState(() {
                        selectedSolutionImages = List.from(selectedSolutionImages)..add(compressed);
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Failed to capture photo: $e')),
                      );
                    }
                  },
                ),
                Divider(color: isDark ? Colors.grey[850] : Colors.grey[200]),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
                  title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    pickSolutionImages();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
  }

  void _submitSolution(String doubtId) async {
    final body = _solutionController.text.trim();
    if (body.isEmpty) return;

    setState(() {
      _isSubmittingSolution = true;
    });

    List<String> uploadedUrls = [];
    bool hasFailedUploads = false;

    try {
      final uploadedResults = await Future.wait(
        selectedSolutionImages.map((img) => CloudinaryService.uploadImage(img)),
      );
      final uploadedUrls = uploadedResults.whereType<String>().toList();
      final hasFailedUploads = uploadedUrls.length < selectedSolutionImages.length;

      await ref.read(solutionsNotifierProvider(doubtId).notifier).addSolution(
            body,
            imageUrls: uploadedUrls,
          );

      _solutionController.clear();
      setState(() {
        selectedSolutionImages.clear();
      });
      FocusScope.of(context).unfocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: hasFailedUploads ? Colors.orange[850] : Colors.green,
          content: Text(
            hasFailedUploads
                ? 'Solution posted without some images ⚠️'
                : 'Solution posted successfully! ✨',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish solution: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSolution = false;
        });
      }
    }
  }

  void _showEditSolutionDialog(String doubtId, Solution solution) {
    final editController = TextEditingController(text: solution.body);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Edit Solution',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: editController,
            maxLines: 4,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Edit your explanation...',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              ),
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
                      .read(solutionsNotifierProvider(doubtId).notifier)
                      .editSolution(solution.id, text);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final doubtId = ModalRoute.of(context)!.settings.arguments as String;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch states
    final doubtAsync = ref.watch(doubtDetailProvider(doubtId));
    final solutions = ref.watch(solutionsNotifierProvider(doubtId));
    final voteState = ref.watch(userVotesProvider);
    final isUpvoted = voteState.value?[doubtId] ?? false;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final accentBg = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    final cardBorder = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Doubt Thread',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: doubtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading doubt: $err')),
        data: (doubt) {
          if (doubt == null) {
            return Center(
              child: Text(
                'Doubt not found.',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            );
          }

          final isDoubtOwner = currentUserId != null && currentUserId == doubt.userId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doubt Details Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          border: Border(
                            bottom: BorderSide(color: cardBorder),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
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
                                      color: Colors.green.withOpacity(0.15),
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
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Resolved Subject Name
                            if (doubt.subjectName.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.purple.withOpacity(0.15) : Colors.purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                ),
                                child: Text(
                                  doubt.subjectName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.purple[200] : Colors.purple[700],
                                  ),
                                ),
                              ),

                            // Title
                            Text(
                              doubt.title,
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 8),

                            // Body
                            Text(
                              doubt.body,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (doubt.imageUrls.isNotEmpty) ...[
                              CloudinaryImageGallery(imageUrls: doubt.imageUrls, height: 200),
                              const SizedBox(height: 16),
                            ],

                            // Tags Scrollable
                            if (doubt.tags.isNotEmpty)
                              SizedBox(
                                height: 26,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: doubt.tags.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                                  itemBuilder: (context, index) {
                                    final tag = doubt.tags[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accentBg,
                                        borderRadius: BorderRadius.circular(8),
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

                            const Divider(height: 32),

                            // Vote doubt & comments launcher
                            Row(
                              children: [
                                // Upvote Doubt Button
                                InkWell(
                                  onTap: () {
                                    ref.read(userVotesProvider.notifier).toggleDoubtVote(doubt.id);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isUpvoted
                                          ? (isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.1))
                                          : (isDark ? const Color(0xFF262626) : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isUpvoted ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
                                          size: 18,
                                          color: isUpvoted ? Colors.amber[600] : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${doubt.upvotesCount}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isUpvoted ? Colors.amber[600] : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Comments Toggle
                                InkWell(
                                  onTap: () {
                                    CommentSection.show(
                                      context,
                                      doubt.id,
                                      null,
                                      'Comments on Doubt',
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF262626) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${doubt.commentsCount} Comments',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Solutions List Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'SOLUTIONS',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${solutions.length}',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Solutions Tiles
                      solutions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 44,
                                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No solutions posted yet.',
                                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: solutions.length,
                              itemBuilder: (context, index) {
                                final sol = solutions[index];
                                return SolutionTile(
                                  solution: sol,
                                  isDoubtOwner: isDoubtOwner,
                                  onToggleAccept: () {
                                    ref
                                        .read(solutionsNotifierProvider(doubtId).notifier)
                                        .toggleAcceptSolution(sol.id, !sol.isAccepted);
                                  },
                                  onEdit: () {
                                    _showEditSolutionDialog(doubtId, sol);
                                  },
                                  onDelete: () {
                                    ref
                                        .read(solutionsNotifierProvider(doubtId).notifier)
                                        .deleteSolution(sol.id);
                                  },
                                  onCommentTap: () {
                                    CommentSection.show(
                                      context,
                                      doubtId,
                                      sol.id,
                                      "Comments on ${sol.authorDisplayName}'s solution",
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),

              // Sticky Write Solution Compose Box at the bottom
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  border: Border(
                    top: BorderSide(color: cardBorder),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedSolutionImages.isNotEmpty) ...[
                        Container(
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedSolutionImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  RepaintBoundary(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: ResizeImage(
                                            FileImage(selectedSolutionImages[index]),
                                            width: 120,
                                            height: 120,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 14,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedSolutionImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.primary),
                            onPressed: _showSolutionImageSourceBottomSheet,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: _solutionController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                style: GoogleFonts.outfit(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Share a helpful solution...',
                                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isSubmittingSolution ? null : () => _submitSolution(doubtId),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: _isSubmittingSolution
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
