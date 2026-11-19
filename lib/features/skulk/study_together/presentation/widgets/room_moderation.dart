import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../presentation/providers/block_providers.dart';
import '../../data/models/study_room.dart';

/// True when the signed-in user created this custom (personal) room and can
/// therefore remove members from it.
bool isRoomHost(StudyRoom? room) {
  final me = Supabase.instance.client.auth.currentUser?.id;
  return room != null &&
      me != null &&
      room.type == 'personal' &&
      room.createdBy == me;
}

String _nameOrFallback(String name) =>
    name.trim().isEmpty ? 'this user' : name.trim();

/// Host only: asks for confirmation, then removes [userId] from [room]
/// (they are dropped from voice and can no longer chat or rejoin).
Future<bool> confirmAndRemoveFromRoom(
  BuildContext context, {
  required StudyRoom room,
  required String userId,
  required String displayName,
}) async {
  final name = _nameOrFallback(displayName);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Remove $name?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Text(
        '$name will be removed from "${room.name}" and won\'t be able to '
        'send messages or join the voice call again.',
        style: GoogleFonts.outfit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: GoogleFonts.outfit()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Remove',
            style: GoogleFonts.outfit(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await Supabase.instance.client.functions.invoke(
      'room-kick',
      body: {'room_id': room.id, 'user_id': userId},
    );
    messenger?.showSnackBar(
      SnackBar(content: Text('$name was removed from the room')),
    );
    return true;
  } catch (e) {
    final msg = e is FunctionException
        ? (e.details is Map ? (e.details as Map)['error'] : null)
        : null;
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not remove $name: ${msg ?? e}')),
    );
    return false;
  }
}

const _reportReasons = [
  'Harassment or bullying',
  'Hate speech',
  'Sexual or inappropriate content',
  'Spam or scam',
  'Disrupting the room',
  'Impersonation',
  'Other',
];

/// Lets any member report [userId]. Stored in `user_reports` for moderators.
Future<void> showReportUserSheet(
  BuildContext context, {
  required String userId,
  required String displayName,
  String? roomId,
}) async {
  final name = _nameOrFallback(displayName);
  final details = TextEditingController();
  String? reason;
  final messenger = ScaffoldMessenger.maybeOf(context);

  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report $name',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reports are reviewed by the Focus Fox team. $name won\'t '
                'know who reported them.',
                style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => setLocal(() => reason = v),
                child: Column(
                  children: [
                    for (final r in _reportReasons)
                      RadioListTile<String>(
                        value: r,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(r, style: GoogleFonts.outfit(fontSize: 14)),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: details,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                style: GoogleFonts.outfit(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Add details (optional)',
                  hintStyle: GoogleFonts.outfit(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: reason == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: Text(
                    'Submit report',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (submitted != true || reason == null) return;
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;
  if (me == null) return;
  try {
    await client.from('user_reports').insert({
      'reporter_id': me,
      'reported_user_id': userId,
      'room_id': roomId,
      'reason': reason,
      'details': details.text.trim().isEmpty ? null : details.text.trim(),
    });
    messenger?.showSnackBar(
      const SnackBar(content: Text('Thanks. Your report has been sent.')),
    );
  } on PostgrestException catch (e) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          e.code == '23505'
              ? 'You have already reported $name in this room.'
              : 'Could not send report: ${e.message}',
        ),
      ),
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not send report: $e')),
    );
  }
}

/// Action sheet for another member of a room: report, block and, for the
/// host of a custom room, remove from room.
Future<void> showRoomMemberActions(
  BuildContext context,
  WidgetRef ref, {
  required StudyRoom room,
  required String userId,
  required String displayName,
}) async {
  final me = Supabase.instance.client.auth.currentUser?.id;
  if (me == null || userId == me) return;
  final name = _nameOrFallback(displayName);
  final host = isRoomHost(room);

  final action = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (host)
            ListTile(
              leading: const Icon(
                Icons.person_remove_alt_1_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                'Remove from room',
                style: GoogleFonts.outfit(color: Colors.redAccent),
              ),
              onTap: () => Navigator.pop(ctx, 'kick'),
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            title: Text(
              'Report user',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
            onTap: () => Navigator.pop(ctx, 'report'),
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
            title: Text(
              'Block user',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
            onTap: () => Navigator.pop(ctx, 'block'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted) return;

  switch (action) {
    case 'kick':
      await confirmAndRemoveFromRoom(
        context,
        room: room,
        userId: userId,
        displayName: name,
      );
    case 'report':
      await showReportUserSheet(
        context,
        userId: userId,
        displayName: name,
        roomId: room.id,
      );
    case 'block':
      await confirmAndBlockUser(
        context,
        ref,
        userId: userId,
        displayName: name,
      );
  }
}
