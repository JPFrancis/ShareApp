import 'package:flutter_picker/flutter_picker.dart';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:shareapp/services/custom_dialog.dart' as customDialog;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/services/const.dart';

double closeButtonSize = 31;

// Reusable Classes

class CustomBoxShadow extends BoxShadow {
  final BlurStyle blurStyle;

  const CustomBoxShadow({
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    this.blurStyle = BlurStyle.normal,
  }) : super(color: color, offset: offset, blurRadius: blurRadius);

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(this.blurStyle, blurSigma);
    assert(() {
      if (debugDisableShadows) result.maskFilter = null;
      return true;
    }());
    return result;
  }
}

class StarRating extends StatelessWidget {
  final int starCount;
  final double rating;
  final Color color;
  final double sz;

  StarRating({this.starCount = 5, this.rating = .0, this.color, this.sz});

  Widget buildStar(BuildContext context, int index, h) {
    Icon icon;
    if (index >= rating) {
      icon = new Icon(
        Icons.star_border,
        color: primaryColor,
        size: sz,
      );
    } else if (index > rating - 1 && index < rating) {
      icon = new Icon(
        Icons.star_half,
        color: primaryColor,
        size: sz,
      );
    } else {
      icon = new Icon(
        Icons.star,
        color: primaryColor,
        size: sz,
      );
    }
    return icon;
  }

  Widget build(BuildContext context) {
    return new Row(
        children: new List.generate(
            starCount, (index) => buildStar(context, index, sz)));
  }
}

class DotsIndicator extends AnimatedWidget {
  DotsIndicator({
    this.controller,
    this.itemCount,
    this.onPageSelected,
    this.color: Colors.white,
  }) : super(listenable: controller);

  /// The PageController that this DotsIndicator is representing.
  final PageController controller;

  /// The number of items managed by the PageController
  final int itemCount;

  /// Called when a dot is tapped
  final ValueChanged<int> onPageSelected;

  /// The color of the dots.
  ///
  /// Defaults to `Colors.white`.
  final Color color;

  // The base size of the dots
  static const double _kDotSize = 8.0;

  // The increase in the size of the selected dot
  static const double _kMaxZoom = 2.0;

