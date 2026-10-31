import 'package:flutter/material.dart';

import '../state/lang.dart';

/// Single row used inside any [MenuAnchor] dropdown that picks a [Lang].
/// Shared by the courses page (speak/learning pickers) and the home page
/// (UI language selector). Disabled rows render dimmed and ignore taps.
class LanguageMenuItem extends StatelessWidget {
  final Lang lang;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  const LanguageMenuItem({
    super.key,
    required this.lang,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = disabled ? Colors.white.withValues(alpha: 0.35) : Colors.white;
    return Material(
      color: selected ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Opacity(
                opacity: disabled ? 0.45 : 1.0,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child:
                      Text(lang.flag, style: const TextStyle(fontSize: 16, height: 1.0)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.native,
                      textDirection:
                          lang.rtl ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: -0.14,
                      ),
                    ),
                    Text(
                      lang.englishName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(
                            alpha: disabled ? 0.30 : 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
