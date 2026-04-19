import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

enum TregoButtonVariant { primary, secondary, ghost, destructive }
enum TregoButtonSize { md, lg }

class TregoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TregoButtonVariant variant;
  final TregoButtonSize size;
  final bool loading;
  final bool fullWidth;
  final IconData? leadingIcon;

  const TregoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TregoButtonVariant.primary,
    this.size = TregoButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onPressed != null && !loading;
    final height = size == TregoButtonSize.lg ? 52.0 : 44.0;
    final colors = _colors(tokens);
    final opacity = enabled ? 1.0 : 0.5;

    final content = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 16, color: colors.fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: context.typo.button.copyWith(color: colors.fg),
              ),
            ],
          );

    final child = Opacity(
      opacity: opacity,
      child: Material(
        color: colors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          side: colors.border != null
              ? BorderSide(color: colors.border!, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(Radii.button),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    return fullWidth
        ? SizedBox(width: double.infinity, height: height, child: child)
        : SizedBox(height: height, child: child);
  }

  _ButtonColors _colors(TregoTokens t) {
    switch (variant) {
      case TregoButtonVariant.primary:
        return _ButtonColors(bg: t.brand, fg: t.onBrand, border: null);
      case TregoButtonVariant.secondary:
        return _ButtonColors(bg: Colors.transparent, fg: t.brand, border: t.brand);
      case TregoButtonVariant.ghost:
        return _ButtonColors(bg: Colors.transparent, fg: t.ink, border: null);
      case TregoButtonVariant.destructive:
        return _ButtonColors(bg: t.danger, fg: t.onDanger, border: null);
    }
  }
}

class _ButtonColors {
  final Color bg;
  final Color fg;
  final Color? border;
  _ButtonColors({required this.bg, required this.fg, this.border});
}
