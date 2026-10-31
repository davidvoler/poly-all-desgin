import 'package:flutter/material.dart';

/// Shows the `results` of a prompt reply. A list of records, such as
/// suggested words with their translations, becomes a table with one column
/// per field; any other value becomes a labelled line.
class ChatResults extends StatelessWidget {
  const ChatResults({required this.results, super.key});

  final Map<String, Object?> results;

  /// `words_translations` -> `Words translations`.
  static String label(String key) {
    final words = key.replaceAll('_', ' ').trim();
    return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
  }

  static String _text(Object? value) => switch (value) {
    null => '',
    final List<Object?> list => list.map(_text).join(', '),
    _ => '$value',
  };

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final entry in results.entries) _buildEntry(entry)],
      ),
    );
  }

  Widget _buildEntry(MapEntry<String, Object?> entry) {
    final value = entry.value;
    if (value is List && value.isNotEmpty && value.every((row) => row is Map)) {
      return _ResultsTable(
        title: '${label(entry.key)} (${value.length})',
        rows: [for (final row in value) (row as Map).cast<String, Object?>()],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '${label(entry.key)}: ${_text(value)}',
        style: const TextStyle(color: Color(0xFF17252D), fontSize: 14),
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.title, required this.rows});

  final String title;
  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    // Columns follow the first record, plus any field only later ones have.
    final columns = <String>{for (final row in rows) ...row.keys}.toList();
    const border = BorderSide(color: Color(0xFFE4E0D9));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF9AA4A6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border.color),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              border: const TableBorder(horizontalInside: border),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFBF8F3)),
                  children: [
                    for (final column in columns)
                      _cell(ChatResults.label(column), header: true),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      for (final column in columns)
                        _cell(ChatResults._text(row[column])),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool header = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: SelectableText(
      text,
      style: TextStyle(
        color: header ? const Color(0xFF748087) : const Color(0xFF17252D),
        fontSize: header ? 12 : 14,
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );
}
