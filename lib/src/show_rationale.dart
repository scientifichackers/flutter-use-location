import 'package:flutter/material.dart';

class RationaleDialog extends StatelessWidget {
  final String msg;
  final bool isOpenSettings;

  const RationaleDialog({
    Key key,
    @required this.msg,
    @required this.isOpenSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      actions: <Widget>[
        SimpleDialogOption(
          child: Text(
            'NO',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        SimpleDialogOption(
          child: Text(
            isOpenSettings ? 'OPEN SETTINGS' : 'OK',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

Future<bool> showRationaleDialog({
  @required BuildContext context,
  @required String msg,
  @required bool isOpenSettings,
}) async {
  var proceed = await showDialog(
    context: context,
    builder: (context) {
      return RationaleDialog(
        msg: msg,
        isOpenSettings: isOpenSettings,
      );
    },
  );
  // if the dialog is dismissed
  return proceed ?? false;
}

Future<bool> showPermissionRationale(BuildContext context) async {
  return showRationaleDialog(
    context: context,
    msg: 'Please grant location access to continue.',
    isOpenSettings: false,
  );
}

Future<bool> showPermissionSettingsRationale(BuildContext context) async {
  return showRationaleDialog(
    context: context,
    msg: 'Please grant location access to continue.',
    isOpenSettings: true,
  );
}

Future<bool> showEnableSettingsRationale(BuildContext context) async {
  return showRationaleDialog(
    context: context,
    msg: 'Please enable location services to continue.',
    isOpenSettings: true,
  );
}
