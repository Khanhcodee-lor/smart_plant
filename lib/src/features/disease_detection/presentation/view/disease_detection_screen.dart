import 'package:app_iot/src/core/views/base_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiseaseDetectionScreen extends BaseView {
  final String plantId;
  const DiseaseDetectionScreen({super.key, required this.plantId});

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text(
          'Chi tiết ID: $plantId',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
