import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/study_room.dart';
import '../../data/models/room_message.dart';
import '../../../utils/image_utils.dart';
import '../../../data/services/cloudinary_service.dart';
import '../providers/study_together_providers.dart';
import '../widgets/room_message_bubble.dart';
import '../widgets/voice_panel.dart';
import '../../../../../app/app.dart' show appRouteObserver;

class StudyRoomChatScreen extends ConsumerStatefulWidget {
  final StudyRoom room;

  const StudyRoomChatScreen({super.key, required this.room});

  @override
  ConsumerState<StudyRoomChatScreen> createState() =>
      _StudyRoomChatScreenState();
}

class _StudyRoomChatScreenState extends ConsumerState<StudyRoomChatScreen>
    with RouteAware {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  Timer? _typingTimer;
  bool _isCurrentlyTyping = false;
  RoomMessage? _replyingTo;
  RoomMessage? _editingMessage;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final Map<String, GlobalKey> _messageKeys = {};

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String? _tagQuery;

  void _showImageSourceBottomSheet() {
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
                  'Share Photo in Chat',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1800,
                        maxHeight: 1800,
                        imageQuality: 85,
                      );
                      if (image == null) return;
                      final compressed = await ImageUtils.compressImage(File(image.path));
                      if (compressed == null) return;
                      setState(() {
                        _selectedImages.add(compressed);
                      });
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to take photo: $e')),
                      );
                    }
                  },
                ),
                Divider(color: isDark ? Colors.grey[850] : Colors.grey[200]),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final images = await _picker.pickMultiImage(
                        maxWidth: 1800,
                        maxHeight: 1800,
                        imageQuality: 85,
                      );
                      if (images.isEmpty) return;
                      final compressedList = await Future.wait(
                        images.map((img) => ImageUtils.compressImage(File(img.path))),
                      );
                      final valid = compressedList.whereType<File>().toList();
                      setState(() {
                        _selectedImages.addAll(valid);
                      });
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to pick images: $e')),
                      );
                    }
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
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onCursorChanged);
    _fetchUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route events so we know exactly when this screen
    // is visible vs covered by another route
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  void _setScreenActive(bool active) {
    // Defer the provider write until after the current frame is built.
    // RouteAware callbacks can fire mid-build, which causes a
    // "provider modified during build" exception if we write synchronously.
    Future.microtask(() {
      if (mounted) {
        ref.read(voiceRoomScreenActiveProvider.notifier).setVal(active);
      }
    });
  }

  // Called when this route is pushed on top (screen becomes visible)
  @override
  void didPush() => _setScreenActive(true);

  // Called when the route on top of this one is popped (screen comes back into view)
  @override
  void didPopNext() => _setScreenActive(true);

  // Called when a new route is pushed on top of this screen (user navigates away)
  @override
  void didPushNext() => _setScreenActive(false);

  // Called when this route is popped (user goes back)
  @override
  void didPop() => _setScreenActive(false);

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _typingTimer?.cancel();
    _messageController.removeListener(_onCursorChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        ref.read(roomTypingProvider(widget.room.id).notifier).sendTyping(false);
      }
      _typingTimer?.cancel();
      return;
    }

    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      ref.read(roomTypingProvider(widget.room.id).notifier).sendTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isCurrentlyTyping) {
        _isCurrentlyTyping = false;
        ref.read(roomTypingProvider(widget.room.id).notifier).sendTyping(false);
      }
    });
  }

  void _onScroll() {
    final messages = ref.read(roomChatProvider(widget.room.id));
    final chatNotifier = ref.read(roomChatProvider(widget.room.id).notifier);

    // In reversed list, older messages are loaded when scrolled near top
    if (messages.length >= 12 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      chatNotifier.loadMore();
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('id, username, display_name, avatar_url');
      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profiles: $e');
    }
  }

  void _onCursorChanged() {
    final text = _messageController.text;
    final selectionStart = _messageController.selection.start;
    final query = _getTypingTagQuery(text, selectionStart);
    
    if (query != null) {
      final lowercaseQuery = query.toLowerCase();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final filtered = _allUsers.where((user) {
        if (user['id'] == currentUserId) return false;
        final username = (user['username'] ?? '').toString().toLowerCase();
        final displayName = (user['display_name'] ?? '').toString().toLowerCase();
        return username.contains(lowercaseQuery) || displayName.contains(lowercaseQuery);
      }).toList();

      setState(() {
        _tagQuery = query;
        _filteredUsers = filtered;
      });
    } else {
      if (_tagQuery != null) {
        setState(() {
          _tagQuery = null;
          _filteredUsers = [];
        });
      }
    }
  }

  String? _getTypingTagQuery(String text, int selectionStart) {
    if (selectionStart < 0 || selectionStart > text.length) return null;
    final textBeforeCursor = text.substring(0, selectionStart);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) return null;

    if (lastAtIndex > 0) {
      final charBeforeAt = textBeforeCursor[lastAtIndex - 1];
      if (charBeforeAt != ' ' && charBeforeAt != '\n') {
        return null;
      }
    }

    final query = textBeforeCursor.substring(lastAtIndex + 1);
    if (query.contains(' ')) {
      return null;
    }
    return query;
  }

  void _selectUserTag(String username) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    if (selection.start < 0) return;

    final textBeforeCursor = text.substring(0, selection.start);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');
    if (lastAtIndex == -1) return;

    final prefix = text.substring(0, lastAtIndex);
    final suffix = text.substring(selection.end);

    final insertText = '@$username ';
    final newText = '$prefix$insertText$suffix';

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lastAtIndex + insertText.length),
    );

    setState(() {
      _tagQuery = null;
      _filteredUsers = [];
    });
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/images/pikachu.png');
    }
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return NetworkImage(avatarUrl);
    }
    return AssetImage(avatarUrl);
  }

  void _scrollToMessage(String msgId) {
    final messages = ref.read(roomChatProvider(widget.room.id));
    
    // Debug logging
    debugPrint("SCROLL TO: '$msgId'");
    debugPrint("TOTAL MESSAGES IN PROVIDER: ${messages.length}");
    for (int idx = 0; idx < messages.length; idx++) {
      debugPrint("  [$idx] ID: '${messages[idx].id}' | TEXT: '${messages[idx].message}'");
    }

    final cleanMsgId = msgId.trim();

    // Determine the index of the message in the list
    int index = -1;
    if (messages.length < 12) {
      final oldestFirst = messages.reversed.toList();
      index = oldestFirst.indexWhere((m) => m.id.trim() == cleanMsgId);
    } else {
      index = messages.indexWhere((m) => m.id.trim() == cleanMsgId);
    }

    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message is not loaded in current history')),
      );
      return;
    }

    final key = _messageKeys[cleanMsgId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
        curve: Curves.easeInOut,
      );
    } else {
      // Fallback: estimate scroll offset based on index and average item height (80.0 px)
      const double averageItemHeight = 80.0;
      final double targetOffset = index * averageItemHeight;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImages.isEmpty) || _isSending) return;

    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message too long (max 2000 characters).'),
        ),
      );
      return;
    }

    final editingMsg = _editingMessage;
    if (editingMsg != null) {
      setState(() => _isSending = true);
      _messageController.clear();
      setState(() => _editingMessage = null);
      try {
        await ref
            .read(roomChatProvider(widget.room.id).notifier)
            .editMessage(editingMsg.id, text);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit message: $e')),
          );
        }
      } finally {
        setState(() => _isSending = false);
      }
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();
    final repliedMsg = _replyingTo;
    setState(() => _replyingTo = null);
    
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      ref.read(roomTypingProvider(widget.room.id).notifier).sendTyping(false);
    }
    _typingTimer?.cancel();

    final imagesToUpload = List<File>.from(_selectedImages);
    setState(() => _selectedImages.clear());

    try {
      String imagePrefix = '';
      if (imagesToUpload.isNotEmpty) {
        final urls = await Future.wait(
          imagesToUpload.map((img) => CloudinaryService.uploadImage(img)),
        );
        final validUrls = urls.whereType<String>().toList();
        for (final url in validUrls) {
          imagePrefix += '[image:$url]';
        }
      }

      // Clean up replied message text to strip images/URLs
      String cleanedReplyText = '';
      if (repliedMsg != null) {
        cleanedReplyText = repliedMsg.message
            .replaceAll(RegExp(r'\[image:[^\]]*\]'), '[Image]')
            .replaceAll(RegExp(r'https?://[^\s]+'), '[Link]')
            .replaceAll('[', '').replaceAll(']', '')
            .trim();
        if (cleanedReplyText.isEmpty) {
          cleanedReplyText = '[Image]';
        }
      }

      final replyPrefix = repliedMsg != null
          ? '[reply:${repliedMsg.id}:${repliedMsg.senderDisplayName ?? repliedMsg.senderUsername ?? "User"}:$cleanedReplyText]'
          : '';
      final fullText = '$replyPrefix$imagePrefix$text';

      await ref
          .read(roomChatProvider(widget.room.id).notifier)
          .sendMessage(fullText);

      // Auto scroll to bottom when sending if in top-down layout
      final messages = ref.read(roomChatProvider(widget.room.id));
      if (messages.length < 12) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(roomChatProvider(widget.room.id));
    final presenceCount = ref.watch(roomPresenceProvider(widget.room.id));
    final chatNotifier = ref.read(roomChatProvider(widget.room.id).notifier);
    final typingUsers = ref.watch(roomTypingProvider(widget.room.id));

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F) // Solid Instagram-style dark mode background
          : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
            height: 1.0,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Row(
          children: [
            Icon(
              widget.room.isVoiceEnabled ? Icons.volume_up_rounded : Icons.chat_bubble_outline_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$presenceCount studying now',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.room.isVoiceEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: VoicePanel(room: widget.room),
              ),
            ],
            // Message List Area
            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset = (_dragOffset + details.delta.dx).clamp(-70.0, 0.0);
                    _isDragging = true;
                  });
                },
                onHorizontalDragEnd: (details) {
                  setState(() {
                    _isDragging = false;
                  });
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: _dragOffset, end: _isDragging ? _dragOffset : 0.0),
                  duration: const Duration(milliseconds: 150),
                  builder: (context, offset, child) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.room.icon,
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet.',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Start the late-night academic chaos ☕',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                     if (messages.length < 12) {
                      final oldestFirst = messages.reversed.toList();
                      return RefreshIndicator(
                        onRefresh: () => ref.read(roomChatProvider(widget.room.id).notifier).refresh(),
                        color: Theme.of(context).colorScheme.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          reverse: false,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = oldestFirst[index];
                            final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                            return RoomMessageBubble(
                              key: key,
                              message: msg,
                              dragOffset: offset,
                              onReply: () {
                                setState(() {
                                  _replyingTo = msg;
                                  _editingMessage = null;
                                });
                              },
                              onRepliedMessageTap: _scrollToMessage,
                              onEdit: () {
                                setState(() {
                                  _editingMessage = msg;
                                  _replyingTo = null;
                                  _messageController.text = msg.message
                                      .replaceAll(RegExp(r'^\[reply:[^\]]*\]'), '')
                                      .replaceAll(RegExp(r'\[image:[^\]]*\]'), '')
                                      .trim();
                                });
                              },
                              onDelete: () {
                                ref.read(roomChatProvider(widget.room.id).notifier).deleteMessage(msg.id);
                              },
                              onReact: (emoji) {
                                ref.read(roomChatProvider(widget.room.id).notifier).toggleReaction(msg.id, emoji);
                              },
                            );
                          },
                        ),
                      );
                    }

                     return RefreshIndicator(
                      onRefresh: () => ref.read(roomChatProvider(widget.room.id).notifier).refresh(),
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        reverse: true,
                        itemCount:
                            messages.length +
                            (chatNotifier.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final msg = messages[index];
                          final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                          return RoomMessageBubble(
                            key: key,
                            message: msg,
                            dragOffset: offset,
                            onReply: () {
                              setState(() {
                                _replyingTo = msg;
                                _editingMessage = null;
                              });
                            },
                            onRepliedMessageTap: _scrollToMessage,
                            onEdit: () {
                              setState(() {
                                _editingMessage = msg;
                                _replyingTo = null;
                                _messageController.text = msg.message
                                    .replaceAll(RegExp(r'^\[reply:[^\]]*\]'), '')
                                    .replaceAll(RegExp(r'\[image:[^\]]*\]'), '')
                                    .trim();
                              });
                            },
                            onDelete: () {
                              ref.read(roomChatProvider(widget.room.id).notifier).deleteMessage(msg.id);
                            },
                            onReact: (emoji) {
                              ref.read(roomChatProvider(widget.room.id).notifier).toggleReaction(msg.id, emoji);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Real-time typing indicator bubble
            if (typingUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.grey),
                        ),
                      ),
                      Text(
                        typingUsers.length == 1
                            ? '${typingUsers.first} is typing...'
                            : '${typingUsers.join(', ')} are typing...',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Instagram-style Reply Preview Box
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161616) : const Color(0xFFF8F9FA),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${_replyingTo!.senderDisplayName ?? _replyingTo!.senderUsername ?? "User"}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _replyingTo!.message.startsWith('[reply:')
                                ? _replyingTo!.message.substring(_replyingTo!.message.indexOf(']') + 1)
                                : _replyingTo!.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _replyingTo = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Edit Preview Box
            if (_editingMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161616) : const Color(0xFFF8F9FA),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Editing message',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _editingMessage!.message
                                .replaceAll(RegExp(r'^\[reply:[^\]]*\]'), '')
                                .replaceAll(RegExp(r'\[image:[^\]]*\]'), '')
                                .trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _editingMessage = null;
                          _messageController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Image Preview above the composer
            if (_selectedImages.isNotEmpty)
              Container(
                height: 80,
                color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 14,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
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
                                size: 12,
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

            // Tag autocomplete suggestions overlay
            if (_tagQuery != null && _filteredUsers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final username = user['username'] ?? '';
                      final displayName = user['display_name'] ?? 'User';
                      final avatarUrl = user['avatar_url'] as String?;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark
                              ? const Color(0xFF383838)
                              : const Color(0xFFE2E6EA),
                          backgroundImage: _getAvatarProvider(avatarUrl),
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '@$username',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () => _selectUserTag(username),
                      );
                    },
                  ),
                ),
              ),

            // Input composer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceBottomSheet,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        style: GoogleFonts.outfit(fontSize: 14),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
