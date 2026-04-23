import 'dart:convert';

class JsonLineParser {
  final StringBuffer _buffer = StringBuffer();

  String get pendingBuffer => _buffer.toString();

  void reset() {
    _buffer.clear();
  }

  List<Map<String, dynamic>> append(String chunk) {
    if (chunk.isEmpty) {
      return const [];
    }

    _buffer.write(chunk);
    final text = _buffer.toString();
    final lines = text.split('\n');

    _buffer.clear();
    if (!text.endsWith('\n')) {
      _buffer.write(lines.removeLast());
    }

    final results = <Map<String, dynamic>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) {
        throw FormatException('Không phải JSON object: $trimmed');
      }
      results.add(Map<String, dynamic>.from(decoded));
    }
    return results;
  }
}
