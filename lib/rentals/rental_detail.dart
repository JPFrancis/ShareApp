import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/database.dart';
import 'package:shareapp/services/functions.dart';
import 'package:shareapp/services/payment_service.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

enum Status {
  requested,
  accepted,
  active,
  returned,
  completed,
}

enum EndRentalType {
  cancel,
  decline,
}

class RentalDetail extends StatefulWidget {
  static const routeName = '/itemRental';

  RentalDetail({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RentalDetailState();
  }
}

class RentalDetailState extends State<RentalDetail> {
  CurrentUser currentUser;
  Rental rental;
  bool isLoading = false;
  bool rentalExists = true;
  bool isRenter;
  String otherUserId;
  bool stripeInit;

  TextStyle style;
  double padding = 5.0;

  TextEditingController reviewController = TextEditingController();

  double communicationRating;
  double itemQualityRating;
  double overallExpRating;
  double renterRating;

  @override
  void initState() {
    super.initState();

    currentUser = CurrentUser.getModel(context);
    rental = Rental.getModel(context);
    stripeInit = false;
    communicationRating = 0.0;
    itemQualityRating = 0.0;
    overallExpRating = 0.0;
    renterRating = 0.0;

    String ownerId = rental.ownerRef.documentID;
    String renterId = rental.renterRef.documentID;
    isRenter = currentUser.id == renterId;
    otherUserId = isRenter ? ownerId : renterId;
  }

  @override
  Widget build(BuildContext context) {
    style = new TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5);

    return isLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            backgroundColor: coolerWhite,
            body: showBody(),
            floatingActionButton: Container(
              padding: const EdgeInsets.only(top: 120.0, left: 5.0),
              child: FloatingActionButton(
                onPressed: () => Navigator.pop(context),
                child: Icon(Icons.close),
                elevation: 1,
                backgroundColor: Colors.white70,
                foregroundColor: primaryColor,
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.miniStartTop,
          );
  }

  Widget chatButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(Chat.routeName,
                arguments: ChatArgs(otherUserId, currentUser));
          },
          child: Row(
            children: <Widget>[
              Text("Chat",
                  style: TextStyle(
                      fontFamily: appFont,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400)),
              SizedBox(
                width: 5.0,
              ),
              Icon(Icons.chat_bubble_outline)
            ],
          )),
    );
  }

  Widget showBody() {
    if (rentalExists) {
      return buildRentalDetails();
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'This proposed rental pick-up time was declined by the item owner',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            RaisedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go back'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildRentalDetails() {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB().getRentalStream(rental.id),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          setState(() {
            rentalExists = false;
          });

          return Text('${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          default:
            if (snapshot.hasData) {
              if (!snapshot.data.exists) {
                setState(() {
                  rentalExists = false;
                });

                return Container();
              }

              rental.updateData(snapshot.data);

              DateTime now = DateTime.now();

              if (now.isAfter(rental.pickupStart) &&
                  now.isBefore(rental.rentalEnd)) {
                updateStatus(3);
              }

              if (now.isAfter(rental.rentalEnd)) {
                updateStatus(4);
              }

              return ListView(
                padding: EdgeInsets.all(0),
                children: <Widget>[
                  showItemImage(),
                  showItemCreator(),
                  SizedBox(height: 20.0,),
                  Container(padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 25), child: showItemRequestStatus()),
                  divider(),
                  showRequestButtons(),
                  //showReceiveItemButton(),
                  //showReturnedItemButton(),
                  showReview(),
                  //paymentButtonTEST(),
                ],
              );
            } else {
              return Container();
            }
        }
      },
    );
  }

