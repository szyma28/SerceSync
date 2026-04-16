import 'package:flutter/material.dart';

class ScreenMessageState extends StatelessWidget {
  const ScreenMessageState({
    super.key,
    required this.title,
    required this.message,
    this.imageAssetPath,
    this.imageHeight = 160,
    this.titleStyle,
    this.messageStyle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
  });

  final String title;
  final String message;
  final String? imageAssetPath;
  final double imageHeight;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = this.titleStyle ?? theme.textTheme.headlineSmall;
    final messageStyle = this.messageStyle ?? theme.textTheme.bodyLarge;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAssetPath != null) ...[
              Image.asset(imageAssetPath!, height: imageHeight),
              const SizedBox(height: 24),
            ],
            Text(title, style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: messageStyle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
