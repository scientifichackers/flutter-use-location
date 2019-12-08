import 'package:flutter/services.dart';

enum UseLocationStatus {
  ok,
  enableDenied,
  permissionDenied,
  waiting,
}

enum InternalStatus {
  ok,
  enableDenied,
  permissionDenied,
  showPermissionRationale,
  openPermissionSettings,
  openEnableSettings
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
typedef Future<bool> ShowRationale();

class UseLocation {
  static const channel =
      const MethodChannel('com.scientifichackers.use_location');

  static Future<UseLocationStatus> useLocation({
    ShowRationale showPermissionRationale,
    ShowRationale showEnableRationale,
    LocationPermissionType permissionType =
        LocationPermissionType.accessFineLocation,
  }) async {
    var index = await channel.invokeMethod("useLocation", {
      'permissionType': permissionType.index,
    });

    var status = InternalStatus.values[index];
    print('>>> $status');

    switch (status) {
      case InternalStatus.showPermissionRationale:
        var shouldContinue = await showPermissionRationale?.call() ?? true;
        if (!shouldContinue) {
          return UseLocationStatus.permissionDenied;
        }

        index = await channel.invokeMethod("ensurePermission", {
          'permissionType': permissionType.index,
          'considerShowRationale': false,
        });

        if (index == InternalStatus.openPermissionSettings.index) {
          // Holds true when the user selects "Never ask Again" for the first time.
          //
          // This check is necessary because android doesn't
          // provide a way to distinguish between the first
          // and subsequent calls for requesting permission
          // after "Never ask Again" is selected.
          //
          // The plugin code simply expects the user to
          // manually grant permission every-time,
          // but we don't want that for the first time.

          return UseLocationStatus.permissionDenied;
        }

        break;

      case InternalStatus.openPermissionSettings:
        var shouldContinue = await showPermissionRationale?.call() ?? true;
        if (!shouldContinue) {
          return UseLocationStatus.permissionDenied;
        }

        await channel.invokeMethod("openPermissionSettings");

        return UseLocationStatus.waiting;

      case InternalStatus.openEnableSettings:
        var shouldContinue = await showEnableRationale?.call() ?? true;
        if (!shouldContinue) {
          return UseLocationStatus.enableDenied;
        }

        await channel.invokeMethod("openEnableSettings");

        return UseLocationStatus.waiting;

      default:
        break;
    }

    print("--- $index");
    return UseLocationStatus.values[index];
  }
}
