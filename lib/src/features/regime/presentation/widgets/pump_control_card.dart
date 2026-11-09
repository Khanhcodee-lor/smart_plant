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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F7F3),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.accent,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    "Điều khiển bơm".h1Custom(
                      size: 15.sp,
                      color: AppColors.textMain,
                      fontweight: FontWeight.w700,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Quản lý chế độ tưới',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              _PumpStatusChip(label: pump?.displayLabel ?? 'Đang tải'),
            ],
          ),
          SizedBox(height: 15.h),
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
                  isOutlined: true,
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
    this.isOutlined = false,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final bool isOutlined;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? Colors.white.withOpacity(0.72)
              : backgroundColor,
          foregroundColor: isOutlined ? backgroundColor : Colors.white,
          side: BorderSide(
            color: isOutlined
                ? backgroundColor.withOpacity(0.3)
                : Colors.transparent,
          ),
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: isOutlined
              ? backgroundColor
              : Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: isOutlined ? backgroundColor : Colors.white,
                ),
              )
            : Icon(icon, size: 19.sp),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: label.bodyCustom(
            size: 13.sp,
            color: isOutlined ? backgroundColor : Colors.white,
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
