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

      // Thêm chỉ dẫn để AI trả lời ngắn gọn, đúng trọng tâm
      const systemPrefix =
          '[Hệ thống: Trả lời ngắn gọn, đúng trọng tâm, tối đa 3-5 câu. '
          'Không liệt kê dài dòng. Nếu cần chi tiết, hỏi người dùng muốn biết thêm không. '
          'Nếu người dùng hỏi về bệnh cây có kèm độ tin cậy %, hãy đánh giá: '
          'trên 70% là bệnh nặng cần xử lý gấp, 40-70% là bệnh trung bình cần theo dõi và xử lý, '
          'dưới 40% là bệnh nhẹ và đưa ra giải pháp phòng ngừa sớm.]\n\n';

      // Truyền dữ liệu dạng Map lên Server
      final result = await callable.call(<String, dynamic>{
        'text': '$systemPrefix$text',
      });

      if (!mounted) return;

      // Lấy câu trả lời (trường 'reply' đã định nghĩa ở index.js)
      String aiResponse = result.data['reply'] ?? "AI không có phản hồi";
      aiResponse = formatAssistantMessageForDisplay(aiResponse);

      // 3. Thêm tin nhắn AI vào state, tắt Loading
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: aiResponse, isUser: false),
        ],
        isLoading: false,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      // Lỗi do Firebase hoặc Server trả về
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: "Lỗi kết nối: ${error.message}", isUser: false),
        ],
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
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
