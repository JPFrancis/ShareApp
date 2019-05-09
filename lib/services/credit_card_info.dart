import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shareapp/models/credit_card.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class CreditCardInfo extends StatefulWidget {
  static const routeName = '/creditCard';
  final CreditCard creditCard;

  CreditCardInfo({Key key, this.creditCard}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CreditCardInfoState();
  }
}

/// We initially assume we are in editing mode
class CreditCardInfoState extends State<CreditCardInfo> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  bool isEdit = true; // true if on editing mode, false if on adding mode
  bool isLoading;
  bool isUploading = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  TextEditingController cvvController = TextEditingController();
  TextEditingController zipController = TextEditingController();

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;

  DocumentSnapshot userDS;

  CreditCard ccCopy;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    init();
  }

  void init() async {
    isLoading = true;

    DocumentSnapshot ds = await Firestore.instance
        .collection('users')
        .document(widget.creditCard.userID)
        .get();

    if (ds != null) {
      userDS = ds;
      ccCopy = CreditCard.copy(widget.creditCard);
      nameController.text = ccCopy.name;
      numberController.text = ccCopy.number;
      monthController.text = ccCopy.month;
      yearController.text = ccCopy.year;
      cvvController.text = ccCopy.cvv;
      zipController.text = ccCopy.zip;

      if (userDS != null && ccCopy != null) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    return Scaffold(
      appBar: AppBar(
        title: Text('Credit Card Info'),
        actions: <Widget>[
          FlatButton(
            child: Text('SAVE',
                textScaleFactor: 1.05,
                style: theme.textTheme.body2.copyWith(color: Colors.white)),
            onPressed: () {
              save();
            },
          ),
        ],
      ),
      resizeToAvoidBottomPadding: true,
      body: Stack(
        children: <Widget>[
          isUploading
              ? Container(
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                )
              : showBody(),
          showCircularProgress(),
        ],
      ),
    );
  }

  Widget showBody() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: ListView(
        shrinkWrap: true,
        padding:
            EdgeInsets.only(top: 10, bottom: 10.0, left: 18.0, right: 18.0),
        children: <Widget>[
          reusableTextEntry(
              'Name on card', true, nameController, 'name', TextInputType.text),
          reusableTextEntry('Card number', true, numberController, 'number'),
          reusableTextEntry('Month', true, monthController, 'month'),
          reusableTextEntry('Year', true, yearController, 'year'),
          reusableTextEntry('CVV', true, cvvController, 'cvv'),
          reusableTextEntry('Zip code', true, zipController, 'zip'),
        ],
      ),
    );
  }

  Widget reusableTextEntry(placeholder, required, controller, saveTo,
      [keyboard = TextInputType.number]) {
    return Container(
      child: TextField(
        keyboardType: keyboard,
        controller: controller,
        inputFormatters: saveTo == 'number'
            ? [
                MaskedTextInputFormatter(
                  mask: 'xxxx-xxxx-xxxx-xxxx',
                  separator: '-',
                ),
              ]
            : null,
        onChanged: (value) {
          switch (saveTo) {
            case 'name':
              ccCopy.name = controller.text;
              break;
            case 'number':
              ccCopy.number = controller.text;
              break;
            case 'month':
              ccCopy.month = controller.text;
              break;
            case 'year':
              ccCopy.year = controller.text;
              break;
            case 'cvv':
              ccCopy.cvv = controller.text;
              break;
            case 'zip':
              ccCopy.zip = controller.text;
              break;
            default:
          }
        },
        decoration: InputDecoration(
          labelStyle: TextStyle(
            color: required ? Colors.black54 : Colors.black26,
          ),
          labelText: placeholder,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget showCircularProgress() {
    return isUploading
        ? Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Uploading...",
                    style: TextStyle(fontSize: 30),
                  ),
                  Container(
                    height: 20.0,
                  ),
                  Center(child: CircularProgressIndicator())
                ]),
          )
        : Container(
            height: 0.0,
            width: 0.0,
          );
  }

  void save() async {
    setState(() {
      isUploading = true;
    });

    //ccCopy.number.replaceAll(new RegExp(r'-'), '');

    Future userCC = Firestore.instance
        .collection('users')
        .document(widget.creditCard.userID)
        .updateData({
      'cc': ccCopy.toMap(),
    });

    Navigator.of(context).pop(true);
  }

  Future<bool> onWillPop() async {
    if (widget.creditCard.compare(ccCopy)) return true;

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                'Discard changes?',
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Discard'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        true); // Returning true to _onWillPop will pop again.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class MaskedTextInputFormatter extends TextInputFormatter {
  final String mask;
  final String separator;

  MaskedTextInputFormatter({
    @required this.mask,
    @required this.separator,
  }) {
    assert(mask != null);
    assert(separator != null);
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length > 0) {
      if (newValue.text.length > oldValue.text.length) {
        if (newValue.text.length > mask.length) return oldValue;
        if (newValue.text.length < mask.length &&
            mask[newValue.text.length - 1] == separator) {
          return TextEditingValue(
            text:
                '${oldValue.text}$separator${newValue.text.substring(newValue.text.length - 1)}',
            selection: TextSelection.collapsed(
              offset: newValue.selection.end + 1,
            ),
          );
        }
      }
    }
    return newValue;
  }
}
