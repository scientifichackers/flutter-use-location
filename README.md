[![Pub](https://img.shields.io/pub/v/use_location.svg?style=for-the-badge)](https://pub.dartlang.org/packages/use_location)

# Use Location

Want to request access to user's location, and enable location services without dealing with the pesky permissions API? This plugin is for you! 

- Uses google play services to enable location services using dialog box if available.
- Automatically opens app settings and location settings to enable location and grant permissions if all else fails. 
- All using a _single_ method, that requires zero logic in your code.

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
