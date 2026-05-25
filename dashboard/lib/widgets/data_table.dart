import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// One column in a [DashTable]. `flex` controls how the row distributes
/// horizontal space; a fixed `width` overrides flex when non-null.
class DashCol {
  final String label;
  final int flex;
  final double? width;
  final TextAlign align;
  const DashCol({
    required this.label,
    this.flex = 1,
    this.width,
    this.align = TextAlign.left,
  });
}

/// Table-shaped list used by Courses, Editors, Students. Header row in
/// small-caps + bordered rows that hover. Cells are full widgets, so
/// callers can drop pills, avatars, or progress bars in directly.
class DashTable extends StatelessWidget {
  final List<DashCol> columns;
  final List<List<Widget>> rows;
  const DashTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(columns: columns),
          for (final r in rows) ...[
            const SizedBox(height: 6),
            _BodyRow(columns: columns, cells: r),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final List<DashCol> columns;
  const _HeaderRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          for (final c in columns) _wrap(c, _HeaderCell(label: c.label)),
        ],
      ),
    );
  }

  Widget _wrap(DashCol c, Widget child) {
    if (c.width != null) {
      return SizedBox(width: c.width!, child: child);
    }
    return Expanded(flex: c.flex, child: child);
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: DashText.sectionLabel(size: 10),
    );
  }
}

class _BodyRow extends StatefulWidget {
  final List<DashCol> columns;
  final List<Widget> cells;
  const _BodyRow({required this.columns, required this.cells});

  @override
  State<_BodyRow> createState() => _BodyRowState();
}

class _BodyRowState extends State<_BodyRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _hover ? DashColors.w(0.06) : DashColors.w(0.04),
          borderRadius: DashRadii.cardSm,
          border: Border.all(color: DashColors.w(0.08)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.columns.length; i++)
              _wrap(widget.columns[i],
                  i < widget.cells.length ? widget.cells[i] : const SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _wrap(DashCol c, Widget child) {
    final cell = DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 13,
        color: Colors.white,
      ),
      child: child,
    );
    if (c.width != null) {
      return SizedBox(width: c.width!, child: cell);
    }
    return Expanded(flex: c.flex, child: cell);
  }
}

/// Round 28×28 action button used in the trailing column of a row.
class RowActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const RowActionButton({super.key, this.icon = Icons.more_horiz, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashColors.w(0.04),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DashColors.w(0.08)),
          ),
          child: Icon(icon, size: 14, color: DashColors.w(0.70)),
        ),
      ),
    );
  }
}

/// "Who" cell — avatar + name + small grey email/subtitle.
class WhoCell extends StatelessWidget {
  final String initials;
  final String avatarKey;
  final String name;
  final String? email;
  final bool youTag;
  const WhoCell({
    super.key,
    required this.initials,
    required this.avatarKey,
    required this.name,
    this.email,
    this.youTag = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LetterAvatar(label: initials, gradientKey: avatarKey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: name),
                    if (youTag)
                      TextSpan(
                        text: ' (you)',
                        style: TextStyle(
                          fontSize: 11,
                          color: DashColors.w(0.55),
                        ),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (email != null && email!.isNotEmpty)
                Text(
                  email!,
                  style: TextStyle(fontSize: 11, color: DashColors.w(0.55)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
