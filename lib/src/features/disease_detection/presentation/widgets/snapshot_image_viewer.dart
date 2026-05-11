import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SnapshotImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? errorBuilder;

  const SnapshotImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = imageUrl.trim();
    if (normalizedUrl.isEmpty) {
      return _buildError(context);
    }

    final dataImageBytes = _tryDecodeDataImage(normalizedUrl);
    if (dataImageBytes != null) {
      return Image.memory(
        dataImageBytes,
        fit: fit,
        errorBuilder: (_, _, _) => _buildError(context),
      );
    }

    if (isLocalSnapshotImagePath(normalizedUrl)) {
      return Image.file(
        _localFileFromPath(normalizedUrl),
        fit: fit,
        errorBuilder: (_, _, _) => _buildError(context),
      );
    }

    return Image.network(
      normalizedUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return loadingBuilder?.call(context) ?? child;
      },
      errorBuilder: (_, _, _) => _buildError(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return errorBuilder?.call(context) ??
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: 'KhÃ´ng táº£i Ä‘Æ°á»£c áº£nh'.bodyCustom(
            size: 14.sp,
            color: Colors.white70,
            align: TextAlign.center,
          ),
        );
  }
}

bool isLocalSnapshotImagePath(String imageUrl) {
  final normalizedUrl = imageUrl.trim();
  if (normalizedUrl.isEmpty || isInlineSnapshotImageData(normalizedUrl)) {
    return false;
  }

  final uri = Uri.tryParse(normalizedUrl);
  if (uri != null) {
    if (uri.scheme == 'file') {
      return true;
    }
    if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'gs') {
      return false;
    }
  }

  return normalizedUrl.startsWith('/') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(normalizedUrl);
}

bool isInlineSnapshotImageData(String imageUrl) {
  return imageUrl.trim().startsWith('data:image/');
}

File _localFileFromPath(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  if (uri != null && uri.scheme == 'file') {
    return File.fromUri(uri);
  }
  return File(imageUrl);
}

Uint8List? _tryDecodeDataImage(String imageUrl) {
  final normalizedUrl = imageUrl.trim();
  if (!normalizedUrl.startsWith('data:image/')) {
    return null;
  }

  final commaIndex = normalizedUrl.indexOf(',');
  if (commaIndex < 0) {
    return null;
  }

  final metadata = normalizedUrl.substring(0, commaIndex);
  if (!metadata.contains(';base64')) {
    return null;
  }

  try {
    return base64Decode(normalizedUrl.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}

void showSnapshotImageViewer(
  BuildContext context, {
  required String imageUrl,
  String title = 'Ảnh bệnh',
  String subtitle = '',
}) {
  final normalizedUrl = imageUrl.trim();
  if (normalizedUrl.isEmpty) {
    return;
  }

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng',
    barrierColor: Colors.black,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: title.h2Custom(
                        size: 16.sp,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: SnapshotImage(
                      imageUrl: normalizedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context) {
                        return CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.4,
                        );
                      },
                      errorBuilder: (context) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: 'Không tải được ảnh'.bodyCustom(
                            size: 14.sp,
                            color: Colors.white70,
                            align: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (subtitle.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
                  child: subtitle.bodyCustom(
                    size: 12.sp,
                    color: Colors.white70,
                    align: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
