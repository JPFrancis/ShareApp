import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';

class ItemDetail extends StatefulWidget {
  Item item;
  String appBarTitle;

  ItemDetail(this.item, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    //appBarTitle += ' Item';
    return ItemDetailState(this.item, this.appBarTitle);
  }
}

class ItemDetailState extends State<ItemDetail> {
  Item item;
  //var itemVar = new Item();
  String appBarTitle;

  ItemDetailState(this.item, this.appBarTitle);

  @override
  Widget build(BuildContext context) {

  }
}