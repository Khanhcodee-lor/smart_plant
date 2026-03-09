import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';

class VideoStreamWidget extends StatefulWidget {
  final String videoUrl;

  const VideoStreamWidget({super.key, required this.videoUrl});

  @override
  State<VideoStreamWidget> createState() => _VideoStreamWidgetState();
}

class _VideoStreamWidgetState extends State<VideoStreamWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(
        Uri.parse(widget.videoUrl.isNotEmpty ? widget.videoUrl : 'about:blank'),
      );
  }

  @override
  void didUpdateWidget(covariant VideoStreamWidget oldWidget) {
    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.videoUrl));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: "Không có luồng video".bodyCustom(
            color: AppColors.disabledText,
          ),
        ),
      );
    }

    return Container(
      height: 250.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
