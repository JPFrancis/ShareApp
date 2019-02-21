import 'package:flutter/material.dart';
import 'package:shareapp/item_list.dart';
import 'package:shareapp/item_edit.dart';

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
      home: ItemList(),
      //home: ItemEdit(),
    );
  }
}