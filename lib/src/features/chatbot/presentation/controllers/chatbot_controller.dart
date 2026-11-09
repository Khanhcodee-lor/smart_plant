import 'package:app_iot/src/features/chatbot/domain/entities/chat_message.dart';
import 'package:app_iot/src/features/chatbot/presentation/utils/chatbot_message_formatter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

//Controller quản lý chat bot
class ChatbotController extends StateNotifier<ChatState> {
  ChatbotController()
    : super(
        ChatState(
          messages: [
            ChatMessage(
              text:
                  "Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp bạn điều gì về các thiết bị trồng cây?",
              isUser: false,
              includeInHistory: false,
            ),
          ],
        ),
      );

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || state.isLoading) return;

    final history = state.messages
        .where((message) => message.includeInHistory && !message.isError)
        .map(
          (message) => <String, String>{
            'role': message.isUser ? 'user' : 'model',
            'text': message.text,
          },
        )
        .toList(growable: false);

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: cleanText, isUser: true),
      ],
      isLoading: true,
    );

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('askChatbot');
      final result = await callable.call(<String, dynamic>{
        'text': cleanText,
        'history': history,
      });

      if (!mounted) return;

      final responseData = result.data;
      final reply = responseData is Map ? responseData['reply'] : null;
      if (reply is! String || reply.trim().isEmpty) {
        throw StateError('Cloud Function returned an empty reply.');
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: formatAssistantMessageForDisplay(reply.trim()),
            isUser: false,
          ),
        ],
        isLoading: false,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'unauthenticated' => 'Bạn cần đăng nhập để sử dụng trợ lý AI.',
        'resource-exhausted' => 'Hệ thống đang quá tải. Bạn thử lại sau nhé.',
        'unavailable' => 'Trợ lý AI đang bận. Bạn thử lại sau ít phút nhé.',
        'failed-precondition' =>
          'Trợ lý AI chưa được cấu hình đầy đủ trên Firebase.',
        'invalid-argument' => error.message ?? 'Tin nhắn chưa hợp lệ.',
        _ => 'Không kết nối được với trợ lý AI. Bạn thử lại sau nhé.',
      };
      _appendErrorMessage(message);
    } catch (e) {
      if (!mounted) return;
      _appendErrorMessage('Trợ lý AI chưa thể trả lời lúc này. Bạn thử lại nhé.');
    }
  }

  void _appendErrorMessage(String text) {
    final messages = state.messages.toList();
    final failedUserIndex = messages.lastIndexWhere(
      (message) => message.isUser,
    );
    if (failedUserIndex >= 0) {
      final failedMessage = messages[failedUserIndex];
      messages[failedUserIndex] = ChatMessage(
        text: failedMessage.text,
        isUser: true,
        includeInHistory: false,
        timestamp: failedMessage.timestamp,
      );
    }

    state = state.copyWith(
      messages: [
        ...messages,
        ChatMessage(text: text, isUser: false, isError: true),
      ],
      isLoading: false,
    );
  }
}

final chatbotControllerProvider =
    StateNotifierProvider.autoDispose<ChatbotController, ChatState>((ref) {
      return ChatbotController();
    });
