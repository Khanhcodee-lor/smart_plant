import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiChatbotSheet extends ConsumerStatefulWidget {
  const AiChatbotSheet({super.key});

  @override
  ConsumerState<AiChatbotSheet> createState() => _AiChatbotSheetState();
}

class _AiChatbotSheetState extends ConsumerState<AiChatbotSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Hàm cuộn xuống cuối cùng khi có tin nhắn mới
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatbotControllerProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.92;
    // Lắng nghe trạng thái Chat từ Provider
    final chatState = ref.watch(chatbotControllerProvider);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 16.h),

          // ==================== HEADER ====================
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 32.w),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    "Trợ lý AI".h1Custom(size: 16.sp),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: "Beta".bodyCustom(size: 10.sp, color: Colors.grey),
                    ),
                  ],
                ),
                // Nút X
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // ==================== LIST TIN NHẮN ====================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              // Cộng thêm 1 item cho Logo chào mừng ở đầu, và 1 item cho "Đang tải" ở cuối
              itemCount:
                  1 + chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // 1. Khối Lời chào ở trên cùng
                if (index == 0) {
                  return Column(
                    children: [
                      SizedBox(height: 20.h),
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accent, Colors.pink.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      "Xin chào! Tôi là trợ lý AI của bạn".h1Custom(
                        size: 16.sp,
                        align: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      "Tôi có thể giúp bạn điều gì? Bạn có thể hỏi tôi về thông tin về các thiết bị của bạn hoặc cách sử dụng chúng."
                          .bodyCustom(
                            size: 12.sp,
                            color: AppColors.textSecondary,
                            align: TextAlign.center,
                            maxLines: 4,
                          ),
                      SizedBox(height: 30.h),
                    ],
                  );
                }

                // 2. Hiển thị "Đang gõ..." ở cuối cùng nếu đang chờ AI trả lời
                if (chatState.isLoading &&
                    index == chatState.messages.length + 1) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: "AI đang suy nghĩ...".bodyCustom(
                        size: 12.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }

                // 3. Render các tin nhắn chat
                final msg = chatState.messages[index - 1];
                final isUser = msg.isUser;

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                          bottomLeft: Radius.circular(isUser ? 16.r : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 16.r),
                        ),
                        boxShadow: [
                          if (!isUser)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: msg.text.bodyCustom(
                        size: 13.sp,
                        color: isUser ? Colors.white : AppColors.textMain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ==================== KHUNG NHẬP TEXT ====================
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              10.h,
              20.w,
              MediaQuery.of(context).padding.bottom + 10.h,
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w), // Độ dày của viền gradient
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, Colors.pink.shade200],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            onSubmitted: (_) =>
                                _sendMessage(), // Gửi khi ấn Enter
                            decoration: InputDecoration(
                              filled: false, // <-- Quan trọng để không đè viền
                              hintText: "Hỏi bất cứ điều gì",
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12.sp,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ),
                        // Nút Gửi hoặc Icon Mic
                        IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: AppColors.accent,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                "Nội dung được tạo ra bởi AI, vui lòng xác định cẩn thận"
                    .bodyCustom(size: 10.sp, color: Colors.grey.shade400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
