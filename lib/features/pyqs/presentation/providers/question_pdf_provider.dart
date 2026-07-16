import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers.dart';
import '../../../../utils/drive_utils.dart';
import '../providers/pyq_providers.dart';
import '../../data/models/subject.dart';
import '../../data/models/pyq_source.dart';

class QuestionPdfMatchResult {
  final Subject subject;
  final List<dynamic> matchedFiles;
  final List<dynamic> allFiles;

  QuestionPdfMatchResult({
    required this.subject,
    required this.matchedFiles,
    required this.allFiles,
  });
}

final questionPdfMatchProvider = FutureProvider.family<QuestionPdfMatchResult?, String>((ref, questionId) async {
  final supabase = ref.read(supabase1ClientProvider);
  final driveService = ref.read(driveServiceProvider);

  // 1. Find the subject for the question
  final questionTopicRes = await supabase
      .from('question_topics')
      .select('topics(subject_id)')
      .eq('question_id', questionId)
      .maybeSingle();

  if (questionTopicRes == null) return null;
  final topicsMap = questionTopicRes['topics'] as Map?;
  if (topicsMap == null) return null;
  final subjectId = topicsMap['subject_id'] as String?;
  if (subjectId == null) return null;

  // 2. Fetch the subject detail to get the drive link
  final subjectRes = await supabase
      .from('subjects')
      .select()
      .eq('id', subjectId)
      .single();
  
  final subject = Subject.fromJson(subjectRes);
  final pyqLink = subject.pyqDriveLink;
  if (pyqLink == null || pyqLink.isEmpty) {
    return QuestionPdfMatchResult(subject: subject, matchedFiles: [], allFiles: []);
  }

  String rootFolderId;
  try {
    rootFolderId = extractFolderId(pyqLink);
  } catch (_) {
    return QuestionPdfMatchResult(subject: subject, matchedFiles: [], allFiles: []);
  }

  // 3. Fetch question's PYQ source tags to help with matching
  final pyqSources = await ref.read(pyqSourcesProvider(questionId).future);
  if (pyqSources.isEmpty) {
    // If no tags, just fetch root folder contents
    final rootFiles = await ref.read(driveFolderContentsProvider(rootFolderId).future);
    return QuestionPdfMatchResult(subject: subject, matchedFiles: [], allFiles: rootFiles);
  }

  // Use the first source for matching target
  final targetSource = pyqSources.first;
  final targetExamType = targetSource.examType.toLowerCase(); // e.g. "midsem", "endsem"
  final targetYear = targetSource.year.toLowerCase();         // e.g. "2023", "2024"
  final targetSeason = targetSource.season.toLowerCase();     // e.g. "autumn", "spring"

  // 4. Fetch the root folder contents to see if there are "mid" or "end" folders
  final rootFiles = await ref.read(driveFolderContentsProvider(rootFolderId).future);
  
  String targetFolderId = rootFolderId;
  List<dynamic> targetFiles = rootFiles;

  // Check if we should traverse to "mid" or "end" subfolders
  final isMid = targetExamType.contains('mid');
  final isEnd = targetExamType.contains('end');

  if (isMid || isEnd) {
    final subfolderName = isMid ? 'mid' : 'end';
    final subfolder = rootFiles.firstWhere(
      (f) => f['mimeType'] == 'application/vnd.google-apps.folder' && 
             (f['name'] as String).toLowerCase().contains(subfolderName),
      orElse: () => null,
    );

    if (subfolder != null) {
      targetFolderId = subfolder['id'] as String;
      targetFiles = await ref.read(driveFolderContentsProvider(targetFolderId).future);
    }
  }

  // 5. Match files based on tags
  final matchedFiles = <dynamic>[];
  final otherFiles = <dynamic>[];

  for (final file in targetFiles) {
    if (file['mimeType'] == 'application/vnd.google-apps.folder') {
      otherFiles.add(file);
      continue;
    }
    
    final fileName = (file['name'] as String? ?? '').toLowerCase();
    
    // Check match criteria
    bool yearMatch = targetYear.isNotEmpty && fileName.contains(targetYear);
    bool seasonMatch = targetSeason.isNotEmpty && fileName.contains(targetSeason);
    
    // An exam type match: e.g., if we are already in the "mid" folder, exam type is semi-matched.
    // If not in a subfolder, check if filename matches "mid" or "end".
    bool examMatch = true;
    if (targetFolderId == rootFolderId) {
      if (isMid && !fileName.contains('mid')) examMatch = false;
      if (isEnd && !fileName.contains('end')) examMatch = false;
    }

    if (yearMatch && (seasonMatch || examMatch)) {
      matchedFiles.add(file);
    } else {
      otherFiles.add(file);
    }
  }

  // Sort matched files by name
  matchedFiles.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  return QuestionPdfMatchResult(
    subject: subject,
    matchedFiles: matchedFiles,
    allFiles: [...matchedFiles, ...otherFiles],
  );
});
