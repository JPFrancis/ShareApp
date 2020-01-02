import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/models/user.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/custom_dialog.dart' as customDialog;
import 'package:shareapp/services/functions.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

import 'database.dart';

double saveButtonBottomPadding = 28;
double saveButtonHeight = 50;

class AddressDialog extends StatefulWidget {
  final double pageWidth;
  final Map address;

  AddressDialog({
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

  double pageWidth;

  @override
  void initState() {
    super.initState();

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
                    Container(height: 12),
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
                    Container(height: 18),
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
                    Container(height: 18),
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
                    Container(height: 18),
                    Container(
                      height: saveButtonHeight,
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
                    Container(height: saveButtonBottomPadding),
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
  final double pageWidth;
  final String phoneNumber;

  PhoneNumberDialog({
    @required this.pageWidth,
    @required this.phoneNumber,
  });

  @override
  PhoneNumberDialogState createState() => PhoneNumberDialogState();
}

class PhoneNumberDialogState extends State<PhoneNumberDialog> {
  String phoneNumber;

  TextEditingController phoneNumberController = TextEditingController();

  double pageWidth;

  @override
  void initState() {
    super.initState();

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
                    Container(height: 12),
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
                    Container(height: 18),
                    Container(
                      height: saveButtonHeight,
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
                    Container(height: saveButtonBottomPadding),
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
  final double pageWidth;
  final DateTime birthday;

  BirthdayDialog({
    @required this.pageWidth,
    @required this.birthday,
  });

  @override
  BirthdayDialogState createState() => BirthdayDialogState();
}

class BirthdayDialogState extends State<BirthdayDialog> {
  DateTime birthday;
  double pageWidth;
  var datePicker;

  @override
  void initState() {
    super.initState();

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
                    Container(height: 12),
                    datePicker.makePicker(),
                    Container(height: 12),
                    Container(
                      height: saveButtonHeight,
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
                    Container(height: saveButtonBottomPadding),
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

class DailyRateDialog extends StatefulWidget {
  final double pageWidth;
  final double rate;

  DailyRateDialog({
    @required this.pageWidth,
    @required this.rate,
  });

  @override
  DailyRateDialogState createState() => DailyRateDialogState();
}

class DailyRateDialogState extends State<DailyRateDialog> {
  double rate;
  double pageWidth;
  TextEditingController rateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pageWidth = widget.pageWidth;
    rate = widget.rate;
    String rateControllerText = '$rate';

    if (rate % 1 == 0) {
      rateControllerText = '${rate.toStringAsFixed(0)}';
    }
    rateController.text = rateControllerText;
  }

  @override
  void dispose() {
    super.dispose();

    rateController.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'New Daily Rate',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(height: 18),
                    TextField(
                      controller: rateController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      textAlign: TextAlign.left,
                      cursorColor: primaryColor,
                      keyboardType: TextInputType.numberWithOptions(
                        signed: false,
                        decimal: true,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: appFont,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Daily Rate',
                        hintStyle: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Container(height: 18),
                    Container(
                      height: saveButtonHeight,
                      width: pageWidth * 0.6655,
                      child: RaisedButton(
                        elevation: 0.0,
                        onPressed: () {
                          if (rateController.text.isNotEmpty) {
                            Navigator.of(context)
                                .pop(double.parse(rateController.text));
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
                    Container(height: saveButtonHeight),
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

class ReviewDialog extends StatefulWidget {
  final String myUserId;
  final bool isRenter;
  final double pageHeight;
  final double pageWidth;

  ReviewDialog({
    @required this.myUserId,
    @required this.isRenter,
    @required this.pageHeight,
    @required this.pageWidth,
  });

  @override
  ReviewDialogState createState() => ReviewDialogState();
}

class ReviewDialogState extends State<ReviewDialog> {
  Rental rental;
  String myUserId;
  bool isRenter;
  double pageHeight;
  double pageWidth;
  String date = '';

  TextEditingController reviewController = TextEditingController();
  String reviewControllerHintText = '';
  String ratingText;

  double communicationRating = 0.0;
  double itemQualityRating = 0.0;
  double overallExpRating = 0.0;
  double renterRating = 0.0;

  @override
  void initState() {
    super.initState();

    rental = Rental.getModel(context);
    myUserId = widget.myUserId;
    isRenter = widget.isRenter;
    pageHeight = widget.pageHeight;
    pageWidth = widget.pageWidth;

    reviewController.text = '';
    reviewControllerHintText = 'Optional';
    DateTime dateTime = rental.pickupStart;
    var dateFormat = DateFormat('E, LLL d');
    date = dateFormat.format(dateTime);

    switch (isRenter) {
      case true:
        ratingText = 'Leave a rating for the owner';

        break;
      case false:
        ratingText = 'Leave a rating for the renter';

        break;
    }
  }

  @override
  void dispose() {
    super.dispose();

    reviewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double dialogBorderRadius = 12.0;
    double headerHeight = pageHeight * 0.2;
    double avatarSize = headerHeight * 0.65;
    double headerIntroPadding = (headerHeight - avatarSize) / 2;
    double dialogWidth = pageWidth * 0.9;
    double contentWidth = dialogWidth * 0.86;

    Widget starRating(String title, int ratingIndex) {
      double rating;

      switch (ratingIndex) {
        case 1:
          rating = communicationRating;
          break;
        case 2:
          rating = itemQualityRating;

          break;
        case 3:
          rating = overallExpRating;
          break;
        case 4:
          rating = renterRating;
          break;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontFamily: appFont,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(height: pageHeight * 0.005),
          SmoothStarRating(
            allowHalfRating: false,
            onRatingChanged: (double value) {
              switch (ratingIndex) {
                case 1:
                  communicationRating = value;
                  break;
                case 2:
                  itemQualityRating = value;
                  break;
                case 3:
                  overallExpRating = value;
                  break;
                case 4:
                  renterRating = value;
                  break;
              }

              setState(() {});
            },
            starCount: 5,
            rating: rating,
            size: 35,
            color: Colors.yellow[700],
            spacing: 1,
            borderColor: Color(0xffCECFD2),
          ),
          Container(height: pageHeight * 0.005),
        ],
      );
    }

    Widget starRatings() {
      return isRenter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                starRating('How was the communication?', 1),
                starRating('How was the quality of the item?', 2),
                starRating('How was your overall experience?', 3),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                starRating('How was the renter?', 4),
              ],
            );
    }

    return customDialog.AlertDialog(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogBorderRadius)),
      titlePadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: dialogWidth,
        child: ScrollConfiguration(
          behavior: RemoveScrollGlow(),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: headerIntroPadding),
                        height: headerHeight,
                        decoration: ShapeDecoration(
                          color: Color(0xffEDEDED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(dialogBorderRadius),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(width: headerIntroPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: rental.itemAvatar,
                                height: avatarSize,
                                width: avatarSize,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Center(child: CircularProgressIndicator()),
                              ),
                            ),
                            Container(width: headerIntroPadding),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: avatarSize * 0.1),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    rental.itemName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    rental.ownerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    ],
                  ),
                  Container(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(height: pageHeight * 0.02),
                        starRatings(),
                        Container(height: pageHeight * 0.02),
                        Container(
                          height: pageHeight * 0.17,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1.0,
                                color: Colors.grey[300],
                              ),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(appBorderRadius)),
                            ),
                          ),
                          child: TextField(
                            controller: reviewController,
                            onChanged: (value) {
                              setState(() {});
                            },
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: appFont,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: reviewControllerHintText,
                              hintStyle: TextStyle(
                                fontSize: 15,
                                fontFamily: appFont,
                                fontWeight: FontWeight.w500,
                              ),
                              contentPadding: EdgeInsets.all(12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Container(height: pageHeight * 0.038),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: saveButtonHeight,
                              width: pageWidth * 0.6655,
                              child: RaisedButton(
                                elevation: 0.0,
                                onPressed: canSubmit()
                                    ? () {
                                        submitReview(
                                                isRenter,
                                                myUserId,
                                                rental,
                                                reviewController.text,
                                                communicationRating,
                                                itemQualityRating,
                                                overallExpRating,
                                                renterRating)
                                            .then((_) {
                                          Navigator.of(context).pop();
                                        });
                                      }
                                    : null,
                                color: primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(appBorderRadius)),
                                child: Text(
                                  'SUBMIT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: appFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(height: saveButtonBottomPadding),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool canSubmit() {
    if (isRenter) {
      return communicationRating == 0 ||
              itemQualityRating == 0 ||
              overallExpRating == 0
          ? false
          : true;
    } else {
      return renterRating == 0 ? false : true;
    }
  }
}

class ReportUserDialog extends StatefulWidget {
  final double pageWidth;
  final String myId;
  final String myName;
  final String offenderId;
  final String offenderName;

  ReportUserDialog({
    @required this.pageWidth,
    @required this.myId,
    @required this.myName,
    @required this.offenderId,
    @required this.offenderName,
  });

  @override
  ReportUserDialogState createState() => ReportUserDialogState();
}

class ReportUserDialogState extends State<ReportUserDialog> {
  double pageWidth;
  TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pageWidth = widget.pageWidth;
  }

  @override
  void dispose() {
    super.dispose();

    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Report User',
                      style: TextStyle(
                        fontFamily: appFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(height: 18),
                    TextField(
                      controller: noteController,
                      textAlign: TextAlign.left,
                      cursorColor: primaryColor,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: appFont,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note',
                        hintStyle: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Container(height: 18),
                    Container(
                      height: saveButtonHeight,
                      width: pageWidth * 0.6655,
                      child: RaisedButton(
                        elevation: 0.0,
                        onPressed: () async {
                          String note = noteController.text.trim();

                          if (note.isEmpty) {
                            showToast('Please leave a note');
                          } else {
                            await Firestore.instance.collection('reports').add({
                              'timestamp': DateTime.now(),
                              'offenderId': widget.offenderId,
                              'offenderName': widget.offenderName,
                              'reporterId': widget.myId,
                              'reporterName': widget.myName,
                              'note': note,
                            });

                            Navigator.of(context).pop(0);
                          }
                        },
                        color: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(appBorderRadius),
                        ),
                        child: Text(
                          'REPORT',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Container(height: saveButtonBottomPadding),
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
