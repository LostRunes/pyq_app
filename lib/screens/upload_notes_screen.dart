import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../core/providers.dart';
import '../models/subject.dart';
import '../services/drive_service.dart';

class UploadNotesScreen extends ConsumerStatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  ConsumerState<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends ConsumerState<UploadNotesScreen> {
  int? _uploadSemester;
  Subject? _uploadSubject;
  bool _isUploadingNotes = false;
  PlatformFile? _selectedFile;
  String? _selectedFilePath;

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
                      value: _uploadSemester,
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
                          value: _uploadSubject,
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
                    if (_selectedFile == null) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_present_rounded),
                        onPressed: _uploadSubject == null ? null : () async {
                          try {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
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

                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                _selectedFile = result.files.single;
                                _selectedFilePath = result.files.single.path;
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
                        label: const Text('Select File'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedFile!.size > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
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
                              ),
                              onPressed: _isUploadingNotes
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedFile = null;
                                        _selectedFilePath = null;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload_rounded),
                        onPressed: _isUploadingNotes ? null : () async {
                          try {
                            final filePath = _selectedFilePath!;
                            final filename = _selectedFile!.name;
                            final fileBytes =
                                await File(filePath).readAsBytes();
                            final mimeType =
                                lookupMimeType(filePath) ??
                                'application/octet-stream';

                            setState(() {
                              _isUploadingNotes = true;
                            });

                            await DriveService().uploadFile(
                              filename: filename,
                              mimeType: mimeType,
                              fileBytes: fileBytes,
                              subjectName: _uploadSubject!.name,
                            );

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
                                          'Notes uploaded to Google Drive! ✨',
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
                                _selectedFile = null;
                                _selectedFilePath = null;
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
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        label: _isUploadingNotes
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
