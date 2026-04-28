String formatAssistantMessageForDisplay(String text) {
  var normalized = text.replaceAll('\r\n', '\n').trim();

  normalized = normalized.replaceAllMapped(
    RegExp(r'^\s{0,3}#{1,6}\s*(.+)$', multiLine: true),
    (match) => match.group(1)?.trim() ?? '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'^\s*[-*]\s+', multiLine: true),
    (_) => '• ',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'^\s*---+\s*$', multiLine: true),
    (_) => '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)'),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'(?<!\w)_(.+?)_(?!\w)'),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (match) => match.group(1) ?? '',
  );
  normalized = normalized.replaceAll('`', '');
  normalized = normalized.replaceAllMapped(
    RegExp(r'^\s*>\s?', multiLine: true),
    (_) => '',
  );
  normalized = normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return normalized.trim();
}
