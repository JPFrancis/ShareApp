import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/payment_service.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum CardTapAction {
  setDefault,
  delete,
}

class PayoutsPage extends StatefulWidget {
  static const routeName = '/payoutsPage';

  PayoutsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PayoutsPageState();
  }
}

class PayoutsPageState extends State<PayoutsPage> {
  String appBarTitle = 'Payments and payouts';
  double padding = 5.0;
  String myUserID;
  String defaultSource = '';
  String stripeCustId = '';

  bool isLoading = true;
  bool stripeInit = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
    FirebaseAuth.instance.currentUser().then((user) {
      myUserID = user.uid;
      delayPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: coolerWhite,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(90),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: Colors.black,
              tabs: [
                Tab(child: Text("Payment Methods")),
                Tab(child: Text("Payout History")),
              ],
            ),
          ),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  showCreditCards(),
                  showPayouts(),
                ],
              ),
      ),
    );
  }

  Widget addCard() {
    double w = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () {
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

        StripeSource.addSource().then((token) {
          PaymentService().addCard(token);
          Fluttertoast.showToast(
              msg: 'Adding card...', toastLength: Toast.LENGTH_LONG);
          setState(() {
            isLoading = true;
          });

          Future.delayed(Duration(seconds: 3)).then((_) {
            setState(() {
              isLoading = false;
            });
          });
        });
      },
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: Radius.circular(15),
            dashPattern: [8, 6],
            child: Container(
              height: w / 1.75,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), color: coolerWhite),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey[400],
                  size: 50,
                ),
              ),
            ),
          )),
    );
  }

  Widget buildCard(DocumentSnapshot creditCardDS) {
    double w = MediaQuery.of(context).size.width;
    Map creditCard = creditCardDS['card'];
    String brand = creditCard['brand'];
    String fingerprint = creditCard['fingerprint'];
    bool isDefault = defaultSource == creditCardDS['id'] ? true : false;

    var colors;
    var imageAsset;

    switch (brand.toUpperCase()) {
      case 'VISA':
        colors = [
          Colors.black,
          Colors.indigo[800],
          Colors.blue,
          Colors.black,
        ];
        imageAsset = Image.asset(
          'assets/visa.png',
          height: 75.0,
          color: Colors.white,
        );
        break;
      case 'MASTERCARD':
        colors = [
          Colors.black,
          Colors.red[800],
          Colors.yellow[800],
          Colors.black,
        ];
        imageAsset = Image.asset(
          'assets/mastercard.png',
          width: 75.0,
        );
        break;
      default:
        colors = [
          Colors.black,
          Colors.black,
          Colors.black,
          Colors.black,
        ];
        break;
    }

    return InkWell(
      onTap: () => handleCardTap(CardTapAction.setDefault, creditCardDS),
      onLongPress: () => handleCardTap(CardTapAction.delete, creditCardDS),
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Container(
              height: w / 1.65,
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  CustomBoxShadow(
                      color: Colors.black,
                      blurRadius: 5.0,
                      blurStyle: BlurStyle.outer),
                ],
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30.0, top: 10.0),
                      child: imageAsset ?? null,
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Row(
                    children: <Widget>[
                      SizedBox(width: 30.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 18.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 18.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(
                        width: 7.0,
                      ),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 7.0),
                      Icon(
                        Icons.brightness_1,
                        color: Colors.white70,
                        size: 8.5,
                      ),
                      SizedBox(width: 18.0),
                      Text(
                        '${creditCardDS['card']['last4']}',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: appFont,
                            fontSize: 17.0,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2.0),
                      ),
                    ],
                  ),
                  SizedBox(height: 60.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${creditCard['name']}',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: appFont,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2.0),
                          ),
                          isDefault
                              ? Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 19,
                                  ),
                                )
                              : Container(),
                          Text(
                            '${creditCard['exp_month']} / ${creditCard['exp_year']}',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: appFont,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }

  Widget showCreditCards() {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
      stream:
          Firestore.instance.collection('users').document(myUserID).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          default:
            DocumentSnapshot ds = snapshot.data;

            if (ds != null && ds.exists) {
              defaultSource = ds['defaultSource'];
              stripeCustId = ds['custId'];
            }

            return StreamBuilder(
              stream: Firestore.instance
                  .collection('users')
                  .document(myUserID)
                  .collection('sources')
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

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: documents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == documents.length) {
                          return Column(
                            children: <Widget>[
                              Container(height: 10),
                              addCard(),
                            ],
                          );
                        } else {
                          return Column(
                            children: <Widget>[
                              Container(height: 10),
                              buildCard(documents[index])
                            ],
                          );
                        }
                      },
                    );
                }
              },
            );
        }
      },
    );
  }

  Widget showPayouts() {
    return Column(
      children: <Widget>[
        buildTransactions("past", "renter"),
        buildTransactions("past", "owner"),
      ],
    );
  }

  Widget buildChargesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('users')
            .document(myUserID)
            .collection('charges')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: new Container(),
              );
            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> docs = snapshot.data.documents;

                return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = docs[index];
                      return ListTile(
                        title: Text(
                          '${ds['amount']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${ds['description']}'),
                      );
                    });
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }

  Widget buildTransactions(String rentalStatus, person) {
    List status;
    switch (rentalStatus) {
      case 'upcoming':
        status = [2];
        break;
      case 'current':
        status = [3, 4];
        break;
      case 'past':
        status = [5];
        break;
    }
    CollectionReference collectionReference =
        Firestore.instance.collection('rentals');
    Stream stream = collectionReference
        .where(person,
            isEqualTo:
                Firestore.instance.collection('users').document(myUserID))
        .snapshots();
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                var updated = snapshot.data.documents
                    .where((d) => status.contains(d['status']))
                    .toList();
                var items = updated.map((rentalDS) {
                  DocumentReference itemDR = rentalDS['item'];

                  return StreamBuilder<DocumentSnapshot>(
                    stream: itemDR.snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return new Text('${snapshot.error}');
                      }
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        default:
                          if (snapshot.hasData) {
                            DocumentSnapshot ds = snapshot.data;

                            return StreamBuilder<DocumentSnapshot>(
                              stream: rentalDS['renter'].snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return new Text('${snapshot.error}');
                                }
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:

                                  default:
                                    if (snapshot.hasData) {
                                      DocumentSnapshot renterDS = snapshot.data;
                                      CachedNetworkImage image =
                                          CachedNetworkImage(
                                        key: ValueKey<String>(ds['images'][0]),
                                        imageUrl: ds['images'][0],
                                        placeholder: (context, url) =>
                                            new CircularProgressIndicator(),
                                        fit: BoxFit.cover,
                                      );

                                      return Container(
                                        child: InkWell(
                                          onTap: () => Navigator.pushNamed(
                                              context, RentalDetail.routeName,
                                              arguments: RentalDetailArgs(
                                                  rentalDS.documentID)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow: <BoxShadow>[
                                                CustomBoxShadow(
                                                    color: Colors.black45,
                                                    blurRadius: 3.5,
                                                    blurStyle: BlurStyle.outer),
                                              ],
                                            ),
                                            child: Stack(
                                              children: <Widget>[
                                                SizedBox.expand(child: image),
                                                SizedBox.expand(
                                                    child: Container(
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                )),
                                                Center(
                                                  child: Column(
                                                    children: <Widget>[
                                                      Text(ds['name'],
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                      // Text("Pickup Time: \n" + DateTime.fromMillisecondsSinceEpoch(rentalDS[ 'pickupStart'].millisecondsSinceEpoch).toString(), style: TextStyle(color:Colors.white)),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                      // return Container(width: MediaQuery.of(context).size.width/2, padding: EdgeInsets.only(left: 10.0), child: _tile());
                                    } else {
                                      return Container();
                                    }
                                }
                              },
                            );
                          } else {
                            return Container(
                              color: Colors.pink,
                            );
                          }
                      }
                    },
                  );
                });

                return GridView.count(
                  padding: EdgeInsets.all(10.0),
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  children: items.toList(),
                );
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  void setCardAsDefault(sourceDS) async {
    setState(() {
      isLoading = true;
    });
    final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'setDefaultSource',
    );

    callable.call(<String, dynamic>{
      'userId': myUserID,
      'customerId': stripeCustId,
      'newSourceId': sourceDS['id'],
    }).then((resp) {
      String responseMessage = resp.data;

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: responseMessage);
    });
  }

  void deleteCard(sourceDS) async {
    setState(() {
      isLoading = true;
    });

    final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'deleteStripeSource',
    );

    Firestore.instance
        .collection('users')
        .document(myUserID)
        .collection('sources')
        .document(sourceDS['card']['fingerprint'])
        .delete()
        .then((_) {
      callable.call(<String, dynamic>{
        'userId': myUserID,
        'customerId': stripeCustId,
        'source': sourceDS['id'],
      }).then((resp) {
        String responseMessage = resp.data;

        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: responseMessage);
      });
    });
  }

  Future<bool> handleCardTap(actionEnum, sourceDS) async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    String dialogText = '';
    String dialogConfirmText = 'Confirm';
    var action;

    switch (actionEnum) {
      case CardTapAction.setDefault:
        dialogText = 'Set card as default payment?';
        action = () => setCardAsDefault(sourceDS);
        break;
      case CardTapAction.delete:
        dialogText = 'Delete card?';
        dialogConfirmText = 'Delete';
        action = () => deleteCard(sourceDS);
        break;
      default:
        return false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                dialogText,
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Pop dialog
                  },
                ),
                FlatButton(
                  child: Text(dialogConfirmText),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Pop dialog
                    action();
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
