class ChatMessage {
  final String text;
  final bool isUser; // true nếu là user gửi, false nếu là AI gửi
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
