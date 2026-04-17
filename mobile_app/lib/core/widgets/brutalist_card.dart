import 'package:flutter/material.dart';
import '../theme/brutalist_theme.dart';

class BrutalistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const BrutalistCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The offset shadow logic (no blur, hard black offset)
    Widget cardContent = Container(
      decoration: const BoxDecoration(
        color: BrutalistTheme.surface,
        border: Border.fromBorderSide(
          BorderSide(color: BrutalistTheme.primary, width: BrutalistTheme.borderWidth),
        ),
        boxShadow: [
          BoxShadow(
            color: BrutalistTheme.primary,
            offset: Offset(6, 6),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    // If it has a shadow offset of 6, we need to pad the bottom/right 
    // so it doesn't clip in lists
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, right: 6.0),
      child: cardContent,
    );
  }
}
