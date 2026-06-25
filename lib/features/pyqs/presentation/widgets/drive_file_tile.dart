import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriveFileTile extends StatelessWidget {
  final Map item;
  final VoidCallback onTap;

  const DriveFileTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFolder = item["mimeType"] == "application/vnd.google-apps.folder";
    final mimeType = item["mimeType"] as String? ?? '';
    final thumbnail = item["thumbnailLink"] as String?;
    final name = item["name"] ?? "Unnamed Item";

    IconData leadingIcon = Icons.description_rounded;
    Color iconColor = Colors.blue;

    if (isFolder) {
      leadingIcon = Icons.folder_rounded;
      iconColor = Colors.amber;
    } else if (mimeType.contains("pdf")) {
      leadingIcon = Icons.picture_as_pdf_rounded;
      iconColor = Colors.redAccent;
    } else if (mimeType.startsWith("image/")) {
      leadingIcon = Icons.image_rounded;
      iconColor = Colors.teal;
    } else if (mimeType.contains("word") || mimeType.contains("document")) {
      leadingIcon = Icons.article_rounded;
      iconColor = Colors.blue;
    } else if (mimeType.contains("spreadsheet") ||
        mimeType.contains("excel") ||
        mimeType.contains("sheet")) {
      leadingIcon = Icons.table_chart_rounded;
      iconColor = Colors.green;
    } else if (mimeType.contains("presentation") ||
        mimeType.contains("powerpoint")) {
      leadingIcon = Icons.slideshow_rounded;
      iconColor = Colors.orange;
    }

    Widget leadingWidget;
    if (thumbnail != null && !isFolder) {
      leadingWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          thumbnail,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(leadingIcon, iconColor),
        ),
      );
    } else {
      leadingWidget = _buildFallbackIcon(leadingIcon, iconColor);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        leading: leadingWidget,
        title: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFallbackIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
