import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/new_pickup.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:stripe_payment/stripe_payment.dart';

enum Status {
  requested,
  accepted,
  active,
  returned,
  completed,
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
  SharedPreferences prefs;
  String myUserId;
  String myName;
  String url;
  String rentalCC;
  bool isLoading = true;
  bool isRenter;
  bool stripeInit;

  DocumentSnapshot rentalDS;
  DocumentSnapshot itemDS;
  DocumentSnapshot ownerDS;
  DocumentSnapshot renterDS;
  DocumentSnapshot userDS;
  DocumentSnapshot otherUserDS;

  TextStyle textStyle;
  double padding = 5.0;

  TextEditingController reviewController = TextEditingController();

  double communicationRating;
  double itemQualityRating;
  double overallExpRating;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    stripeInit = false;
    communicationRating = 0.0;
    itemQualityRating = 0.0;
    overallExpRating = 0.0;

    getMyUserID();
    getSnapshots();
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
    prefs = await SharedPreferences.getInstance();
    myName = prefs.getString('name') ?? '';
    var user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      myUserId = user.uid;
    }
  }

  void getSnapshots() async {
    DocumentReference dr;
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    if (ds != null) {
      rentalDS = ds;

      dr = rentalDS['owner'];

      ds = await Firestore.instance
          .collection('users')
          .document(dr.documentID)
          .get();

      if (ds != null) {
        ownerDS = ds;

        dr = rentalDS['item'];

        ds = await Firestore.instance
            .collection('items')
            .document(dr.documentID)
            .get();

        if (ds != null) {
          itemDS = ds;

          dr = rentalDS['renter'];

          ds = await Firestore.instance
              .collection('users')
              .document(dr.documentID)
              .get();

          if (ds != null) {
            renterDS = ds;

            if (prefs != null &&
                ownerDS != null &&
                renterDS != null &&
                itemDS != null) {
              isRenter = myUserId == renterDS.documentID ? true : false;
              otherUserDS = isRenter ? ownerDS : renterDS;
              rentalCC = isRenter ? 'renterCC' : 'ownerCC';
              userDS = isRenter ? renterDS : ownerDS;
              delayPage();
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    textStyle = Theme.of(context).textTheme.title;

    return Scaffold(
      backgroundColor: coolerWhite,
      body: isLoading
          ? Container(
              child: Center(child: CircularProgressIndicator()),
            )
          : showBody(),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
    );
  }

  Widget chatButton() {
    return RaisedButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          Chat.routeName,
          arguments: ChatArgs(
            otherUserDS,
          ),
        );
      },
      child: Text('Chat'),
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
              rentalDS = snapshot.data;

              DateTime now = DateTime.now();
              //DateTime now = DateTime(2019, 7, 16, 6,30);
              DateTime pickupStart = rentalDS['pickupStart'].toDate();
              DateTime pickupEnd = rentalDS['pickupEnd'].toDate();
              DateTime rentalEnd = rentalDS['rentalEnd'].toDate();
              DateTime created = rentalDS['created'].toDate();

              if (now.isAfter(pickupStart) && now.isBefore(pickupEnd)) {
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
                  chatButton(),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width / 25),
                      height: MediaQuery.of(context).size.height / 4,
                      child: showItemRequestStatus()),
                  divider(),
                  showRequestButtons(),
                  showCreditCardButton(),
                  showPaymentInfo(),
                  //showReceiveItemButton(),
                  showReturnedItemButton(),
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

  Widget showItemImage() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    var images = itemDS['images'];
    _getItemImage(BuildContext context) {
      return new Container(
        child: FittedBox(
          fit: BoxFit.cover,
          child: CachedNetworkImage(
            imageUrl: images[0],
            placeholder: (context, url) => new CircularProgressIndicator(),
          ),
        ),
      );
    }

    return images.length > 0
        ? Container(
            height: widthOfScreen / 1,
            child: _getItemImage(context),
          )
        : Text('No images yet\n');
  }

  Widget paymentButtonTEST() {
    return RaisedButton(
      onPressed: () {
        PaymentService().chargeRental(
            1.0,
            '${renterDS['name']} paying ${ownerDS['name']} '
            'for renting ${rentalDS['itemName']}');
      },
      child: Text('Charge'),
    );
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
                    imageUrl: ownerDS['avatar'],
                    placeholder: (context, url) =>
                        new CircularProgressIndicator(),
                  ),
                ),
              ),
              Text(
                '${ownerDS['name']}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontFamily: 'Quicksand'),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget showItemName() {
    String itemOwner = 'Item owner: ${ownerDS['name']}';
    String itemRenter = 'Item renter: ${renterDS['name']}';
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
          'Item owner:\n${ownerDS['name']}',
          style: TextStyle(color: Colors.black, fontSize: 20.0),
          textAlign: TextAlign.left,
        ),
        Expanded(
          child: Container(
            height: 50,
            child: CachedNetworkImage(
              //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
              imageUrl: ownerDS['avatar'],
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget showItemRequestStatus() {
    int itemStatus = rentalDS['status'];
    String start = DateFormat('h:mm a on d MMM yyyy')
        .format(rentalDS['pickupStart'].toDate());
    String end = DateFormat('h:mm a on d MMM yyyy')
        .format(rentalDS['rentalEnd'].toDate());
    int durationDays = rentalDS['duration'];
    double price = itemDS['price'].toDouble() * durationDays.toDouble();
    String duration =
        '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

    Widget info;

    switch (itemStatus) {
      case 0: //requested, renter has sent request
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "Waiting for response from ${ownerDS['name']}",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Your proposal",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "${ownerDS['name']} has proposed a pickup!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Proposal",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 1: // requested, renter need to accept/reject pickup window
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "${ownerDS['name']} has proposed a new pickup!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "New proposal",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "Waiting from response from ${renterDS['name']}",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Proposal",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
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
                    "${ownerDS['name']} has accepted your request! Make sure to pick it up on time!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "You have accepted ${renterDS['name']}'s request! Be prepared for their pickup!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Pickup Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$start",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 3: // active
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "You are currently renting the item!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Return Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$end",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "${renterDS['name']} has your item!",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Return Time:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$end",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Duration:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 4: // returned
        info = isRenter
            ? Column(
                children: <Widget>[
                  Text(
                    "You have returned the item.",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Returned On:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$end",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Rented for:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  Text(
                    "Your item has been returned to you.",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Text(
                    "Transaction Details",
                    style: TextStyle(fontFamily: appFont, color: Colors.white),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Returned On:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$end",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Rented for:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "$duration",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total:",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                      Text(
                        "\$$price",
                        style:
                            TextStyle(fontFamily: appFont, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
        break;

      case 5: // completed
        info = Column(
          children: <Widget>[
            Text(
              "The transaction is complete.",
              style: TextStyle(fontFamily: appFont, color: Colors.white),
            ),
            Text(
              "Transaction Details",
              style: TextStyle(fontFamily: appFont, color: Colors.white),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Rented Out On:",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
                Text(
                  "$start",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Returned On:",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
                Text(
                  "$end",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(
                  "Rented for:",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
                Text(
                  "$duration",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Total:",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
                Text(
                  "\$$price",
                  style: TextStyle(fontFamily: appFont, color: Colors.white),
                ),
              ],
            ),
          ],
        );
        break;

      default:
        info = Container();
        break;
    }

    return Container(
        decoration: new BoxDecoration(
          color: primaryColor,
          borderRadius: new BorderRadius.all(Radius.circular(12.0)),
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
                color: Colors.black45,
                blurRadius: 3.0,
                blurStyle: BlurStyle.outer),
          ],
        ),
        child: Container(
            padding: EdgeInsets.all(10),
            child:
                info) //Text(statusMessage, style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: appFont)),
        );
  }

  Widget showRequestButtons() {
    return (isRenter && rentalDS['status'] == 1) ||
            (!isRenter && rentalDS['status'] == 0)
        ? Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: reusableButton('Accept', Colors.green, () {
                        updateStatus(2);
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
                      child: reusableButton('Reject', Colors.red[800], null),
                    ),
                  ],
                ),
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

  Widget showCreditCardButton() {
    return rentalDS['status'] == 2
        ? Container(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                'Confirm payment method',
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                if (!stripeInit) {
                  Firestore.instance
                      .collection('keys')
                      .document('stripe_pk')
                      .get()
                      .then((DocumentSnapshot ds) {
                    StripeSource.setPublishableKey(ds['key']);
                  });

                  stripeInit = true;
                }

                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        title: const Text('Credit Card'),
                        content: Container(
                          height: 175,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: Firestore.instance
                                .collection('users')
                                .document(myUserId)
                                .collection('sources')
                                .limit(1)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasError) {
                                return new Text('${snapshot.error}');
                              }
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return Container();
                                default:
                                  List documents = snapshot.data.documents;
                                  bool hasCard = documents.length > 0;

                                  return Column(
                                    children: <Widget>[
                                      RaisedButton(
                                        shape: new RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(5.0)),
                                        color: Colors.green,
                                        textColor: Colors.white,
                                        child: Text(
                                          'Add card',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        onPressed: hasCard
                                            ? null
                                            : () {
                                                StripeSource.addSource()
                                                    .then((token) {
                                                  PaymentService()
                                                      .addCard(token);
                                                });
                                              },
                                      ),
                                      Text('Or use card on file'),
                                      hasCard
                                          ? ListTile(
                                              leading: Icon(Icons.credit_card),
                                              title: Text(
                                                documents[0]['card']['last4']
                                                    .toString(),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Text(documents[0]
                                                      ['card']['brand']
                                                  .toString()),
                                              onTap: () {
                                                Firestore.instance
                                                    .collection('rentals')
                                                    .document(
                                                        rentalDS.documentID)
                                                    .updateData({
                                                  '$rentalCC': documents[0]
                                                          ['card']['last4']
                                                      .toString()
                                                });
                                                Navigator.pop(context);
                                              },
                                            )
                                          : Text('No cards yet'),
                                    ],
                                  );
                              }
                            },
                          ),
                        ),
                      ),
                ).then<String>((returnVal) {
                  if (returnVal != null) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You clicked: $returnVal'),
                        action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ),
                    );
                  }
                });
              },
            ),

            /*
            RaisedButton(

              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                'Add payment method',
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                navToCreditCard();
                //updateStatus(3);
              },
            ),
    */
          )
        : Container();
  }

  Widget showPaymentInfo() {
    String confirmedCC = rentalDS['$rentalCC'];
    String displayText = confirmedCC == null
        ? 'Payment not confirmed yet'
        : 'Payment confirmed: card ending in $confirmedCC';

    return rentalDS['status'] == 2
        ? Container(
            padding: EdgeInsets.all(5),
            child: Text(
              '${displayText}',
              style: TextStyle(fontSize: 20),
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
              onPressed: () {
                PaymentService().chargeRental(
                    1.0,
                    '${renterDS['name']} paying ${ownerDS['name']} '
                    'for renting ${rentalDS['itemName']}');
              },
            ),
          )
        : Container();
  }

  Widget showReview() {
    return isRenter && rentalDS['status'] == 4
        ? Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                starRating('How was the communication?', 1),
                starRating('How was the quality of the item?', 2),
                starRating('How was your overal experience?', 3),
                showWriteReviewTextBox(),
                Align(
                  alignment: AlignmentDirectional(0, 0),
                  child: showSubmitReviewButton(),
                ),
              ],
            ),
          )
        : Container();
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
        updateStatus(5);
        submitReview();
      },
    );
  }

  void updateStatus(int status) async {
    bool requesting = status == 2 ? false : rentalDS['requesting'];

    Firestore.instance
        .collection('rentals')
        .document(rentalDS.documentID)
        .updateData({'status': status, 'requesting': requesting}).then((_) {
      if (status == 2) {
        Firestore.instance.collection('notifications').add({
          'title': '$myName accepted your pickup window',
          'body': 'Item: ${itemDS['name']}',
          'pushToken': otherUserDS['pushToken'],
          'rentalID': rentalDS.documentID,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  void newPickupProposal() async {
    Navigator.pushNamed(
      context,
      NewPickup.routeName,
      arguments: NewPickupArgs(rentalDS.documentID, isRenter),
    );
  }

  void submitReview() async {
    var review = {
      'communication': communicationRating,
      'itemQuality': itemQualityRating,
      'overall': overallExpRating,
      'reviewNote': reviewController.text
    };

    Firestore.instance
        .collection('rentals')
        .document(rentalDS.documentID)
        .updateData({'review': review}).then((_) {
      Firestore.instance.collection('notifications').add({
        'title': '$myName left you a review',
        'body': '',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rentalDS.documentID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    /// UPDATE USER RATINGS
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
