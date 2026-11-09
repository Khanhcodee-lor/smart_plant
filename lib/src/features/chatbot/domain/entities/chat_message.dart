class ChatMessage {
  final String text;
  final bool isUser; // true nếu là user gửi, false nếu là AI gửi
  final bool isError;
  final bool includeInHistory;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.includeInHistory = true,
    DateTime? timestamp,
  })
    : timestamp = timestamp ?? DateTime.now();
}
