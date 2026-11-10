import 'dart:math';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lantern/core/common/common.dart';
import 'package:lantern/core/services/injection_container.dart';
import 'package:lantern/lantern/lantern_platform_service.dart';

final _deviceIdPattern = RegExp(r'^[0-9a-fA-F]{16}$');

/// Generates a random ID in the same shape as an Android ID:
/// 16 lowercase hexadecimal characters.
String _generateDeviceId() {
  final random = Random.secure();
  final bytes = List<int>.generate(8, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Lets the user override the device ID Lantern reports to the backend.
///
/// The backend consumes the device ID once, when it starts, so changes made
/// here only take effect after the app is restarted.
@RoutePage(name: 'DeviceIdSetting')
class DeviceIdSetting extends HookConsumerWidget {
  const DeviceIdSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final controller = useTextEditingController();
    final effective = useState<Map<String, String>?>(null);

    Future<void> load() async {
      final result = await sl<LanternPlatformService>().getEffectiveDeviceId();
      result.fold(
        (failure) => appLogger.error(
          'Failed to load effective device ID',
          failure,
          StackTrace.current,
        ),
        (value) {
          effective.value = value;
          if (value['source'] == 'custom' && controller.text.isEmpty) {
            controller.text = value['deviceId'] ?? '';
          }
        },
      );
    }

    useEffect(() {
      load();
      return null;
    }, []);

    Future<void> save() async {
      final id = controller.text.trim();
      if (!_deviceIdPattern.hasMatch(id)) {
        context.showSnackBar('device_id_invalid'.i18n);
        return;
      }
      final result = await sl<LanternPlatformService>().setCustomDeviceId(
        id.toLowerCase(),
      );
      if (!context.mounted) return;
      result.fold(
        (failure) => context.showSnackBar(failure.localizedErrorMessage),
        (_) {
          context.showSnackBar('device_id_saved_restart'.i18n);
          load();
        },
      );
    }

    Future<void> clear() async {
      final result = await sl<LanternPlatformService>().clearCustomDeviceId();
      if (!context.mounted) return;
      result.fold(
        (failure) => context.showSnackBar(failure.localizedErrorMessage),
        (_) {
          controller.clear();
          context.showSnackBar('device_id_cleared_restart'.i18n);
          load();
        },
      );
    }

    final deviceId = effective.value?['deviceId'] ?? '';
    final isCustom = effective.value?['source'] == 'custom';

    return BaseScreen(
      title: 'device_id_settings'.i18n,
      body: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: <Widget>[
          AppCard(
            padding: EdgeInsets.all(defaultSize),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'device_id_current'.i18n,
                  style: textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                SelectableText(
                  deviceId.isEmpty ? '...' : deviceId,
                  style: textTheme.bodyLarge,
                ),
                SizedBox(height: 4),
                Text(
                  (isCustom
                          ? 'device_id_source_custom'
                          : 'device_id_source_system')
                      .i18n,
                  style: textTheme.labelMedium!.copyWith(
                    color: context.textTertiary,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'device_id_notice'.i18n,
            style: textTheme.bodyMedium!.copyWith(
              color: context.textTertiary,
            ),
          ),
          SizedBox(height: 16),
          AppTextField(
            controller: controller,
            label: 'device_id_field_label'.i18n,
            hintText: 'device_id_hint'.i18n,
            maxLength: 16,
          ),
          SizedBox(height: 16),
          PrimaryButton(
            label: 'device_id_save'.i18n,
            isTaller: true,
            onPressed: save,
          ),
          SizedBox(height: 8),
          AppTextButton(
            label: 'device_id_generate'.i18n,
            onPressed: () {
              controller.text = _generateDeviceId();
            },
          ),
          AppTextButton(
            label: 'device_id_use_system'.i18n,
            onPressed: clear,
          ),
        ],
      ),
    );
  }
}
