import 'package:flutter/material.dart';
import '../../../../shared/styles/app_text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark
            ? const Color(0xFF251E4E)
            : const Color(0xFFFFF4E6),
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 28,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: AppTextStyles.button(context),
                ),
              ],
            ),
    );
  }
}
