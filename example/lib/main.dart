import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert' show JsonEncoder;
import 'package:flutter/services.dart';
import 'package:flutter_windows_vault/flutter_windows_vault.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Page(),
    );
  }
}

class Page extends StatefulWidget {
  @override
  _PageState createState() => _PageState();
}

class _PageState extends State<Page> {
  String _platformVersion = 'Unknown';
  static final jsonEncoder = JsonEncoder.withIndent('   ');

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await FlutterWindowsVault.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    setState(() {
      _platformVersion = platformVersion;
    });
  }

  _showDialog({
    @required String title,
    @required dynamic value,
    List<dynamic> values: const <dynamic>[],
    bool error = false,
  }) {
    showDialog(
      context: context,
      child: SimpleDialog(
        title: Text('$title ${error ? 'error : ' : 'done : '}'),
        contentPadding: EdgeInsets.all(20),
        children: [
          IconButton(
            icon: Icon(
              error ? Icons.error : Icons.done,
              color: Colors.red,
            ),
            onPressed: Navigator.of(context).pop,
          ),
          if (value != null)
            SelectableText(
              '${error ? value : jsonEncoder.convert(value)}',
            ),
          for (dynamic v in values)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              margin: EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('${jsonEncoder.convert(v)}'),
            ),
        ],
      ),
    );
  }

  void set() {
    FlutterWindowsVault.set(key: 'password', value: '123456789')
        .then((v) => _showDialog(title: 'set', value: v))
        .catchError(
            (err) => _showDialog(title: 'set', error: true, value: err));
  }

  void get() {
    FlutterWindowsVault.get(key: 'password')
        .then((v) => _showDialog(title: 'get', value: v.toJson))
        .catchError(
            (err) => _showDialog(title: 'get', error: true, value: err));
  }

  void del() {
    FlutterWindowsVault.del(key: 'password')
        .then((v) => _showDialog(title: 'del', value: v))
        .catchError(
            (err) => _showDialog(title: 'del', error: true, value: err));
  }

  void list() {
    FlutterWindowsVault.list()
        .then((v) => _showDialog(
              title: 'list',
              value: null,
              values: v?.map((e) => e?.toJson)?.toList() ?? [],
            ))
        .catchError(
            (err) => _showDialog(title: 'list', error: true, value: err));
  }

  void encrypt() {
    FlutterWindowsVault.encrypt(
      value: '123456789',
      fAsSelf: false,
    );
    FlutterWindowsVault.encrypt(value: '123456789')
        .then((v) => _showDialog(title: 'encrypt', value: v))
        .catchError(
            (err) => _showDialog(title: 'encrypt', error: true, value: err));
  }

  void decrypte() {
    FlutterWindowsVault.decrypt(
            value:
                "@@D\u0007\b\f\n\rgAAAAAYppBAAAAAAA5c5uXGQ1pJpY0VrAG-aZawRYNC3MboXJ")
        .then((v) => _showDialog(title: 'decrypte', value: v))
        .catchError(
            (err) => _showDialog(title: 'decrypte', error: true, value: err));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        drawer: Drawer(),
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 504,
              maxHeight: MediaQuery.of(context).size.height - 40,
            ),
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text('Running on: $_platformVersion\n'),
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Set'),
                    onPressed: set,
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Get'),
                    onPressed: get,
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Delete'),
                    onPressed: del,
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('list'),
                    onPressed: list,
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('encrypt'),
                    onPressed: encrypt,
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                    minWidth: 504,
                    height: 60,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('decrypte'),
                    onPressed: decrypte,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