  // The distance between the center of each dot
  static const double _kDotSpacing = 25.0;

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((controller.page ?? controller.initialPage) - index).abs(),
      ),
    );
    double zoom = 1.0 + (_kMaxZoom - 1.0) * selectedness;
    return new Container(
      width: _kDotSpacing,
      child: new Center(
        child: new Material(
          color: color,
          type: MaterialType.circle,
          child: new Container(
            width: _kDotSize * zoom,
            height: _kDotSize * zoom,
            child: new InkWell(
              onTap: () => onPageSelected(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: new List<Widget>.generate(itemCount, _buildDot),
    );
  }
}

// Reusable Widgets

Widget itemCard(DocumentSnapshot ds, context) {
  String priceAndDistance = "\$${ds['price']} per day";
  double distance = ds.data['distance'];
  double rating = ds['rating'].toDouble();
  double numRatings = ds['numRatings'].toDouble();

  double itemRating = numRatings == 0 ? 0 : rating / numRatings;

  if (distance != null) {
    distance /= 1.609;
    priceAndDistance += ' | ${distance.toStringAsFixed(1)} miles away';
  }

  var card = new Container(child: new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
    double h = constraints.maxHeight;
    double w = constraints.maxWidth;

    List images = ds['images'];
    var url = '';

    if (images.isNotEmpty) {
      url = images[0];
    }

    return Container(
      height: h,
      width: w,
      decoration: new BoxDecoration(
        boxShadow: <BoxShadow>[
          CustomBoxShadow(
              color: Colors.black45,
              blurRadius: 4.0,
              blurStyle: BlurStyle.outer),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Container(
            height: h,
            width: w,
            child: FittedBox(
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          /*
          Hero(
            tag: "${ds['id']}",
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(ds['images'][0]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          */
          SizedBox.expand(
            child: Container(
              color: Colors.black12,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: h / 3.5,
              width: w,
              padding: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  CustomBoxShadow(
                      color: Colors.black38,
                      blurRadius: 0.1,
                      blurStyle: BlurStyle.outer),
                ],
                color: Color.fromARGB(220, 255, 255, 255),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(ds['name'],
                          style: TextStyle(
                              fontSize: h / 20,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.bold)),
                      Text(
                        '${ds['type']}'.toUpperCase(),
                        style: TextStyle(
                            fontSize: h / 25,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 2.0,
                  ),
                  Text(priceAndDistance,
                      style: TextStyle(
                          fontSize: h / 21,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w400)),
                  SizedBox(
                    height: 2.0,
                  ),
                  Row(
                    children: <Widget>[
                      StarRating(rating: itemRating, sz: h / 15),
                      SizedBox(width: 5.0),
                      Text(
                        ds['numRatings'].toString(),
                        style: TextStyle(
                            fontSize: h / 23,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }));

  return InkWell(
      onTap: () {
        navigateToDetail(ds, context);
      },
      child: card);
}

Widget reusableCategory(text) {
  return Container(
      padding: EdgeInsets.only(left: 15.0, top: 10.0),
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w100)));
}

Widget reusableCategoryWithAll(text, action) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Container(
          padding: EdgeInsets.only(left: 15.0),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Quicksand'))),
      Container(
          child: FlatButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Text(
          "View All",
          style: TextStyle(
              fontSize: 12.0,
              fontFamily: 'Quicksand',
              color: primaryColor,
              fontWeight: FontWeight.w400),
        ),
        onPressed: action,
      )),
    ],
  );
}

Widget reusableFlatButton(text, icon, action) {
  return Column(
    children: <Widget>[
      Container(
        child: FlatButton(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(text,
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 15)),
              Icon(icon)
            ],
          ),
          onPressed: () => action(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          left: 15.0,
          right: 15.0,
        ),
        child: Divider(),
      )
    ],
  );
}

Widget divider() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Divider(),
  );
}

Widget backButton(context) {
  return IconButton(
    alignment: Alignment.topLeft,
    icon: BackButton(),
    onPressed: () => Navigator.pop(context),
  );
}

// helper methods

void navigateToDetail(DocumentSnapshot itemDS, context) async {
  Navigator.pushNamed(
    context,
    ItemDetail.routeName,
    arguments: ItemDetailArgs(
      itemDS,
    ),
  );
}

void delayPage() async {
  await Future.delayed(Duration(milliseconds: 500));
}

// transitions

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
}

String combineID(String myId, String otherId) {
  String groupChatId = '';

  if (myId.hashCode <= otherId.hashCode) {
    groupChatId = '$myId-$otherId';
  } else {
    groupChatId = '$otherId-$myId';
  }

  return groupChatId;
}

Widget searchTile(ds, context) {
  double h = MediaQuery.of(context).size.height;
  double w = MediaQuery.of(context).size.width;
  String milesAway = '';
  double rating = ds['rating'].toDouble();
  double numRatings = ds['numRatings'].toDouble();
  double itemRating = numRatings == 0 ? 0 : rating / numRatings;

  if (ds.data['distance'] != null) {
    double distance = ds.data['distance'];
    distance /= 1.609;
    milesAway = distance.toStringAsFixed(1);
    milesAway += ' mi away';
  }

  return InkWell(
    onTap: () => navigateToDetail(ds, context),
    child: Container(
      width: w,
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 80,
                  width: 80,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: CachedNetworkImage(
                      imageUrl: ds['images'][0],
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10.0,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${ds['name']}',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                        fontSize: h / 45),
                    textAlign: TextAlign.left,
                  ),
                  Row(
                    children: <Widget>[
                      StarRating(rating: itemRating, sz: h / 40),
                      SizedBox(
                        width: 5.0,
                      ),
                      Text(
                        '${ds['numRatings']} reviews',
                        style: TextStyle(
                            fontFamily: 'Quicksand', fontSize: h / 65),
                      ),
                    ],
                  ),
                  Text(
                    '${ds['condition']}',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontStyle: FontStyle.italic,
                        fontSize: h / 65),
                  ),
                  Text(
                    '$milesAway',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontStyle: FontStyle.italic,
                        fontSize: h / 65),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('\$${ds['price']}',
                      style:
                          TextStyle(fontFamily: 'Quicksand', fontSize: h / 55)),
                  Text(' /day',
                      style:
                          TextStyle(fontFamily: 'Quicksand', fontSize: h / 75)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;
    final StringBuffer newText = StringBuffer();
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1) selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
      if (newValue.selection.end >= 3) selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
      if (newValue.selection.end >= 6) selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
      if (newValue.selection.end >= 10) selectionIndex++;
    }

    if (newTextLength >= usedSubstringIndex)
      newText.write(newValue.text.substring(usedSubstringIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

DateTime stripHourMin(DateTime other) {
  return DateTime(other.year, other.month, other.day);
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text?.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class RemoveScrollGlow extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class AddressDialog extends StatefulWidget {
  final double pageHeight;
  final double pageWidth;
  final Map address;

  AddressDialog({
    @required this.pageHeight,
    @required this.pageWidth,
    @required this.address,
  });

  @override
  AddressDialogState createState() => AddressDialogState();
}

class AddressDialogState extends State<AddressDialog> {
  final UpperCaseTextFormatter stateFormatter = UpperCaseTextFormatter();
  Map address;

  TextEditingController streetAddressController = TextEditingController();
  TextEditingController cityAddressController = TextEditingController();
  TextEditingController stateAddressController = TextEditingController();
  TextEditingController zipAddressController = TextEditingController();

  double pageHeight;
  double pageWidth;

  @override
  void initState() {
    super.initState();

    pageHeight = widget.pageHeight;
    pageWidth = widget.pageWidth;
    address = widget.address;

    if (address != null) {
      streetAddressController.text = address['street'];
      cityAddressController.text = address['city'];
      stateAddressController.text = address['state'];
      zipAddressController.text = address['zip'];
    } else {
      streetAddressController.text = '';
      cityAddressController.text = '';
      stateAddressController.text = '';
      zipAddressController.text = '';
    }
  }

  @override
  void dispose() {
    super.dispose();

    streetAddressController.dispose();
    cityAddressController.dispose();
    stateAddressController.dispose();
    zipAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double headerSize = 16.0;
    double fontSize = 16.0;

    return customDialog.AlertDialog(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogBorderRadius),
      ),
      titlePadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: pageWidth * 0.9,
        child: ScrollConfiguration(
          behavior: RemoveScrollGlow(),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: closeButtonSize,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                  ),
                  color: primaryColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: pageWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Address',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(height: pageHeight * 0.02),
                    TextField(
                      controller: streetAddressController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      textAlign: TextAlign.left,
                      cursorColor: primaryColor,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: appFont,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Street',
                        hintStyle: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Container(height: pageHeight * 0.03),
                    TextField(
                      controller: cityAddressController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      textAlign: TextAlign.left,
                      cursorColor: primaryColor,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: appFont,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'City',
                        hintStyle: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Container(height: pageHeight * 0.038),
                    Row(
                      children: <Widget>[
                        Flexible(
                          flex: 1,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'State',
                              hintStyle: TextStyle(
                                fontFamily: appFont,
                                fontWeight: FontWeight.w500,
                              ),
                              contentPadding: EdgeInsets.all(12),
                              border: OutlineInputBorder(),
                            ),
                            controller: stateAddressController,
                            maxLength: 2,
                            inputFormatters: <TextInputFormatter>[
                              stateFormatter,
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                        ),
                        Flexible(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Zip',
                              hintStyle: TextStyle(
                                fontFamily: appFont,
                                fontWeight: FontWeight.w500,
                              ),
                              contentPadding: EdgeInsets.all(12),
                              border: OutlineInputBorder(),
                            ),
                            controller: zipAddressController,
                            maxLength: 5,
                            keyboardType: TextInputType.numberWithOptions(
                              signed: false,
                              decimal: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(height: pageHeight * 0.03),
                    Container(
                      height: pageHeight * 0.073,
                      width: pageWidth * 0.6655,
                      child: RaisedButton(
                        elevation: 0.0,
                        onPressed: () {
                          if (streetAddressController.text.isEmpty) {
                            Fluttertoast.showToast(
                                msg: 'Street name can\'t be empty');
                          } else if (cityAddressController.text.isEmpty) {
                            Fluttertoast.showToast(msg: 'City can\'t be empty');
                          } else if (stateAddressController.text.length != 2) {
                            Fluttertoast.showToast(
                                msg: 'Please enter valid state');
                          } else if (zipAddressController.text.length != 5) {
                            Fluttertoast.showToast(
                                msg: 'Please enter valid zip code');
                          } else {
                            String street = streetAddressController.text.trim();
                            String city = cityAddressController.text.trim();
                            String state = stateAddressController.text.trim();
                            String zip = zipAddressController.text.trim();
                            Map address = {
                              'street': street,
                              'city': city,
                              'state': state,
                              'zip': zip,
                            };

                            Navigator.of(context).pop(address);
                          }
                        },
                        color: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(appBorderRadius),
                        ),
                        child: Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(height: pageHeight * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneNumberDialog extends StatefulWidget {
  final double pageHeight;
  final double pageWidth;
  final String phoneNumber;

  PhoneNumberDialog({
    @required this.pageHeight,
    @required this.pageWidth,
    @required this.phoneNumber,
  });

  @override
  PhoneNumberDialogState createState() => PhoneNumberDialogState();
}

class PhoneNumberDialogState extends State<PhoneNumberDialog> {
  String phoneNumber;

  TextEditingController phoneNumberController = TextEditingController();

  double pageHeight;
  double pageWidth;

  @override
  void initState() {
    super.initState();

    pageHeight = widget.pageHeight;
    pageWidth = widget.pageWidth;
    phoneNumber = widget.phoneNumber;

    if (phoneNumber != null) {
      phoneNumberController.text = phoneNumber;
    } else {
      phoneNumberController.text = '';
    }
  }

  @override
  void dispose() {
    super.dispose();

    phoneNumberController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double headerSize = 16.0;
    double fontSize = 16.0;

    return customDialog.AlertDialog(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogBorderRadius),
      ),
      titlePadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: pageWidth * 0.9,
        child: ScrollConfiguration(
          behavior: RemoveScrollGlow(),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: closeButtonSize,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                  ),
                  color: primaryColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: pageWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(height: pageHeight * 0.02),
                    TextField(
                      controller: phoneNumberController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      textAlign: TextAlign.left,
                      cursorColor: primaryColor,
                      maxLength: 10,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly,
//                        phoneNumberFormatter,
                      ],
                      keyboardType: TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: appFont,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Container(height: pageHeight * 0.03),
                    Container(
                      height: pageHeight * 0.073,
                      width: pageWidth * 0.6655,
                      child: RaisedButton(
                        elevation: 0.0,
                        onPressed: () {
                          if (phoneNumberController.text.length == 10) {
                            Navigator.of(context)
                                .pop(phoneNumberController.text);
                          }
                        },
                        color: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(appBorderRadius),
                        ),
                        child: Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(height: pageHeight * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BirthdayDialog extends StatefulWidget {
  final double pageHeight;
  final double pageWidth;
  final DateTime birthday;

  BirthdayDialog({
    @required this.pageHeight,
    @required this.pageWidth,
    @required this.birthday,
  });

  @override
  BirthdayDialogState createState() => BirthdayDialogState();
}

class BirthdayDialogState extends State<BirthdayDialog> {
  DateTime birthday;
  double pageHeight;
  double pageWidth;
  var datePicker;

  @override
  void initState() {
    super.initState();

    pageHeight = widget.pageHeight;
    pageWidth = widget.pageWidth;
    birthday = widget.birthday;

    if (birthday == null) {
      birthday = DateTime.now();
    }

    datePicker = Picker(
      hideHeader: true,
      adapter: DateTimePickerAdapter(
        type: PickerDateTimeType.kMDY,
        isNumberMonth: false,
        value: birthday,
      ),
      onConfirm: (Picker picker, List<int> value) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    double headerSize = 16.0;
    double fontSize = 16.0;

    return customDialog.AlertDialog(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogBorderRadius),
      ),
      titlePadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: pageWidth * 0.9,
        child: ScrollConfiguration(
          behavior: RemoveScrollGlow(),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.all(0),
                  iconSize: closeButtonSize,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                  ),
                  color: primaryColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: pageWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Birthday',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(height: pageHeight * 0.02),
                    datePicker.makePicker(),
                    Container(height: pageHeight * 0.02),
                    Container(
                      height: pageHeight * 0.073,
                      width: pageWidth * 0.6655,
                      child: RaisedButton(
                        elevation: 0.0,
                        onPressed: () {
                          DateTime date =
                              (datePicker.adapter as DateTimePickerAdapter)
                                  .value;

                          Navigator.of(context).pop(date);
                        },
                        color: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(appBorderRadius),
                        ),
                        child: Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(height: pageHeight * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
