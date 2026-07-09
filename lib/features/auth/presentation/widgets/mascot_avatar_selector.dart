import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:focus_fox/core/providers.dart';

class MascotAvatarSelector extends ConsumerStatefulWidget {
  final String selectedAvatarPath;
  final ValueChanged<String> onSelected;

  const MascotAvatarSelector({
    super.key,
    required this.selectedAvatarPath,
    required this.onSelected,
  });

  @override
  ConsumerState<MascotAvatarSelector> createState() => _MascotAvatarSelectorState();
}

class _MascotAvatarSelectorState extends ConsumerState<MascotAvatarSelector> {
  final List<Map<String, String>> _mascots = const [
    {'name': 'Pikachu', 'path': 'assets/images/pikachu.png'},
    {'name': 'Fox', 'path': 'assets/images/lil_fox.png'},
    {'name': 'Panda', 'path': 'assets/images/panda.png'},
    {'name': 'Cat', 'path': 'assets/images/cat.png'},
    {'name': 'Octopus', 'path': 'assets/images/lil_octopus.png'},
    {'name': 'Owl', 'path': 'assets/images/owl.png'},
    {'name': 'Polar Bear', 'path': 'assets/images/polar_bearr.png'},
    {'name': 'Raccoon', 'path': 'assets/images/raccoon.png'},
    {'name': 'Toothless', 'path': 'assets/images/toothless.png'},
    {'name': 'Shark', 'path': 'assets/images/sleepy-shark.png'},
  ];

  bool _isUploading = false;
  String? _customUploadedUrl;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAvatarPath.startsWith('http')) {
      _customUploadedUrl = widget.selectedAvatarPath;
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
    });
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final supabase = ref.read(supabase1ClientProvider);
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      setState(() {
        _customUploadedUrl = publicUrl;
        _isUploading = false;
      });

      widget.onSelected(publicUrl);
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasCustom = _customUploadedUrl != null;
    final totalCount = _mascots.length + (hasCustom ? 1 : 0) + 1; // mascots + optional custom + plus button

    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          // Case 1: Mascot item
          if (index < _mascots.length) {
            final mascot = _mascots[index];
            final path = mascot['path']!;
            final isSelected = widget.selectedAvatarPath == path;
            return _buildAvatarCircle(
              isSelected: isSelected,
              isDark: isDark,
              theme: theme,
              onTap: () => widget.onSelected(path),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }

          // Case 2: Custom uploaded item
          if (hasCustom && index == _mascots.length) {
            final path = _customUploadedUrl!;
            final isSelected = widget.selectedAvatarPath == path;
            return _buildAvatarCircle(
              isSelected: isSelected,
              isDark: isDark,
              theme: theme,
              onTap: () => widget.onSelected(path),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.network(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF818CF8),
                    size: 32,
                  ),
                ),
              ),
            );
          }

          // Case 3: Plus button
          return GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: isDark
                    ? const Color(0xFF1E193C).withOpacity(0.5)
                    : theme.colorScheme.primary.withOpacity(0.04),
                child: _isUploading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.add_a_photo_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarCircle({
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: isDark
              ? const Color(0xFF1E193C)
              : Colors.amber.shade50.withOpacity(0.3),
          child: child,
        ),
      ),
    );
  }
}
