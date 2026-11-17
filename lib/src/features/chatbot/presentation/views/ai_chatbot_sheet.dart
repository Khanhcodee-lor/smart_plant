import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/constants/app_text_styles.dart';
import 'package:app_iot/src/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiChatbotSheet extends ConsumerStatefulWidget {
  final String? initialMessage;
  final bool autoSendInitialMessage;
  final Map<String, dynamic>? initialContext;

  const AiChatbotSheet({
    super.key,
    this.initialMessage,
    this.autoSendInitialMessage = false,
    this.initialContext,
  });

  @override
  ConsumerState<AiChatbotSheet> createState() => _AiChatbotSheetState();
}

class _AiChatbotSheetState extends ConsumerState<AiChatbotSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    final initialMessage = widget.initialMessage?.trim();
    if (initialMessage == null || initialMessage.isEmpty) {
      return;
    }

    if (widget.autoSendInitialMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ref
            .read(chatbotControllerProvider.notifier)
            .sendMessage(initialMessage, context: widget.initialContext);
        _scrollToBottom();
      });
    } else {
      _textController.text = initialMessage;
    }
  }

  // ===================== CUỘN & GỬI =====================

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

  Widget _buildMessageContent(String text, {required bool isUser}) {
    if (isUser) {
      return Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 12.5.sp,
          height: 1.4,
          color: Colors.white,
        ),
      );
    }

    final blocks = <Widget>[];
    final paragraphLines = <String>[];
    final bodyStyle = AppTextStyles.body.copyWith(
      fontSize: 12.5.sp,
      height: 1.48,
      color: AppColors.textMain,
    );

    void addParagraph() {
      final paragraph = paragraphLines.join(' ').trim();
      if (paragraph.isEmpty) return;
      if (blocks.isNotEmpty) blocks.add(SizedBox(height: 5.h));
      blocks.add(Text(paragraph, style: bodyStyle));
      paragraphLines.clear();
    }

    for (final sourceLine in text.split('\n')) {
      final line = sourceLine.trim();
      if (line.isEmpty) {
        addParagraph();
        continue;
      }

      final heading = RegExp(r'^\d+[.)]\s*(.+)$').firstMatch(line);
      if (heading != null) {
        addParagraph();
        if (blocks.isNotEmpty) blocks.add(SizedBox(height: 7.h));
        blocks.add(
          Text(
            heading.group(1)!.trim(),
            style: AppTextStyles.body.copyWith(
              fontSize: 12.5.sp,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        );
        blocks.add(SizedBox(height: 3.h));
        continue;
      }

      final bullet = RegExp(r'^[•*-]\s*(.+)$').firstMatch(line);
      if (bullet != null) {
        addParagraph();
        if (blocks.isNotEmpty) blocks.add(SizedBox(height: 3.h));
        blocks.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1.h, right: 7.w),
                child: Icon(
                  Icons.circle,
                  size: 5.sp,
                  color: AppColors.accent,
                ),
              ),
              Expanded(child: Text(bullet.group(1)!.trim(), style: bodyStyle)),
            ],
          ),
        );
        continue;
      }

      paragraphLines.add(line);
    }
    addParagraph();

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: blocks,
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty &&
        !ref.read(chatbotControllerProvider).isLoading) {
      final hasUserMessages = ref
          .read(chatbotControllerProvider)
          .messages
          .any((message) => message.isUser);
      ref
          .read(chatbotControllerProvider.notifier)
          .sendMessage(
            text,
            context: hasUserMessages ? null : widget.initialContext,
          );
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
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = mediaQuery.size.height - keyboardHeight;
    ref.listen<ChatState>(chatbotControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });
    final chatState = ref.watch(chatbotControllerProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: availableHeight * 0.92,
      margin: EdgeInsets.only(bottom: keyboardHeight),
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
                SizedBox(width: 28.w),
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

                // 2. "Đang gõ..." ở cuối nếu đang chờ AI
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

                // 3. Render tin nhắn
                final msgIndex = index - 1;
                final msg = chatState.messages[msgIndex];
                final isUser = msg.isUser;

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width *
                              (isUser ? 0.82 : 0.94),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primary
                              : const Color(0xFFF1F8F6),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: AppColors.accent.withOpacity(0.14),
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: Radius.circular(isUser ? 16.r : 5.r),
                            bottomRight: Radius.circular(isUser ? 5.r : 16.r),
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
                        child: _buildMessageContent(msg.text, isUser: isUser),
                      ),
                    ],
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
              (keyboardHeight > 0 ? 0 : mediaQuery.padding.bottom) + 10.h,
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
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
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: "Hỏi bất cứ điều gì",
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12.sp,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Gửi tin nhắn',
                          onPressed:
                              chatState.isLoading ||
                                  _textController.text.trim().isEmpty
                              ? null
                              : _sendMessage,
                          icon: chatState.isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          color: AppColors.accent,
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
