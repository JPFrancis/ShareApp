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
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/services/const.dart';
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
  final String rentalID;

  RentalDetail({Key key, this.rentalID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RentalDetailState();
  }
}

class RentalDetailState extends State<RentalDetail> {
  CurrentUser currentUser;
  String myUserId;
  String url;
  String rentalCC;
  bool isLoading = true;
  bool rentalExists = true;
  bool isRenter;
  bool stripeInit;

  DocumentSnapshot rentalDS;
  String itemId;
  String ownerId;
  String renterId;
  String otherUserId;
  int status = -1;

  TextStyle textStyle;
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
    stripeInit = false;
    communicationRating = 0.0;
    itemQualityRating = 0.0;
    overallExpRating = 0.0;
    renterRating = 0.0;

    getMyUserID();
    //delayPage();
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void getMyUserID() async {
    var user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      myUserId = user.uid;

      getSnapshots();
    }
  }

  void getSnapshots() async {
    DocumentReference dr;
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    if (!ds.exists) {
      setState(() {
        rentalExists = false;
        isLoading = false;
      });

      return;
    }

    if (ds != null) {
      rentalDS = ds;

      DocumentReference itemRef = rentalDS['item'];
      DocumentReference ownerRef = rentalDS['owner'];
      DocumentReference renterRef = rentalDS['renter'];

      itemId = itemRef.documentID;
      ownerId = ownerRef.documentID;
      renterId = renterRef.documentID;

      isRenter = myUserId == renterId ? true : false;
      otherUserId = isRenter ? ownerId : renterId;

      delayPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    textStyle = Theme.of(context).textTheme.title;

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

  Future<DocumentSnapshot> getRentalFromFirestore() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(rentalDS.documentID)
        .get();

    return ds;
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
      stream: rentalDS.reference.snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return new Text('${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          default:
            if (snapshot.hasData) {
              if (!snapshot.data.exists) {
                return Container();
              }

              rentalDS = snapshot.data;
              status = rentalDS['status'];

              DateTime now = DateTime.now();
              //DateTime now = DateTime(2019, 7, 16, 6,30);
              DateTime pickupStart = rentalDS['pickupStart'].toDate();
              DateTime pickupEnd = rentalDS['pickupEnd'].toDate();
              DateTime rentalEnd = rentalDS['rentalEnd'].toDate();
              DateTime created = rentalDS['created'].toDate();

              if (now.isAfter(pickupStart) && now.isBefore(rentalEnd)) {
                updateStatus(3);
              }

              if (now.isAfter(rentalEnd)) {
                updateStatus(4);
              }

              return ListView(
                padding: EdgeInsets.all(0),
                children: <Widget>[
                  showItemImage(),
                  showItemCreator(),
//                  Container(
//                    padding: EdgeInsets.symmetric(horizontal: 15),
//                    child: RaisedButton(
//                      onPressed: () async {
//                        var duration = rentalDS['duration'].toInt();
//                        var price = rentalDS['price'].toInt();
//                        double itemPrice = (duration * price).toDouble();
//                        double tax = itemPrice * 0.06;
//                        double ourFee = itemPrice * 0.07;
//                        double baseChargeAmount =
//                            (itemPrice + tax + ourFee) * 1.029 + 0.3;
//                        int finalCharge = (baseChargeAmount * 100).round();
//
//                        Map transferData = {
//                          'ourFee': ourFee * 100,
//                          'ownerPayout': itemPrice * 100,
//                        };
//
//                        PaymentService().createSubscription(
//                          rentalDS.documentID,
//                          rentalDS['duration'],
//                          rentalDS['pickupStart'],
//                          rentalDS['rentalEnd'],
//                          renterId,
//                          ownerId,
//                          finalCharge,
//                          transferData,
//                          '${rentalDS['renterData']['name']} paying ${rentalDS['ownerData']['name']} '
//                          'for renting ${rentalDS['itemName']}',
//                        );
//                      },
//                      textColor: Colors.white,
//                      color: Colors.green,
//                      child: Text('Charge'),
//                    ),
//                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width / 25),
                      child: showItemRequestStatus()),
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
    String imageUrl = rentalDS['itemAvatar'];

    _getItemImage(BuildContext context) {
      return Stack(
        children: <Widget>[
          Container(
            width: width,
            height: width,
            child: FittedBox(
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => CircularProgressIndicator(),
              ),
            ),
          ),
          status < 3 &&
                  DateTime.now().isBefore(rentalDS['pickupStart'].toDate())
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

    return imageUrl != null
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

    if (status < 2) {
      endAndSendNotification(type);
      return;
    }

    Timestamp timestamp = rentalDS['pickupStart'];
    DateTime startTime = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime twoDaysFromNow = now.add(Duration(days: 2));

    // refund, but can cancel for free - no charge needed
    if (status == 3 && twoDaysFromNow.isBefore(startTime)) {
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
        .document(rentalDS.documentID)
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
        'body': 'Item: ${rentalDS['itemName']}',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rentalDS.documentID,
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
    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            rentalDS['itemName'],
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
                    imageUrl: rentalDS['ownerData']['avatar'],
                    placeholder: (context, url) =>
                        new CircularProgressIndicator(),
                  ),
                ),
              ),
              Text(
                '${rentalDS['ownerData']['name']}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontFamily: 'Quicksand'),
                textAlign: TextAlign.left,
              ),
              chatButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget showItemName() {
    String itemOwner = 'Item owner: ${rentalDS['ownerData']['name']}';
    String itemRenter = 'Item renter: ${rentalDS['renterData']['name']}';
    String you = ' (You)';

    isRenter ? itemRenter += you : itemOwner += you;

    return Container(
      child: Text(
        'Item name: ${rentalDS['itemName']}\n'
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
          'Item owner:\n${rentalDS['ownerData']['name']}',
          style: TextStyle(color: Colors.black, fontSize: 20.0),
          textAlign: TextAlign.left,
        ),
        Expanded(
          child: Container(
            height: 50,
            child: CachedNetworkImage(
              //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              imageUrl: rentalDS['ownerData']['avatar'],
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget showItemRequestStatus() {
   int itemStatus = rentalDS['status'];
    //int itemStatus = 4;
    TextStyle style = new TextStyle(fontFamily: appFont, color: primaryColor, fontSize: 13.5);
    String start = DateFormat('h:mm a on d MMM yyyy').format(rentalDS['pickupStart'].toDate());
    String end = DateFormat('h:mm a on d MMM yyyy').format(rentalDS['rentalEnd'].toDate());
    int durationDays = rentalDS['duration'];
    //double price = rentalDS['price'].toDouble() * durationDays.toDouble();
    String duration = '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

    double itemPrice = rentalDS['price'].toDouble();
    double itemRentalPrice = itemPrice * durationDays;
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

    switch (itemStatus) {
      case 0: //requested, renter has sent request
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "Waiting for response from ${rentalDS['ownerData']['name']}",
                    style: style,
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
                    "${rentalDS['ownerData']['name']} has proposed a pickup!",
                    style: style,
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
                    "${rentalDS['ownerData']['name']} has proposed a new pickup!",
                    style: style,
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
                    "Waiting from response from ${rentalDS['renterData']['name']}",
                    style: style,
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
                    "${rentalDS['ownerData']['name']} has accepted your request! Make sure to pick it up on time!",
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
                    "You have accepted ${rentalDS['renterData']['name']}'s request! Be prepared for their pickup!",
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
                    "${rentalDS['renterData']['name']} has your item!",
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
        var declined = rentalDS['declined'];
        String declinedText = '';

        if (declined != null) {
          declinedText = rentalDS['declined']
              ? 'This rental was declined'
              : 'This rental was cancelled';
        }

        info = Column(
          children: <Widget>[
            Text(
              declinedText,
              style: TextStyle(fontFamily: appFont, color: Colors.white),
            ),
          ],
        );
        break;

      default:
        info = Container();
        break;
    }

    if ((isRenter && rentalDS['rentalReview'] != null) && 
        (!isRenter && rentalDS['ownerReview'] != null)) {
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

    updateStatus(2);

    DocumentSnapshot otherUserDS = await Firestore.instance
        .collection('users')
        .document(otherUserId)
        .get();

    await Future.delayed(Duration(milliseconds: 500));

    Firestore.instance.collection('notifications').add({
      'title': '${currentUser.name} accepted your pickup window',
      'body': 'Item: ${rentalDS['itemName']}',
      'pushToken': otherUserDS['pushToken'],
      'rentalID': rentalDS.documentID,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).then((_) async {
      var duration = rentalDS['duration'].toInt();
      var price = rentalDS['price'].toInt();
      double itemPrice = (duration * price).toDouble();
      double tax = itemPrice * 0.06;
      double ourFee = itemPrice * 0.07;
      double baseChargeAmount = (itemPrice + tax + ourFee) * 1.029 + 0.3;
      int finalCharge = (baseChargeAmount * 100).round();

      var snap =
          await Firestore.instance.collection('users').document(ownerId).get();

      Map transferData = {
        'ourFee': ourFee * 100,
        'ownerPayout': itemPrice * 100,
        'connectedAcctId': snap['connectedAcctId'],
      };

      PaymentService().chargeRental(
        rentalDS.documentID,
        rentalDS['duration'],
        rentalDS['pickupStart'],
        rentalDS['rentalEnd'],
        renterId,
        ownerId,
        finalCharge,
        transferData,
        '${rentalDS['renterData']['name']} paying ${rentalDS['ownerData']['name']} '
        'for renting ${rentalDS['itemName']}',
      );

      setState(() {
        isLoading = false;
      });
    });
  }

  Widget showRequestButtons() {
    return (isRenter && rentalDS['status'] == 1) ||
            (!isRenter && rentalDS['status'] == 0)
        ? Container(
            padding: EdgeInsets.all(15),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: reusableButton('Accept', Colors.green, () {
                        handleAcceptedRental();
                      }),
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: reusableButton('Propose new time',
                          Colors.orange[700], newPickupProposal),
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: reusableButton('Decline', Colors.red[800],
                          () => removeRentalWarning(EndRentalType.decline)),
                    ),
                  ],
                ),
                /*
                Container(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    'Pickup note: ${rentalDS['note']}',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                */
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
            borderRadius: new BorderRadius.circular(5.0)),
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
    return rentalDS['status'] == 2
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
    return rentalDS['status'] == 3
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
    if (isRenter && rentalDS['status'] == 4) {
      if (rentalDS['ownerReview'] != null) {
        return showCompletedReview();
      } else {
        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
    } else if (!isRenter && rentalDS['status'] == 4) {
      if (rentalDS['renterReview'] != null) {
        return showCompletedReview();
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
    Map review = !isRenter ? rentalDS['renterReview'] : rentalDS['ownerReview'];

    if (review == null) {
      return Container();
    }

    var renterRating = review['rating'];
    var communication = review['communication'];
    var itemQuality = review['itemQuality'];
    var overall = review['overall'];
    var reviewNote = review['reviewNote'];

    return Container(
      child: Column(
        children: <Widget>[
          isRenter
              ? Text(
                  'Communication: $communication\n'
                  'Item quality: $itemQuality\n'
                  'Overall experience: $overall\n'
                  'Review note: $reviewNote',
                )
              : Text(
                  'Rating: $renterRating\n'
                  'Review note: $reviewNote',
                ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          text,
          style: TextStyle(fontSize: 18),
        ),
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
        )
      ],
    );
  }

  Widget showWriteReviewTextBox() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        maxLines: 3,
        controller: reviewController,
        style: textStyle,
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
      color: Colors.green,
      textColor: Colors.white,
      child: Text(
        'Submit Review',
        //addButton + " Images",
        textScaleFactor: 1.25,
      ),
      onPressed: () {
        updateReview();
      },
    );
  }

  void updateStatus(int status) async {
    bool requesting = status == 2 ? false : rentalDS['requesting'];
    var lastUpdateTime =
        status == 2 ? DateTime.now() : rentalDS['lastUpdateTime'];

    Firestore.instance
        .collection('rentals')
        .document(rentalDS.documentID)
        .updateData({
      'status': status,
      'requesting': requesting,
      'lastUpdateTime': lastUpdateTime,
    });
  }

  void newPickupProposal() async {
    Navigator.pushNamed(
      context,
      NewPickup.routeName,
      arguments: NewPickupArgs(rentalDS.documentID, isRenter, currentUser),
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
          myUserId,
          rentalDS,
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

    Firestore.instance
        .collection('rentals')
        .document(rentalDS.documentID)
        .delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('items')
        .document(rentalDS['item'].documentID)
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