import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PumpControlCard extends ConsumerWidget {
  const PumpControlCard({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeAsyncValue = ref.watch(regimeRealtimeDataProvider(plantId));
    final inFlightAction = ref.watch(pumpControlInFlightProvider(plantId));
    final pump = realtimeAsyncValue.asData?.value.pump;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.accent,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: "Điều khiển bơm".h1Custom(
                  size: 16.sp,
                  color: AppColors.textMain,
                  fontweight: FontWeight.w600,
                ),
              ),
              _PumpStatusChip(label: pump?.displayLabel ?? 'Đang tải'),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _PumpActionButton(
                  label: 'Bơm tự động',
                  icon: Icons.auto_mode,
                  backgroundColor: AppColors.accent,
                  isLoading: inFlightAction == PumpControlAction.automatic,
                  isDisabled: inFlightAction != null,
                  onPressed: () => _handlePumpAction(
                    context,
                    ref,
                    PumpControlAction.automatic,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _PumpActionButton(
                  label: 'Tắt thủ công',
                  icon: Icons.power_settings_new,
                  backgroundColor: AppColors.error,
                  isLoading: inFlightAction == PumpControlAction.manualOff,
                  isDisabled: inFlightAction != null,
                  onPressed: () => _handlePumpAction(
                    context,
                    ref,
                    PumpControlAction.manualOff,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePumpAction(
    BuildContext context,
    WidgetRef ref,
    PumpControlAction action,
  ) async {
    final inFlight = ref.read(pumpControlInFlightProvider(plantId).notifier);
    if (inFlight.state != null) {
      return;
    }

    inFlight.state = action;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = ref.read(pumpControlServiceProvider);
      switch (action) {
        case PumpControlAction.automatic:
          await service.setAutomatic(plantId);
        case PumpControlAction.manualOff:
          await service.turnOffManual(plantId);
      }

      ref.invalidate(regimeRealtimeDataProvider(plantId));
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(_successMessage(action))));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Cập nhật bơm thất bại: $error')),
      );
    } finally {
      inFlight.state = null;
    }
  }

  String _successMessage(PumpControlAction action) {
    return switch (action) {
      PumpControlAction.automatic => 'Đã bật chế độ bơm tự động',
      PumpControlAction.manualOff => 'Đã tắt bơm thủ công',
    };
  }
}

class _PumpActionButton extends StatelessWidget {
  const _PumpActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 19.sp),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: label.bodyCustom(
            size: 13.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PumpStatusChip extends StatelessWidget {
  const _PumpStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: label.bodyCustom(
        size: 12.sp,
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
