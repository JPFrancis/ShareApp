/// ===================================

/// below is a empty app, can be used to test anything
/*

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'Test';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(),
      ),
    );
  }
}

*/

/// ========================================================================
/// Our actual app

import 'package:flutter/material.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/pages/item_list.dart';
import 'package:shareapp/pages/root_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShareApp',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new RootPage(auth: new Auth()),
      //initialRoute: '/',
      /*routes: <String, WidgetBuilder>{
        '/': (context) => RootPage(auth: new Auth()),
        '/ItemList': (context) => new ItemList(
              auth: RootPage().auth,
            ),
      },*/
    );
  }
}
