import 'package:app_iot/src/features/chatbot/domain/entities/chat_message.dart';
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
            ),
          ],
        ),
      );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    // 1. Thêm tin nhắn của User vào danh sách và bật trạng thái Loading
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: text, isUser: true),
      ],
      isLoading: true,
    );

    try {
      // 2. GỌI FIREBASE CLOUD FUNCTION có tên là 'askChatbot'
      final callable = FirebaseFunctions.instance.httpsCallable('askChatbot');

      // Truyền dữ liệu dạng Map lên Server
      final result = await callable.call(<String, dynamic>{'text': text});

      // Lấy câu trả lời (trường 'reply' đã định nghĩa ở index.js)
      String aiResponse = result.data['reply'] ?? "AI không có phản hồi";

      // 3. Thêm tin nhắn AI vào state, tắt Loading
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: aiResponse, isUser: false),
        ],
        isLoading: false,
      );
    } on FirebaseFunctionsException catch (error) {
      // Lỗi do Firebase hoặc Server trả về
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: "Lỗi kết nối: ${error.message}", isUser: false),
        ],
        isLoading: false,
      );
    } catch (e) {
      // Lỗi cục bộ khác
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: "Đã xảy ra lỗi không xác định.", isUser: false),
        ],
        isLoading: false,
      );
    }
  }
}

final chatbotControllerProvider =
    StateNotifierProvider.autoDispose<ChatbotController, ChatState>((ref) {
      return ChatbotController();
    });