//    DocumentSnapshot userSnap = await Firestore.instance.collection('users').document(myUserId).get();
//
//    if (userSnap['custId']=='new') {
//      HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
//        functionName: 'createCustomer',
//      );
//
//      final HttpsCallableResult result = await callable.call(
//        <String, dynamic>{
//          userSnap['']
//        },
//      );
//    }

  Widget showItemImage() {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double height = MediaQuery.of(context).size.height - statusBarHeight;
    double width = MediaQuery.of(context).size.width;

    _getItemImage(BuildContext context) {
      return Stack(
        children: <Widget>[
          Container(
            width: width,
            height: width,
            child: FittedBox(
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                imageUrl: rental.itemAvatar,
                placeholder: (context, url) => CircularProgressIndicator(),
              ),
            ),
          ),
          rental.status < 3 && DateTime.now().isBefore(rental.pickupStart)
              ? Positioned(
                  top: statusBarHeight,
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: primaryColor,
                    ),
                    onSelected: (value) {
                      if (value == 'cancel') {
                        removeRentalWarning(EndRentalType.cancel);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(
                        value: 'cancel',
                        child: Text('Cancel Rental'),
                      ),
                    ],
                  ),
                )
              : Container(),
        ],
      );
    }

    return rental.itemAvatar != null
        ? Container(
            height: width / 1,
            width: width / 1,
            child: FittedBox(child: _getItemImage(context), fit: BoxFit.cover),
          )
        : Text('No images yet\n');
  }

  Future<bool> removeRentalWarning(EndRentalType warning) async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    String text = '';
    var action;

    switch (warning) {
      case EndRentalType.decline:
        text = 'Decline rental?';
        action = () => endRental(EndRentalType.decline);

        break;
      case EndRentalType.cancel:
        text = 'Cancel rental?';
        action = () => endRental(EndRentalType.cancel);

        break;
    }

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Warning'),
              content: Text(
                text,
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('CLOSE'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('PROCEED'),
                  onPressed: () => action(),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void endRental(EndRentalType type) async {
    Navigator.of(context).pop(false);

    setState(() {
      isLoading = true;
    });

    if (rental.status < 2) {
      return endAndSendNotification(type);
    }

    DateTime now = DateTime.now();
    DateTime twoDaysFromNow = now.add(Duration(days: 2));

    // refund, but can cancel for free - no charge needed
    if (rental.status == 3 && twoDaysFromNow.isBefore(rental.pickupStart)) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    showToast('An error occurred');

    Navigator.of(context).pop();
  }

  void endAndSendNotification(EndRentalType type) async {
    bool declinedStatus;
    String declinedText;

    switch (type) {
      case EndRentalType.cancel:
        declinedStatus = false;
        declinedText = 'cancelled';
        break;
      case EndRentalType.decline:
        declinedStatus = true;
        declinedText = 'declined';
        break;
    }

    await Firestore.instance
        .collection('rentals')
        .document(rental.id)
        .updateData({
      'status': 5,
      'requesting': false,
      'declined': declinedStatus,
      'lastUpdateTime': DateTime.now()
    });

    DocumentSnapshot otherUserDS = await Firestore.instance
        .collection('users')
        .document(otherUserId)
        .get();

    if (otherUserDS != null && otherUserDS.exists) {
      await Firestore.instance.collection('notifications').add({
        'title': '${currentUser.name} has $declinedText rental',
        'body': 'Item: ${rental.itemName}',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rental.id,
        'timestamp': DateTime.now(),
      });
    }

    setState(() {
      isLoading = false;
    });

    showToast('Rental successfully $declinedText');

    Navigator.of(context).pop();
  }

  Widget showItemCreator() {
    String name = '${rental.ownerName}'.trim();
    String firstName = name.split(' ')[0];

    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            rental.itemName,
            style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 25.0,
                fontWeight: FontWeight.bold),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                height: 50.0,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: rental.ownerAvatar,
                    placeholder: (context, url) =>
                        new CircularProgressIndicator(),
                  ),
                ),
              ),
              Text(firstName, style: TextStyle(color: Colors.black, fontSize: 15.0, fontFamily: 'Quicksand'), textAlign: TextAlign.left,),
              chatButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget showItemName() {
    String itemOwner = 'Item owner: ${rental.ownerName}';
    String itemRenter = 'Item renter: ${rental.renterName}';
    String you = ' (You)';

    isRenter ? itemRenter += you : itemOwner += you;

    return Container(
      child: Text(
        'Item name: ${rental.itemName}\n'
        '$itemOwner\n'
        '$itemRenter',
        style: TextStyle(
          fontSize: 20,
        ),
      ),
    );
  }

  Widget showItemOwner() {
    return Row(
      children: <Widget>[
        Text(
          'Item owner:\n${rental.ownerName}',
          style: TextStyle(color: Colors.black, fontSize: 20.0),
          textAlign: TextAlign.left,
        ),
        Expanded(
          child: Container(
            height: 50,
            child: CachedNetworkImage(
              //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              imageUrl: rental.ownerAvatar,
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget showItemRequestStatus() {
    String start =
        DateFormat('h:mm a on d MMM yyyy').format(rental.pickupStart);
    String end = DateFormat('h:mm a on d MMM yyyy').format(rental.rentalEnd);
    double price = rental.price * rental.duration.toDouble();
    String duration =
        '${rental.duration > 1 ? '${rental.duration} days' : '${rental.duration} day'}';

    double itemPrice = rental.price.toDouble();
    double itemRentalPrice = itemPrice * rental.duration;
    double taxPrice = itemRentalPrice * 0.06;
    double ourFeePrice = itemRentalPrice * 0.07;
    double subtotal = itemRentalPrice + taxPrice + ourFeePrice;
    double total = subtotal * 1.029 + 0.3;
    double stripeFeePrice = subtotal * 0.029 + 0.3;

    Widget receipt = isRenter 
    ? Container(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Text('Item rental:', style:style)),
          Text('\$${itemRentalPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style:style),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Text('Government\'s cut:', textAlign: TextAlign.left, style:style)),
          Text('\$${taxPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 11.5)),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Text('Transaction fee (Not us):', textAlign: TextAlign.left, style:style)),
          Text('\$${stripeFeePrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 11.5)),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Text('Cost to keep our lights on:', textAlign: TextAlign.left, style:style)),
          Text('\$${ourFeePrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 11.5)),
        ],),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Divider(),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Align(alignment: Alignment.centerLeft, child: Text('Total:', textAlign: TextAlign.left, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5, fontWeight: FontWeight.bold))),
          Text('\$${total.toStringAsFixed(2)}', textAlign: TextAlign.right, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5, fontWeight: FontWeight.bold)),
        ],)
      ],))
    : Container(child: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Divider(),
        ),        
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Text('Total Payout To You:', textAlign: TextAlign.left, style: TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5, fontWeight: FontWeight.bold)),
            Text('\$${itemRentalPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style:TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5, fontWeight: FontWeight.bold))
          ],),
      ],
    ));

    Widget info;

    switch (rental.status) {
      case 0: //requested, renter has sent request
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "Waiting for response from ${rental.ownerName}",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "The Receipt",
                    style: style
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                            
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "${rental.renterName} has proposed a pickup!",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "Proposal",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style,
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 1: // requested, renter need to accept/decline pickup window
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "${rental.ownerName} has proposed a new pickup!",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "New proposal",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style,
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "Waiting for response from ${rental.renterName}",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "Proposal",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style,
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 2: // accepted
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "${rental.ownerName} has accepted your request! Make sure to pick it up on time!",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "Transaction Details",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style,
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                  receipt,
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "You have accepted ${rental.renterName}'s request! Be prepared for their pickup!",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "Transaction Details",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style: style,
                      ),
                      Text(
                        "$start",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                  receipt,
                ],
              );
        break;

      case 3: // active
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "You are currently renting the item!",
                    style: style,
                  ),
                  Text(
                    "Transaction Details",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Return Time:",
                        style: style,
                      ),
                      Text(
                        "$end",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                  receipt,
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "${rental.renterName} has your item!",
                    style: TextStyle(fontFamily: appFont, color: primaryColor),
                  ),
                  Text(
                    "Transaction Details",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Return Time:",
                        style: style,
                      ),
                      Text(
                        "$end",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                  receipt,
                ],
              );
        break;

      case 4: // returned
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text( "You have returned the item.", style: style,),
                  Text( "Transaction Details", style: style,),
                  Divider(),
                  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Text( "Returned On:", style: style,),
                      Text( "$end", style: style,),
                    ],
                  ),
                  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Text( "Rented for: ", style: style,),
                      Text( "$duration", style: style,),
                    ],
                  ),
                  receipt,
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "Your item has been returned to you.",
                    style: style,
                  ),
                  Text(
                    "Transaction Details",
                    style: style,
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[ Text(
                        "Returned On:",
                        style: style,
                      ),
                      Text(
                        "$end",
                        style: style,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Rented for:",
                        style: style,
                      ),
                      Text(
                        "$duration",
                        style: style,
                      ),
                    ],
                  ),
                  receipt,
                ],
              );
        break;

      case 5: // declined or cancelled
        var declined = rental.declined;
        String declinedText = '';

        if (declined != null) {
          declinedText = rental.declined
              ? 'This rental was declined'
              : 'This rental was cancelled';
        }

        info = Column(
          children: <Widget>[
            Text(
              declinedText,
              style: TextStyle(fontFamily: appFont, color: primaryColor),
            ),
          ],
        );
        break;

      default:
        info = Container();
        break;
    }

    if ((isRenter && rental.renterReviewSubmitted) ||
        (!isRenter && rental.ownerReviewSubmitted)) {
      info = Column(
        children: <Widget>[
          Text(
            "The transaction is complete.",
            style: style,
          ),
          Text(
            "Transaction Details",
            style: style,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Rented Out On:",
                style: style,
              ),
              Text(
                "$start",
                style: style,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Returned On:",
                style: style,
              ),
              Text(
                "$end",
                style: style,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Rented for:",
                style: style,
              ),
              Text(
                "$duration",
                style: style,
              ),
            ],
          ),
          receipt,
        ],
      );
    }

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          border: Border.all(
            color: primaryColor,
            width: 0.5,
          ),
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
                color: Colors.grey,
                blurRadius: 0.5,
                blurStyle: BlurStyle.outer),
          ],
        ),
        child: Container(
          width: 300.0,
          padding: EdgeInsets.all(10), child: info)
        //Text(statusMessage, style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: appFont)),
        );
  }

  void handleAcceptedRental() async {
    setState(() {
      isLoading = true;
    });

    dynamic value = await DB().checkAcceptRental(rental).catchError((e) {
      setState(() {
        showToast(e.toString());
        isLoading = false;
      });
    });

    if (value != null && value is int && value == 0) {
      updateStatus(2);

      DocumentSnapshot otherUserDS = await Firestore.instance
          .collection('users')
          .document(otherUserId)
          .get();

      await Future.delayed(Duration(milliseconds: 500));

      Firestore.instance.collection('notifications').add({
        'title': '${currentUser.name} accepted your pickup window',
        'body': 'Item: ${rental.itemName}',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rental.id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }).then((_) async {
        var duration = rental.duration;
        var price = rental.price;
        double itemPrice = (duration * price).toDouble();
        double tax = itemPrice * 0.06;
        double ourFee = itemPrice * 0.07;
        double baseChargeAmount = (itemPrice + tax + ourFee) * 1.029 + 0.3;
        int finalCharge = (baseChargeAmount * 100).round();

        var snap = await Firestore.instance
            .collection('users')
            .document(rental.ownerRef.documentID)
            .get();

        Map transferData = {
          'ourFee': ourFee * 100,
          'ownerPayout': itemPrice * 100,
          'connectedAcctId': snap['connectedAcctId'],
        };

        DocumentReference ref;

        if (isRenter) {
          ref = rental.ownerRef;
        } else {
          ref = rental.renterRef;
        }

        snap = await ref.get();

        Map myData = {
          'name': currentUser.name,
          'avatar': currentUser.avatar,
        };

        Map otherUserData = {
          'name': snap['name'],
          'avatar': snap['avatar'],
        };

        Map owner = {};
        Map renter = {};

        if (isRenter) {
          owner = {}..addAll(otherUserData);
          renter = {}..addAll(myData);
        } else {
          owner = {}..addAll(myData);
          renter = {}..addAll(otherUserData);
        }

        Map userData = {
          'owner': {}..addAll(owner),
          'renter': {}..addAll(renter),
        };

        PaymentService().chargeRental(
            rental.id,
            rental.duration,
            Timestamp.fromDate(rental.pickupStart),
            Timestamp.fromDate(rental.rentalEnd),
            rental.renterRef.documentID,
            rental.ownerRef.documentID,
            finalCharge,
            transferData,
            '${rental.renterName} paying ${rental.ownerName} '
            'for renting ${rental.itemName}',
            userData);

        setState(() {
          isLoading = false;
        });
      });
    }
  }

  Widget showRequestButtons() {
    return ((isRenter && rental.status == 1) ||
                (!isRenter && rental.status == 0)) &&
            DateTime.now().isBefore(rental.pickupStart)
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: reusableButton('Accept', primaryColor, () {handleAcceptedRental(); }),),
                  Container(width: 10,),
                  Expanded(child: reusableButton('Propose new time', Color(0xfffa9200),  newPickupProposal),),
                  Container(width: 10,),
                  Expanded(child: reusableButton('Decline', Color(0xffff6961), () => removeRentalWarning(EndRentalType.decline)),),
                ],),
              ],
            ),
          )
        : Container();
  }

  Widget reusableButton(String text, Color color, action) {
    return ButtonTheme(
      height: 60,
      child: RaisedButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(10.0)),
        color: color,
        textColor: Colors.white,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        onPressed: () {
          action();
        },
      ),
    );
  }

  Widget showReceiveItemButton() {
    return rental.status == 2
        ? Container(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                "Simulate start of rental",
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                updateStatus(3);
              },
            ),
          )
        : Container();
  }

  Widget showReturnedItemButton() {
    return rental.status == 3
        ? Container(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                'I have the item! (charge)',
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {},
            ),
          )
        : Container();
  }

  Widget showReview() {
    if (isRenter && rental.status == 4) {
      if (rental.ownerReviewSubmitted) {
        return Container(padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 25), child: showCompletedReview());
      } else {
        return Container(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              reusableCategory("REVIEW"),
              SizedBox(height: 5.0,),
              starRating('How was the communication?', 1),
              starRating('How was the quality of the item?', 2),
              starRating('How was your overall experience?', 3),
              showWriteReviewTextBox(),
              Align(
                alignment: AlignmentDirectional(0, 0),
                child: showSubmitReviewButton(),
              ),
            ],
          ),
        );
      }
    } else if (!isRenter && rental.status == 4) {
      if (rental.renterReviewSubmitted != null) {
        return Container(padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 25), child: showCompletedReview());
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            starRating('Leave a rating for the renter', 4),
            showWriteReviewTextBox(),
            Align(
              alignment: AlignmentDirectional(0, 0),
              child: showSubmitReviewButton(),
            ),
          ],
        );
      }
    } else {
      return Container();
    }
  }

  Widget showCompletedReview() {
    if (isRenter && !rental.renterReviewSubmitted || !isRenter && !rental.ownerReviewSubmitted) {
      return Container();
    }
    Widget info = isRenter
    ? new Column(children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Communication:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
          Text((rental.ownerReviewCommunication).toInt().toString(), style: TextStyle(color: primaryColor, fontFamily: appFont),),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Item Quality:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
          Text((rental.ownerReviewItemQuality).toInt().toString(), style: TextStyle(color: primaryColor, fontFamily: appFont),),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Overall Experience:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
          Text((rental.ownerReviewOverall).toInt().toString(), style: TextStyle(color: primaryColor, fontFamily: appFont),),
        ],),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Review Note:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
            Flexible(child: Text("${rental.ownerReviewNote}", style: TextStyle(color: primaryColor, fontFamily: appFont), textAlign: TextAlign.end,)),        ],),
      ])
    : new Column(children: <Widget>[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Rating:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
          Text((renterRating).toInt().toString(), style: TextStyle(color: primaryColor, fontFamily: appFont),),
        ],),
        Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text("Review Note:", style: TextStyle(color: primaryColor, fontFamily: appFont),),
          Flexible(child: Text("${rental.renterReviewNote}", style: TextStyle(color: primaryColor, fontFamily: appFont), textAlign: TextAlign.end,)),
        ],),
      ]);

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          border: Border.all(
            color: primaryColor,
            width: 0.5,
          ),
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
                color: Colors.grey,
                blurRadius: 0.5,
                blurStyle: BlurStyle.outer),
          ],
        ),
        child: Container(
          width: 300.0,
          padding: EdgeInsets.all(10), 
          child: info,)
        //Text(statusMessage, style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: appFont)),
        );
  }

  double getRating(int indicator) {
    switch (indicator) {
      case 1:
        return communicationRating;
        break;
      case 2:
        return itemQualityRating;
        break;
      case 3:
        return overallExpRating;
        break;
      case 4:
        return renterRating;
        break;
      default:
        return 0.0;
        break;
    }
  }

  Widget starRating(String text, int indicator) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(text, style: TextStyle(fontSize: 18, fontFamily: appFont,)),
          SmoothStarRating(
            allowHalfRating: false,
            onRatingChanged: (double value) {
              switch (indicator) {
                case 1:
                  communicationRating = value;
                  debugPrint('Communication: $communicationRating');
                  break;
                case 2:
                  itemQualityRating = value;
                  debugPrint('item quality: $itemQualityRating');
                  break;
                case 3:
                  overallExpRating = value;
                  debugPrint('overal exp: $overallExpRating');
                  break;
                case 4:
                  renterRating = value;
                  debugPrint('renter rating: $renterRating');
                  break;
              }

              setState(() {});
            },
            starCount: 5,
            rating: getRating(indicator),
            size: 35.0,
            color: Colors.yellow[800],
            borderColor: Colors.black,
            spacing: 1,
          )
        ],
      ),
    );
  }

  Widget showWriteReviewTextBox() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        maxLines: 3,
        controller: reviewController,
        style: style,
        decoration: InputDecoration(
          labelText: 'Write review',
          filled: true,
        ),
      ),
    );
  }

  Widget showSubmitReviewButton() {
    return RaisedButton(
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(5.0)),
      color: primaryColor,
      textColor: Colors.white,
      child: Text('Submit Review', textScaleFactor: 1.25, style: TextStyle(fontFamily: appFont),),
      onPressed: () {
        updateReview();
      },
    );
  }

  void updateStatus(int status) async {
    bool requesting = status == 2 ? false : rental.requesting;
    var lastUpdateTime = status == 2 ? DateTime.now() : rental.lastUpdateTime;

    Firestore.instance.collection('rentals').document(rental.id).updateData({
      'status': status,
      'requesting': requesting,
      'lastUpdateTime': lastUpdateTime,
    });
  }

  void newPickupProposal() async {
    Navigator.pushNamed(
      context,
      NewPickup.routeName,
      arguments: NewPickupArgs(rental.id, isRenter, currentUser),
    );
  }

  void updateReview() async {
    setState(() {
      isLoading = true;
    });

    if ((isRenter &&
            communicationRating > 0 &&
            itemQualityRating > 0 &&
            overallExpRating > 0) ||
        (!isRenter && renterRating > 0)) {
      submitReview(
          isRenter,
          currentUser.id,
          rental,
          reviewController.text,
          communicationRating,
          itemQualityRating,
          overallExpRating,
          renterRating);

//        DocumentSnapshot otherUserDS = await Firestore.instance
//            .collection('users')
//            .document(otherUserId)
//            .get();
//
//        await Firestore.instance.collection('notifications').add({
//          'title': '$myName left you a review',
//          'body': '',
//          'pushToken': otherUserDS['pushToken'],
//          'rentalID': rentalDS.documentID,
//          'timestamp': DateTime.now().millisecondsSinceEpoch,
//        });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> deleteRentalDialog() async {
    final ThemeData theme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete rental?'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    deleteRental();
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void deleteRental() async {
    int delay = 500;

    setState(() {
      isLoading = true;
    });

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance.collection('rentals').document(rental.id).delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('items')
        .document(rental.itemRef.documentID)
        .updateData({'rental': null});

    goToLastScreen();
  }

  void goToLastScreen() {
    Navigator.pop(context);
    /*
    Navigator.popUntil(
      context,
      ModalRoute.withName('/'),
    );
    */
  }
} 