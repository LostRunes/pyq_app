import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers.dart';
import '../providers/skulk_providers.dart';
import '../../data/services/cloudinary_service.dart';

class CreateDoubtScreen extends ConsumerStatefulWidget {
  const CreateDoubtScreen({super.key});

  @override
  ConsumerState<CreateDoubtScreen> createState() => _CreateDoubtScreenState();
}

class _CreateDoubtScreenState extends ConsumerState<CreateDoubtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<File> selectedImages = [];

  String? _selectedSubjectId;
  bool _isPublishing = false;

  // Route args — extracted once in didChangeDependencies to avoid
  // re-reading on every rebuild.
  String? _branchId;
  int? _semester;
  bool _argsParsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsParsed) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _branchId = args['branchId'] as String;
      _semester = args['semester'] as int;
      _argsParsed = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Colors.grey[500],
          ),
        ),
      );

  // ── publish ────────────────────────────────────────────────────────────────

  Future<void> pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) return;
      setState(() {
        selectedImages.addAll(images.map((e) => File(e.path)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _publishDoubt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final rawTags = _tagsController.text.trim();
    final parsedTags = rawTags.isEmpty
        ? <String>[]
        : rawTags
            .split(RegExp(r'[,\s]+'))
            .map((e) => e.replaceAll('#', '').trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList();

    List<String> uploadedUrls = [];
    bool hasFailedUploads = false;

    try {
      // Step 7 — Upload Before Publishing
      for (final image in selectedImages) {
        final url = await CloudinaryService.uploadImage(image);
        if (url != null) {
          uploadedUrls.add(url);
        } else {
          hasFailedUploads = true;
        }
      }

      await ref.read(skulkRepositoryProvider).createDoubt(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            subjectId: _selectedSubjectId!,
            tags: parsedTags,
            imageUrls: uploadedUrls,
          );

      ref.invalidate(skulkFeedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: hasFailedUploads ? Colors.orange[800] : Colors.green[700],
            content: Text(
              hasFailedUploads
                  ? 'Post published without some images ⚠️'
                  : 'Doubt posted! ✨',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to publish: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_argsParsed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectsAsync = ref.watch(subjectsProvider((
      branchId: _branchId!,
      semester: _semester!,
    )));

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Ask the Community',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load subjects.\n$err',
                textAlign: TextAlign.center),
          ),
        ),
        data: (subjects) {
          // ── pre-select once, never inside build recursively ──
          if (_selectedSubjectId == null && subjects.isNotEmpty) {
            // Use post-frame callback so we don't trigger setState mid-build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedSubjectId == null) {
                setState(() => _selectedSubjectId = subjects.first.id);
              }
            });
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                children: [
                  // ── Subject ──────────────────────────────────────────────
                  _sectionLabel('WHICH SUBJECT?'),
                  Container(
                    decoration: _cardDecoration(context),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedSubjectId),
                        initialValue: _selectedSubjectId,
                        isExpanded: true,
                        dropdownColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _fieldDecoration('').copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                        ),
                        items: subjects.map((sub) {
                          return DropdownMenuItem<String>(
                            value: sub.id,
                            child: Text(
                              '${sub.name} (${sub.code})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSubjectId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ────────────────────────────────────────────────
                  _sectionLabel('TITLE'),
                  Container(
                    decoration: _cardDecoration(context),
                    child: TextFormField(
                      controller: _titleController,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.outfit(fontSize: 15),
                      decoration: _fieldDecoration('What is your doubt about?'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a title.';
                        }
                        if (v.trim().length < 5) {
                          return 'Title is too short (min 5 chars).';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────────────────────
                  _sectionLabel('DESCRIPTION'),
                  Container(
                    decoration: _cardDecoration(context),
                    child: TextFormField(
                      controller: _bodyController,
                      minLines: 5,
                      maxLines: 12,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: GoogleFonts.outfit(fontSize: 14, height: 1.5),
                      decoration:
                          _fieldDecoration('Explain your doubt in detail…'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please add a description.';
                        }
                        if (v.trim().length < 10) {
                          return 'Add a bit more explanation (min 10 chars).';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Images ───────────────────────────────────────────────
                  _sectionLabel('IMAGES  (OPTIONAL)'),
                  if (selectedImages.isNotEmpty) ...[
                    Container(
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
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
                  OutlinedButton.icon(
                    onPressed: pickImages,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Add Images'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Tags ─────────────────────────────────────────────────
                  _sectionLabel('TAGS  (OPTIONAL)'),
                  Container(
                    decoration: _cardDecoration(context),
                    child: TextFormField(
                      controller: _tagsController,
                      maxLines: 1,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration:
                          _fieldDecoration('exam sem2 math assignment …'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Separate tags with spaces or commas — no # needed.',
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 32),

                  // ── Publish button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isPublishing ? null : _publishDoubt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isPublishing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Publish Doubt',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
