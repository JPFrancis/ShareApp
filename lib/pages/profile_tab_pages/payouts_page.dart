import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/functions.dart';
import 'package:shareapp/services/payment_service.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

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
  CurrentUser currentUser;
  String appBarTitle = 'Payments and payouts';
  double padding = 5.0;
  int numCards = 0;

  bool isLoading = false;
  bool stripeInit = false;
  bool showFAB = true;

  @override
  void initState() {
    super.initState();

    currentUser = CurrentUser.getModel(context);
    initStream();
  }

  void initStream() {
    getLinksStream().listen((link) {
      try {
        var _latestUri;
        if (link != null) _latestUri = Uri.parse(link);
        print("App was opened with: ${_latestUri}");
      } on FormatException {
        print("--- A link got here but was invalid");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: showFAB
            ? FloatingActionButton(
                onPressed: createStripeAccount,
                child: Icon(Icons.attach_money),
                tooltip: 'Create Stripe account',
              )
            : null,
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
                Tab(child: Text("Payouts")),
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
      onTap: () async {
        setState(() {
          isLoading = true;
        });

        if (!stripeInit) {
          var snap = await Firestore.instance
              .collection('keys')
              .document('stripe_pk')
              .get();

          if (snap != null && snap.exists) {
            StripeSource.setPublishableKey(snap['key']);
            stripeInit = true;
          }
        }

        StripeSource.addSource().then((token) {
          final HttpsCallable callable =
              CloudFunctions.instance.getHttpsCallable(
            functionName: 'addStripeCard',
          );

          callable.call(<String, dynamic>{
            'tokenId': token,
            'userId': currentUser.id,
            'email': currentUser.email,
            'customerId': currentUser.custId,
          }).then((var resp) {
            var response = resp.data;

            if (response != null && response is Map) {
              String custId = response['custId'];
              String defaultSource = response['defaultSource'];

              currentUser.updateCustomerId(custId);
              currentUser.updateDefaultSource(defaultSource);

              showToast('Success');
            } else {
              showToast('An error occurred');
            }

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
            color: Color(0xff007f6e),
            child: Container(
              height: w / 1.75,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), color: coolerWhite),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Color(0xff007f6e),
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
    bool isDefault =
        currentUser.defaultSource == creditCardDS['id'] ? true : false;

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
    Widget _image(){
      return Container(
        height: 100.0,
        child: Row(children: <Widget>[
          SizedBox(width: 10.0,),
          Align(alignment: Alignment.centerLeft, child: Text("Payments secured by", style: TextStyle(fontFamily: 'Quicksand', fontSize: w/25,))),
          SizedBox(width: 0.0,),
          Container(
            height: w/7,
            width: w/3, 
            decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/stripe_logo.png'), fit: BoxFit.fill),)
          ),
        ],),
      );
    }
    return Stack(children: <Widget>[
        StreamBuilder(
          stream: Firestore.instance
              .collection('users')
              .document(currentUser.id)
              .collection('sources')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return new Text('${snapshot.error}');
            }

            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Container();
              default:
                List documents = snapshot.data.documents;
                numCards = documents.length;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: documents.length + 1,
                  itemBuilder: (context, index) {
                    if (index == documents.length) {
                      return Column(
                        children: <Widget>[
                          Container(height: 10),
                          addCard(),
                          Container(height: 10),
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
        ),
      Align(alignment: Alignment.bottomLeft,child: Container(child: _image(),),)
      ],);
  }

  Widget showPayouts() {
    double w = MediaQuery.of(context).size.width;
    Widget _image(){
      return Container(
        color: Colors.transparent,
        height: 100.0,
        child: Row(children: <Widget>[
          SizedBox(width: 10.0,),
          Align(alignment: Alignment.centerLeft, child: Text("Payments secured by", style: TextStyle(fontFamily: 'Quicksand', fontSize: w/25,))),
          SizedBox(width: 0.0,),
          Container(
            height: w/7,
            width: w/3, 
            decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/stripe_logo.png'), fit: BoxFit.fill),)
          ),
        ],),
      );
    }
    return Column(
      children: <Widget>[
        buildChargesList(),
        //buildTransactions("past", "renter"),
        //buildTransactions("past", "owner"),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(child: _image())),
        ],
    );
  }

  Widget buildChargesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('charges')
            .where('status', isEqualTo: 'succeeded')
            .orderBy('timestamp', descending: true)
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
                      double amount = ds['amount'] / 100;

                      String desc = ds['description']; 
                      //bool amOwner  = ds['rentalData']['idFrom'] == myUserID ? false : true;

                      int payingIndex = desc.indexOf("paying");
                      int forIndex = desc.indexOf("for");

                      String owner = desc.substring(payingIndex + 6, forIndex);
                      String renter = desc.substring(0, payingIndex);

                      /// @rohith get user data like this
                      Map userData = ds['userData'];
                      if (userData == null) return Container();
                      Map ownerDS = userData['owner'];
                      Map renterDS = userData['renter'];
                      String ownerName = ownerDS['name'];
                      String ownerAvatar = ownerDS['avatar'];
                      String renterName = renterDS['name'];
                      String renterAvatar = renterDS['avatar'];

                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(ownerAvatar), backgroundColor: Colors.white),
                        title: Text(renter + "paying" + owner, style: TextStyle(fontFamily: appFont),),
                        subtitle: Text("insert subtitle"),
                        trailing: Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: appFont),),
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
                Firestore.instance.collection('users').document(currentUser.id))
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
                                                  Rental(rentalDS),
                                                  currentUser)),
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
      'userId': currentUser.id,
      'customerId': currentUser.custId,
      'newSourceId': sourceDS['id'],
    }).then((var resp) {
      var response = resp.data;

      if (response != null && response is String && response.isNotEmpty) {
        currentUser.updateDefaultSource(response);

        showToast('Success');

        setState(() {
          isLoading = false;
        });
      } else {
        showToast('An error occurred');

        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<Null> deleteCard(sourceDS) async {
    setState(() {
      isLoading = true;
    });

    if (numCards <= 1) {
      var requestingRentals = await Firestore.instance
          .collection('rentals')
          .where('users',
              arrayContains: Firestore.instance
                  .collection('users')
                  .document(currentUser.id))
          .where('status', isLessThan: 3)
          .limit(1)
          .getDocuments();

      if (requestingRentals != null && requestingRentals.documents.length > 0) {
        setState(() {
          isLoading = false;
        });
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Text(
                    'You can\'t delete a card if you have active rentals',
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: const Text('CLOSE'),
                      onPressed: () {
                        Navigator.of(context).pop(false); // Pop dialog
                      },
                    ),
                  ],
                );
              },
            ) ??
            false;
      }
    } else {
      final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
        functionName: 'deleteStripeSource',
      );

      Firestore.instance
          .collection('users')
          .document(currentUser.id)
          .collection('sources')
          .document(sourceDS['card']['fingerprint'])
          .delete()
          .then((_) {
        callable.call(<String, dynamic>{
          'userId': currentUser.id,
          'customerId': currentUser.custId,
          'source': sourceDS['id'],
        }).then((resp) {
          var response = resp.data;

          if (response != null && response is String && response.isNotEmpty) {
            currentUser.updateDefaultSource(response);

            showToast('Success');

            setState(() {
              isLoading = false;
            });
          } else {
            showToast('An error occurred');

            setState(() {
              isLoading = false;
            });
          }
        });
      });
    }
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

  void createStripeAccount() async {
    String phoneNum = '';
    String random = DateTime.now().microsecondsSinceEpoch.toString();

    /// CHANGE THIS ~~~~~~~~~~~~~~~~
    String email = '$random@gmail.com';
    String firstName = 'Bob';
    String lastName = 'Jones';
    String url = '';

    String redirectUrl = 'share-app.web.app/';
//    String redirectUrl = 'https://share-app.web.app/';

    url += 'https://connect.stripe.com/express/oauth/authorize?'
        'redirect_uri=$redirectUrl'
        '&client_id=ca_G2aEpUUFBkF4B3U8tgcY0G5NWhCfOj2c'
        '&stripe_user[country]=US'
        '&stripe_user[phone_number]=$phoneNum'
        '&stripe_user[business_type]=individual'
        '&stripe_user[email]=$email'
        '&stripe_user[first_name]=$firstName'
        '&stripe_user[last_name]=$lastName'
        '&stripe_user[product_description]=do_not_edit';

    if (await canLaunch(url)) {
      debugPrint("eee");
      await launch(url, forceSafariVC: false, universalLinksOnly: false);
    }else{
      debugPrint("nooo");
    }
  }

  initPlatformState() async {
    try {
      String initialLink = await getInitialLink();
      print('initial link: $initialLink');
      if (initialLink != null) {
//        String initialUri = Uri.parse(initialLink);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}