import 'package:flutter/material.dart';
import 'package:use_location/use_location.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Use Location Plugin'),
        ),
        body: Center(
          child: Main(),
        ),
      ),
    );
  }
}

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  UseLocationStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("status: '$status'"),
        SizedBox(height: 20),
        RaisedButton(
          child: Text('useLocation()'),
          onPressed: () async {
            setState(() {
              status = null;
            });

            var value = await UseLocation.useLocation(
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

            setState(() {
              status = value;
            });
          },
        ),
      ],
    );
  }
}

class YesNoDialog extends StatelessWidget {
  final String message;

  const YesNoDialog({Key key, @required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(message, textAlign: TextAlign.center),
      actions: <Widget>[
        SimpleDialogOption(
          child: Text(
            "NOPE",
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        SimpleDialogOption(
          child: Text(
            "OKAY",
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        )
      ],
    );
  }
}

Future<bool> showYesNoDialog(BuildContext context, String message) async {
  var choice = await showDialog(
    context: context,
    builder: (context) {
      return YesNoDialog(message: message);
    },
  );

  return choice ?? false;
}
