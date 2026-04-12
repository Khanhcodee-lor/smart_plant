import 'dart:convert';

class JsonLineParser {
  JsonLineParser({this.onMalformedLine});

  final void Function(Object error, String line)? onMalformedLine;

  String _buffer = '';

  String get pendingBuffer => _buffer;

  void clear() {
    _buffer = '';
  }

  List<Map<String, dynamic>> append(String chunk) {
    if (chunk.isEmpty) {
      return const [];
    }

    _buffer += chunk;
    final messages = <Map<String, dynamic>>[];

    while (true) {
      final separatorIndex = _buffer.indexOf('\n');
      if (separatorIndex < 0) {
        break;
      }

      final rawLine = _buffer.substring(0, separatorIndex).trim();
      _buffer = _buffer.substring(separatorIndex + 1);

      if (rawLine.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(rawLine);
        if (decoded is Map<String, dynamic>) {
          messages.add(decoded);
          continue;
        }

        if (decoded is Map) {
          messages.add(Map<String, dynamic>.from(decoded));
        }
      } catch (error) {
        onMalformedLine?.call(error, rawLine);
      }
    }

    return messages;
  }
}
