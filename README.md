[![Pub](https://img.shields.io/pub/v/use_location.svg?style=for-the-badge)](https://pub.dartlang.org/packages/use_location)

# Use Location

- Uses google play services to enable location services using dialog box if available.
- Automatically opens app settings and location settings to enable location and grant permissions.
- All using a _single_ method, that requires writing no logic by the user.

```dart
import 'package:use_location/use_location.dart';


var status = await UseLocation.useLocation(
  showEnableRationale: () async {
    return await showYesNoDialog(
      context,
      "Please enable location to continue.",
    );
  },
  showPermissionRationale: () async {
    return await showYesNoDialog(
      context,
      "Please grant location permission to continue.",
    );
  },
);
```
