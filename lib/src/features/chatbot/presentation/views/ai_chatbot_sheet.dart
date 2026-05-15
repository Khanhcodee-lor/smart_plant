import 'package:app_iot/src/core/constants/api_config.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/chatbot/data/cloud_tts_service.dart';
import 'package:app_iot/src/features/chatbot/data/voice_transcription_service.dart';
import 'package:app_iot/src/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class AiChatbotSheet extends ConsumerStatefulWidget {
  final String? initialMessage;
  final bool autoSendInitialMessage;

  const AiChatbotSheet({
    super.key,
    this.initialMessage,
    this.autoSendInitialMessage = false,
  });

  @override
  ConsumerState<AiChatbotSheet> createState() => _AiChatbotSheetState();
}

class _AiChatbotSheetState extends ConsumerState<AiChatbotSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final CloudTtsService _ttsService = CloudTtsService();
  final VoiceTranscriptionService _voiceService = VoiceTranscriptionService();

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isTtsPlaying = false;
  bool _isTtsEnabled = true;

  /// Index của tin nhắn AI đang được đọc (-1 = không đọc gì)
  int _currentSpeakingIndex = -1;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    // Callback từ TTS service
    _ttsService.onStart = () {
      if (mounted) setState(() => _isTtsPlaying = true);
    };
    _ttsService.onComplete = () {
      if (mounted) {
        setState(() {
          _isTtsPlaying = false;
          _currentSpeakingIndex = -1;
        });
      }
    };

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
            .sendMessage(initialMessage);
        _scrollToBottom();
      });
    } else {
      _textController.text = initialMessage;
    }
  }

  // ===================== GHI ÂM & NHẬN DIỆN GIỌNG NÓI =====================

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Dừng TTS nếu đang phát
    if (_isTtsPlaying) {
      await _ttsService.stop();
    }

    // Xin quyền Microphone
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Vui lòng cấp quyền microphone để sử dụng giọng nói.',
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Cài đặt',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Kiểm tra API key
    if (ApiConfig.googleSpeechApiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Chưa cấu hình API key. Thêm key vào api_config.dart',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final started = await _voiceService.startRecording();
    if (started && mounted) {
      setState(() => _isRecording = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không thể bắt đầu ghi âm.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final transcript = await _voiceService.stopAndTranscribe(
        ApiConfig.googleSpeechApiKey,
      );

      if (!mounted) return;

      if (transcript != null && transcript.isNotEmpty) {
        _textController.text = transcript;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: transcript.length),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Không nhận diện được giọng nói. Hãy nói to và rõ hơn.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi xử lý giọng nói.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  // ===================== TTS — AI ĐỌC VĂN BẢN =====================

  void _speakMessage(String text, int messageIndex) {
    if (_isTtsPlaying && _currentSpeakingIndex == messageIndex) {
      // Đang đọc tin nhắn này → dừng lại
      _ttsService.stop();
      return;
    }

    setState(() => _currentSpeakingIndex = messageIndex);
    _ttsService.speak(text, ApiConfig.googleSpeechApiKey);
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

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      if (_isTtsPlaying) {
        _ttsService.stop();
      }
      ref.read(chatbotControllerProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    // Xóa callback trước để tránh gọi setState sau khi widget bị dispose
    _ttsService.onStart = null;
    _ttsService.onComplete = null;
    _ttsService.stop();
    _ttsService.dispose();
    _voiceService.cancelRecording();
    _voiceService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.92;
    ref.listen<ChatState>(chatbotControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }

      // Khi AI trả lời xong → tự động đọc nếu TTS đang bật
      if (_isTtsEnabled &&
          previous?.isLoading == true &&
          next.isLoading == false) {
        if (next.messages.isNotEmpty) {
          final lastMsg = next.messages.last;
          if (!lastMsg.isUser) {
            final msgIndex = next.messages.length - 1;
            _speakMessage(lastMsg.text, msgIndex);
          }
        }
      }
    });
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
                // Nút bật/tắt TTS
                InkWell(
                  onTap: () {
                    setState(() => _isTtsEnabled = !_isTtsEnabled);
                    if (!_isTtsEnabled && _isTtsPlaying) {
                      _ttsService.stop();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isTtsEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      size: 20.sp,
                      color: _isTtsEnabled ? AppColors.accent : Colors.grey,
                    ),
                  ),
                ),
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
                final isSpeakingThis =
                    _isTtsPlaying && _currentSpeakingIndex == msgIndex;

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
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
                      // Nút phát loa cho tin nhắn AI
                      if (!isUser) ...[
                        SizedBox(height: 4.h),
                        GestureDetector(
                          onTap: () => _speakMessage(msg.text, msgIndex),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpeakingThis
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_outlined,
                                size: 16.sp,
                                color: isSpeakingThis
                                    ? AppColors.accent
                                    : AppColors.disabledText,
                              ),
                              SizedBox(width: 4.w),
                              (isSpeakingThis ? "Đang đọc..." : "Nghe")
                                  .bodyCustom(
                                    size: 11.sp,
                                    color: isSpeakingThis
                                        ? AppColors.accent
                                        : AppColors.disabledText,
                                  ),
                            ],
                          ),
                        ),
                      ],
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
              MediaQuery.of(context).padding.bottom + 10.h,
            ),
            child: Column(
              children: [
                // Hiển thị trạng thái ghi âm
                if (_isRecording)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        "Đang ghi âm... Nhấn lại để dừng".bodyCustom(
                          size: 12.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                if (_isTranscribing)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        "Đang xử lý giọng nói...".bodyCustom(
                          size: 12.sp,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Colors.red, Colors.redAccent]
                          : [AppColors.accent, Colors.pink.shade200],
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
                            enabled: !_isRecording && !_isTranscribing,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              filled: false,
                              hintText: _isRecording
                                  ? "Đang lắng nghe..."
                                  : _isTranscribing
                                      ? "Đang xử lý..."
                                      : "Hỏi bất cứ điều gì",
                              hintStyle: TextStyle(
                                color: _isRecording
                                    ? Colors.red
                                    : AppColors.textHint,
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
                        // Nút Mic (ghi âm)
                        if (_textController.text.trim().isEmpty &&
                            !_isTranscribing)
                          IconButton(
                            icon: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic,
                              color: _isRecording
                                  ? Colors.red
                                  : AppColors.accent,
                              size: _isRecording ? 28.sp : 22.sp,
                            ),
                            onPressed: _toggleRecording,
                          ),
                        // Nút Gửi
                        if (_textController.text.trim().isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: AppColors.accent,
                            ),
                            onPressed: _sendMessage,
                          ),
                        // Loading khi đang transcribe
                        if (_isTranscribing)
                          Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
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
