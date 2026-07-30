import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:focus_fox/core/providers/prefs_provider.dart';
import 'package:focus_fox/features/subjects/presentation/providers/subjects_providers.dart';
import 'package:focus_fox/features/pyqs/data/models/subject.dart';
import 'package:focus_fox/core/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_history_screen.dart';


class UploadNotesScreen extends ConsumerStatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  ConsumerState<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends ConsumerState<UploadNotesScreen> {
  int? _uploadSemester;
  Subject? _uploadSubject;
  bool _isUploadingNotes = false;
  List<PlatformFile> _selectedFiles = [];
  String _uploadProgressText = '';

  @override
  void initState() {
    super.initState();
    // Initialize semester from active provider
    Future.microtask(() {
      final activeSem = ref.read(selectedSemesterProvider);
      setState(() {
        _uploadSemester = activeSem;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBranchId = ref.watch(selectedBranchIdProvider);

    final AsyncValue<List<Subject>> subjectsAsync = _uploadSemester == null
        ? ref.watch(allSubjectsProvider)
        : ref.watch(
            subjectsProvider((
              branchId: activeBranchId,
              semester: _uploadSemester!,
            )),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Notes',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Upload History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/darktheme_bg.png'),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Upload Study Notes 📚',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Help your classmates! Upload your files directly to the shared subject folder on Google Drive.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int?>(
                      initialValue: _uploadSemester,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'All Semesters',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        ...List.generate(8, (i) => i + 1).map(
                          (sem) => DropdownMenuItem<int?>(
                            value: sem,
                            child: Text(
                              'S$sem',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (sem) {
                        setState(() {
                          _uploadSemester = sem;
                          _uploadSubject = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    subjectsAsync.when(
                      data: (subs) {
                        final otherSubject = Subject(
                          id: 'other',
                          name: 'Other (Non-academic)',
                          code: 'OTHER',
                        );

                        if (_uploadSubject != null &&
                            _uploadSubject!.id != 'other' &&
                            !subs.any((s) => s.id == _uploadSubject!.id)) {
                          _uploadSubject = null;
                        }
                        return DropdownButtonFormField<Subject>(
                          initialValue: _uploadSubject,
                          isExpanded: true,
                          hint: Text(
                            'Select Subject',
                            style: GoogleFonts.outfit(fontSize: 14),
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          items: [
                            DropdownMenuItem<Subject>(
                              value: otherSubject,
                              child: Text(
                                'Other (Non-academic)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...subs.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (sub) {
                            setState(() {
                              _uploadSubject = sub;
                            });
                          },
                        );
                      },
                      loading: () => Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => DropdownButtonFormField<Subject>(
                        isExpanded: true,
                        items: const [],
                        onChanged: null,
                        decoration: const InputDecoration(
                          labelText: 'Error loading subjects',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_selectedFiles.isEmpty) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_present_rounded),
                        onPressed: _uploadSubject == null ? null : () async {
                          try {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowMultiple: true,
                              allowedExtensions: [
                                'pdf',
                                'doc',
                                'docx',
                                'xls',
                                'xlsx',
                                'png',
                                'jpg',
                                'jpeg',
                              ],
                            );

                            if (result != null) {
                              setState(() {
                                _selectedFiles = result.files
                                    .where((f) => f.path != null)
                                    .toList();
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('File selection failed: $e 😢'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        label: const Text('Select Files'),
                      ),
                    ] else ...[
                      Column(
                        children: _selectedFiles.map((file) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.15,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (file.size > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${(file.size / 1024).toStringAsFixed(1)} KB',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: _isUploadingNotes
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedFiles.remove(file);
                                          });
                                        },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'Add More Files',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isUploadingNotes
                            ? null
                            : () async {
                                try {
                                  final result = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowMultiple: true,
                                    allowedExtensions: [
                                      'pdf',
                                      'doc',
                                      'docx',
                                      'xls',
                                      'xlsx',
                                      'png',
                                      'jpg',
                                      'jpeg',
                                    ],
                                  );
                                  if (result != null) {
                                    setState(() {
                                      final newFiles = result.files
                                          .where((f) =>
                                              f.path != null &&
                                              !_selectedFiles.any((existing) =>
                                                  existing.path == f.path))
                                          .toList();
                                      _selectedFiles.addAll(newFiles);
                                    });
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'File selection failed: $e 😢',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload_rounded),
                        onPressed: _isUploadingNotes ? null : () async {
                          try {
                            setState(() {
                              _isUploadingNotes = true;
                            });

                            final total = _selectedFiles.length;
                            for (int i = 0; i < total; i++) {
                              final file = _selectedFiles[i];
                              final filePath = file.path!;

                              setState(() {
                                _uploadProgressText =
                                    'Uploading ${i + 1} of $total:\n${file.name}';
                              });

                              final fileBytes =
                                  await File(filePath).readAsBytes();
                              final mimeType =
                                  lookupMimeType(filePath) ??
                                  'application/octet-stream';

                              final fileId = await ref.read(driveServiceProvider).uploadFile(
                                filename: file.name,
                                mimeType: mimeType,
                                fileBytes: fileBytes,
                                subjectName: _uploadSubject!.name,
                              );

                              if (fileId != null) {
                                await Supabase.instance.client.from('uploaded_notes').insert({
                                  'drive_file_id': fileId,
                                  'filename': file.name,
                                  'subject_name': _uploadSubject!.name,
                                  'semester': _uploadSemester,
                                });
                              }
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'All files uploaded to Google Drive! ✨',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                              setState(() {
                                _selectedFiles.clear();
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Upload failed: $e 😢'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isUploadingNotes = false;
                                _uploadProgressText = '';
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: _isUploadingNotes
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _uploadProgressText,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Upload Notes'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
