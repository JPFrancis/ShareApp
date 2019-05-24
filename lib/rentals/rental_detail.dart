import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/new_pickup.dart';
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
  GoogleMapController googleMapController;

  SharedPreferences prefs;
  String myUserId;
  String url;
  String rentalCC;
  bool isLoading;
  bool isRenter;
  bool stripeInit;

  DocumentSnapshot rentalDS;
  DocumentSnapshot ownerDS;
  DocumentSnapshot renterDS;
  DocumentSnapshot userDS;
  DocumentSnapshot cardDS;

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
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myUserId = prefs.getString('userID') ?? '';
  }

  void getSnapshots() async {
    isLoading = true;
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

        dr = rentalDS['renter'];

        ds = await Firestore.instance
            .collection('users')
            .document(dr.documentID)
            .get();

        if (ds != null) {
          renterDS = ds;

          ds = await Firestore.instance
              .collection('cards')
              .document(myUserId)
              .get();

          if (ds != null) {
            cardDS = ds;

            if (prefs != null && ownerDS != null && renterDS != null) {
              setState(() {
                isRenter = myUserId == renterDS.documentID ? true : false;
                rentalCC = isRenter ? 'renterCC' : 'ownerCC';
                userDS = isRenter ? renterDS : ownerDS;
                isLoading = false;
              });
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        goToLastScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Item Rental'),
          // back button
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              goToLastScreen();
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Delete rental',
              onPressed: () {
                setState(() {
                  deleteRentalDialog();
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Center(child: CircularProgressIndicator())
                    ]),
              )
            : showBody(),
        floatingActionButton: showFAB(),
      ),
    );
  }

  FloatingActionButton showFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          Chat.routeName,
          arguments: ChatArgs(
            widget.rentalID,
          ),
        );
      },
      tooltip: 'Chat',
      child: Icon(Icons.message),
    );
  }

  Future<DocumentSnapshot> getRentalFromFirestore() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
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

              return Padding(
                padding: EdgeInsets.all(15),
                child: ListView(
                  children: <Widget>[
                    showItemName(),
                    Divider(
                      height: 20,
                    ),
                    showItemRequestStatus(),
                    Container(
                      height: 10,
                    ),
                    showRequestButtons(),
                    showCreditCardButton(),
                    showPaymentInfo(),
                    showReceiveItemButton(),
                    showReturnedItemButton(),
                    showReview(),
                  ],
                ),
              );
            } else {
              return Container();
            }
        }
      },
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
              key: new ValueKey<String>(
                  DateTime.now().millisecondsSinceEpoch.toString()),
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
    String statusMessage;

    String start = DateFormat('h:mm a on EEE, MMM d yyyy')
        .format(rentalDS['pickupStart'].toDate());
    String end = DateFormat('h:mm a on EEE, MMM d yyyy')
        .format(rentalDS['pickupEnd'].toDate());
    int durationDays = rentalDS['duration'];
    String duration =
        '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

    // IF YOU ARE THE RENTER
    if (isRenter) {
      switch (itemStatus) {
        case 0: // requested, renter has sent request
          statusMessage = 'Status: requested (0)\n'
              'Awaiting response from ${ownerDS['name']}\n'
              'Your proposed pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 1: // requested, renter need to accept/reject pickup window
          statusMessage = 'Status: requested (0)\n'
              '${ownerDS['name']} has proposed a pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['name']} has accepted your request\n'
              'Awaiting ${ownerDS['name']} to send item';
          break;
        case 3: // active
          statusMessage = 'Status: active\n'
              'Happy renting your ${rentalDS['itemName']}!\n'
              'Return the item when you are done';
          break;
        case 4: // returned
          statusMessage = 'Status: returned\n'
              '${rentalDS['itemName']} has been returned to you\n'
              'Please write a review of the item';
          break;
        case 5: // completed
          statusMessage = 'Status: completed\n'
              'Rental has been complete!';
          break;
        default:
          statusMessage = 'There was an error with getting status';
          break;
      }
    }

    // IF YOU ARE THE OWNER
    else {
      switch (itemStatus) {
        case 0: // requested, owner needs to accept/reject pickup window
          statusMessage = 'Status: requested (0)\n'
              '${renterDS['name']} has proposed a pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 1: // requested, owner has sent new pickup window
          statusMessage = 'Status: requested (0)\n'
              'Awaiting response from ${renterDS['name']}\n'
              'Your proposed pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['name']} has accepted your request\n'
              'Give the item to ${renterDS['name']}';
          break;
        case 3: // active
          statusMessage = 'Status: active\n'
              '${renterDS['name']} is currently renting your item\n'
              'Press the button when the item has been returned to you to end the rental';
          break;
        case 4: // returned
          statusMessage = 'Status: returned\n'
              'You have returned the item to ${ownerDS['name']}\n'
              'Waiting for ${renterDS['name']} to write a review';
          break;
        case 5: // completed
          statusMessage = 'Status: completed\n'
              'Rental has completed!';
          break;
        default:
          statusMessage = 'There was an error with getting status';
          break;
      }
    }

    return Container(
      child: Text(
        statusMessage,
        style: TextStyle(
          fontSize: 18,
        ),
      ),
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
                                .collection('cards')
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
                                                    .document(widget.rentalID)
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
                'Simulate end of rental',
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                updateStatus(4);
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
    Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .updateData({'status': status});
  }

  void newPickupProposal() async {
    Navigator.pushNamed(
      context,
      NewPickup.routeName,
      arguments: NewPickupArgs(widget.rentalID, isRenter),
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
        .document(widget.rentalID)
        .updateData({'review': review});

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
        .collection('users')
        .document(renterDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('users')
        .document(ownerDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance.collection('rentals').document(widget.rentalID).delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .collection('chat')
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('items')
        .document(rentalDS['item'].documentID)
        .updateData({'rental': null});

    goToLastScreen();
  }

  void goToLastScreen() {
    Navigator.popUntil(
      context,
      ModalRoute.withName('/'),
    );
  }
}
