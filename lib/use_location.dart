import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'src/show_rationale.dart' as sr;
import 'src/stubs.dart';

enum UseLocationStatus {
  ok,
  enableDenied,
  permissionDenied,
}

enum LocationPermissionType {
  accessFineLocation,
  accessCoarseLocation,
}

/// A callback that allows showing a small message to user
/// explaining the need to acquire some kind of permission.
///
/// This method should return a Boolean value,
/// indicating whether the library should continue
/// asking the user for that permission or not.
typedef Future<bool> ShowRationale(BuildContext context);

bool _indexOutOfBounds(int index) {
  return index > UseLocationStatus.values.length - 1;
}

class UseLocation {
  static const channel =
      const MethodChannel('com.scientifichackers.use_location');

  static Future<UseLocationStatus> useLocation(
    BuildContext context, {
    ShowRationale showPermissionRationale,
    ShowRationale showPermissionSettingsRationale,
    ShowRationale showEnableSettingsRationale,
    LocationPermissionType permissionType =
        LocationPermissionType.accessFineLocation,
  }) async {
    showPermissionRationale ??= sr.showPermissionRationale;
    showPermissionSettingsRationale ??= sr.showPermissionSettingsRationale;
    showEnableSettingsRationale ??= sr.showEnableSettingsRationale;

    var args = {'permissionType': permissionType.index};
    var index = await channel.invokeMethod("useLocation", args);

    switch (InternalStatus.values[index]) {
      case InternalStatus.showPermissionRationale:
        var shouldContinue = await showPermissionRationale(context);
        if (!shouldContinue) {
          return UseLocationStatus.permissionDenied;
        }

        index = await channel.invokeMethod("ensurePermission", {
          'permissionType': permissionType.index,
          'considerShowRationale': false,
        });
        if (_indexOutOfBounds(index)) {
          return UseLocationStatus.permissionDenied;
        }

        break;

      case InternalStatus.openPermissionSettings:
        var proceed = await showPermissionSettingsRationale(context);
        if (!proceed) {
          return UseLocationStatus.permissionDenied;
        }

        index = await channel.invokeMethod("openPermissionSettings", args);
        if (_indexOutOfBounds(index)) {
          return UseLocationStatus.permissionDenied;
        }

        break;

      case InternalStatus.openEnableSettings:
        var proceed = await showEnableSettingsRationale(context);
        if (!proceed) {
          return UseLocationStatus.enableDenied;
        }

        index = await channel.invokeMethod("openEnableSettings", args);
        if (_indexOutOfBounds(index)) {
          return UseLocationStatus.enableDenied;
        }

        break;

      default:
        break;
    }

    return UseLocationStatus.values[index];
  }
}
