import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SensorStatus extends StatelessWidget {
  const SensorStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ["Trạng thái".h1Custom(size: 14.sp)],
    );
  }
}
