import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AllItems extends StatefulWidget {
  static const routeName = '/allItems';

  AllItems({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AllItemsState();
  }
}

class AllItemsState extends State<AllItems> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('All items'),
          // back button
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              goBack();
            },
          ),
        ),
        body: showBody(),
        //floatingActionButton: showFAB(),
      ),
    );
  }

  Widget showBody() {
    return Center(
      child: Text('Hello'),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
