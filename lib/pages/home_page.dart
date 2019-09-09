import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/models/user.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/profile_tab_pages/help_page.dart';
import 'package:shareapp/pages/profile_tab_pages/payouts_page.dart';
import 'package:shareapp/pages/profile_tab_pages/profile_edit.dart';
import 'package:shareapp/pages/search_page.dart';
import 'package:shareapp/pages/transactions_page.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/services/const.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/homePage';

  final BaseAuth auth;
  final FirebaseUser firebaseUser;
  final VoidCallback onSignOut;

  HomePage({this.auth, this.firebaseUser, this.onSignOut});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  String deviceToken;

  SharedPreferences prefs;
  FirebaseUser currentUser;
  DocumentSnapshot myUserDS;
  String myUserID;
  List<Item> itemList;
  Future<File> selectedImage;
  File imageFile;

  List bottomNavBarTiles;
  List bottomTabPages;
  int currentTabIndex;
  int badge;

  bool pageIsLoading = true;
  bool locIsLoading = false;
  bool showTOS = true;
  bool isAuthenticated;

  TextEditingController searchController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  List<DocumentSnapshot> allItems;
  List<String> searchList;
  List<String> filteredList;

  Geoflutterfire geo;
  Position currentLocation;
  double searchRange = 10.0; // in miles

  EdgeInsets edgeInset;
  double padding;
  String font = 'Quicksand';

  FlutterLocalNotificationsPlugin localNotificationManager =
      FlutterLocalNotificationsPlugin();
  var initializationSettingsAndroid;
  var initializationSettingsIOS;
  var initializationSettings;
  var androidSpecs = AndroidNotificationDetails('Default channel ID',
      'Rental notifications', 'Notifications for rental updates',
      importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
  var iosSpecs = IOSNotificationDetails();
  NotificationDetails specs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    geo = Geoflutterfire();

    initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);

    initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    localNotificationManager.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    specs = NotificationDetails(androidSpecs, iosSpecs);

    currentTabIndex = 0;

    padding = 18;
    edgeInset = EdgeInsets.only(
        left: padding, right: padding, bottom: padding, top: 30);

    currentUser = widget.firebaseUser;

    if (currentUser == null) {
      isAuthenticated = false;
      showTOS = false;
    } else {
      isAuthenticated = true;
      myUserID = currentUser.uid;
      setPrefs();
    }

    bottomNavBarTiles = <BottomNavigationBarItem>[
      bottomNavTile('Search', Icon(Icons.search), false),
      bottomNavTile('Rentals', Icon(Icons.shopping_cart), false),
      bottomNavTile('Listings', Icon(Icons.style), true),
      bottomNavTile('Messages', Icon(Icons.forum), false),
      bottomNavTile('Profile', Icon(Icons.account_circle), false),
    ];

    if (isAuthenticated) {
      updateRentals();
    } else {
      setState(() {
        pageIsLoading = false;
      });
    }

    getUserLocation();
  }

  void updateRentals() async {
    CollectionReference rentalsCollection =
        Firestore.instance.collection('rentals');

    // Check for expired rentals
    var rentalQuerySnaps = await rentalsCollection
        .where('users',
            arrayContains:
                Firestore.instance.collection('users').document(myUserID))
        .where('requesting', isEqualTo: true)
        .where('lastUpdateTime',
            isLessThan: DateTime.now().subtract(Duration(days: 1)))
        .getDocuments();
    List<DocumentSnapshot> rentalSnaps = rentalQuerySnaps.documents;

    if (rentalSnaps != null && rentalSnaps.length > 0) {
      for (int i = 0; i < rentalSnaps.length; i++) {
        DocumentSnapshot rentalDS = rentalSnaps[i];

        // Delete expired rental
        await rentalsCollection.document(rentalDS.documentID).delete();
      }
    }

    // Update status of rentals that are accepted but haven't begun
    rentalQuerySnaps = await rentalsCollection
        .where('users',
            arrayContains:
                Firestore.instance.collection('users').document(myUserID))
        .where('status', isEqualTo: 2)
        .where('pickupStart', isLessThanOrEqualTo: DateTime.now())
        .getDocuments();
    rentalSnaps = rentalQuerySnaps.documents;

    if (rentalSnaps != null && rentalSnaps.length > 0) {
      for (int i = 0; i < rentalSnaps.length; i++) {
        DocumentSnapshot rentalDS = rentalSnaps[i];

        // Update rental status to active
        await rentalsCollection
            .document(rentalDS.documentID)
            .updateData({'status': 3});
      }
    }

    // Update status of rentals that are completed
    rentalQuerySnaps = await rentalsCollection
        .where('users',
            arrayContains:
                Firestore.instance.collection('users').document(myUserID))
        .where('status', isEqualTo: 3)
        .where('rentalEnd', isLessThanOrEqualTo: DateTime.now())
        .getDocuments();
    rentalSnaps = rentalQuerySnaps.documents;

    if (rentalSnaps != null && rentalSnaps.length > 0) {
      for (int i = 0; i < rentalSnaps.length; i++) {
        DocumentSnapshot rentalDS = rentalSnaps[i];

        // Update status of rental to 'past'
        await rentalsCollection
            .document(rentalDS.documentID)
            .updateData({'status': 4});
      }
    }

    scheduleNotifications();
  }

  void scheduleNotifications() async {
    await localNotificationManager.cancelAll();

    DocumentReference userDR =
        Firestore.instance.collection('users').document(myUserID);
    var rentalQuerySnaps = await Firestore.instance
        .collection('rentals')
        .where('users', arrayContains: userDR)
        .where('status', isEqualTo: 2)
        .getDocuments();
    List<DocumentSnapshot> rentalSnaps = rentalQuerySnaps.documents;

    for (int i = 0; i < rentalSnaps.length; i++) {
      DocumentSnapshot rentalDS = rentalSnaps[i];
      DateTime now = DateTime.now();
      DateTime pickupStart = rentalDS['pickupStart'].toDate();
      DateTime pickupEnd = rentalDS['pickupEnd'].toDate();
      DateTime rentalEnd = rentalDS['rentalEnd'].toDate();
      DateTime created = rentalDS['created'].toDate();
      DateTime expired = created.add(Duration(days: 1));
      String itemName = rentalDS['itemName'];
      int status = rentalDS['status'];
      List expiredRentalStatus = [0, 1];

      if (expiredRentalStatus.contains(status) && now.isAfter(expired)) {
        await Firestore.instance
            .collection('rentals')
            .document(rentalDS.documentID)
            .delete();
      } else {
        int id = i * 10;
        int idCounter = 0;

        id += idCounter;
        await localNotificationManager.schedule(
          id,
          'Pickup window will begin in 1 hour',
          'Item: $itemName',
          pickupStart.subtract(Duration(hours: 1)),
          specs,
          payload: '$id',
        );
        idCounter++;

        id += idCounter;
        await localNotificationManager.schedule(
          id,
          'Pickup window will begin in 20 minutes',
          'Item: $itemName',
          pickupStart.subtract(Duration(minutes: 20)),
          specs,
          payload: '$id',
        );
        idCounter++;

        id += idCounter;
        await localNotificationManager.schedule(
          id,
          'Pickup window has begun!',
          'Item: $itemName',
          pickupStart,
          specs,
          payload: '$id',
        );
        idCounter++;

        id += idCounter;
        await localNotificationManager.schedule(
          id,
          'Pickup window has ended! Begin rental',
          'Item: $itemName',
          pickupEnd,
          specs,
          payload: '$id',
        );
        idCounter++;

        id += idCounter;
        await localNotificationManager.schedule(
          id,
          'Item rental has ended',
          'Item: $itemName',
          rentalEnd,
          specs,
          payload: '$id',
        );
      }
    }

    removeUnavailableItemDays();
  }

  void removeUnavailableItemDays() async {
    CollectionReference itemRef = Firestore.instance.collection('items');

    QuerySnapshot snaps = await itemRef
        .where('creator',
            isEqualTo:
                Firestore.instance.collection('users').document(myUserID))
        .getDocuments();
    List<DocumentSnapshot> docs = snaps.documents;

    if (snaps != null && docs.isNotEmpty) {
      for (DocumentSnapshot snap in docs) {
        List timestamps = snap['unavailable'];
        List<DateTime> times = [];

        for (var timestamp in timestamps) {
          times.add(timestamp.toDate());
        }

        for (DateTime time in times) {
          if (time.add(Duration(days: 1)).isBefore(DateTime.now())) {

            await itemRef.document(snap.documentID).updateData({
              'unavailable': FieldValue.arrayRemove([time]),
            });
          }
        }
      }
    }

    setState(() {
      pageIsLoading = false;
    });
  }

  /*
  void configureFCM() async {
    firebaseMessaging.configure(
      /// called if app is closed but running in background
      onResume: (Map<String, dynamic> message) async {
        handleNotifications(message);
      },

      /// called if app is fully closed
      onLaunch: (Map<String, dynamic> message) async {
        handleNotifications(message);
      },

      /// called when app is running in foreground
      onMessage: (Map<String, dynamic> message) async {
      },
    );
  }

  void handleNotifications(Map<String, dynamic> message) async {
    var data = message['data'];
    var rentalID = data['rentalID'];
    String otherUserID = data['idFrom'];

    switch (data['type']) {
      case 'rental':
        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        Navigator.of(context).pushNamed(
          RentalDetail.routeName,
          arguments: RentalDetailArgs(
            rentalID,
          ),
        );

        break;

      case 'chat':
        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        Navigator.of(context).pushNamed(
          Chat.routeName,
          arguments: ChatArgs(
            otherUserID,
          ),
        );

        break;
    }
  }
  */

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }

    await Navigator.of(context).pushNamed(HelpPage.routeName);
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    /*
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new SecondScreen(payload),
                ),
              );
            },
          )
        ],
      ),
    );
    */
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        pageIsLoading = false;
      });
    });
  }

  void setPrefs() async {
    prefs = await SharedPreferences.getInstance();

    await prefs.remove('userID');

    if (prefs != null) {
      await prefs.setString('userID', myUserID);

      var stream =
          Firestore.instance.collection('users').document(myUserID).snapshots();

      stream.listen((ds) async {
        if (ds != null && ds.exists) {
          myUserDS = ds;
          var acceptedTOS = myUserDS['acceptedTOS'];

          if (acceptedTOS != null && acceptedTOS is bool) {
            if (acceptedTOS) {
              showTOS = false;
            } else {
              showTOS = true;
            }
          }

          UserUpdateInfo userUpdateInfo = UserUpdateInfo();
          userUpdateInfo.displayName = myUserDS['name'];
          userUpdateInfo.photoUrl = myUserDS['avatar'];
          await currentUser.updateProfile(userUpdateInfo);
          await currentUser.reload();

          setState(() {});
        }
      }, onDone: () {
        print("Done");
      }, onError: (error) {
        print("Error");
      });

      updateLastActiveAndPushToken();
    }
  }

  void checkPrefs() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs != null) {
      String tempUserID = await prefs.get('userID');

      if (tempUserID != null) {
        if (myUserID != tempUserID) {
          setPrefs();
        } else {
          setState(() {
            pageIsLoading = false;
          });
        }
      }
    }
  }

  void updateLastActiveAndPushToken() async {
    firebaseMessaging.getToken().then((token) {
      deviceToken = token;
      Firestore.instance.collection('users').document(myUserID).updateData({
        'lastActive': DateTime.now().millisecondsSinceEpoch,
        'pushToken': token,
      });

//      configureFCM();
    });
  }

  Future<Null> getAllItems() async {
    searchList = [];
    filteredList = [];

    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('items')
        .orderBy('name', descending: false)
        .getDocuments();

    if (querySnapshot != null) {
      allItems = querySnapshot.documents;

      allItems.forEach((DocumentSnapshot ds) {
        String name = ds['name'].toLowerCase();
        String description = ds['description'].toLowerCase();

        searchList.addAll(name.split(' '));
        searchList.addAll(description.split(' '));
      });

      searchList = searchList.toSet().toList();

      for (int i = 0; i < searchList.length; i++) {
        searchList[i] = searchList[i].replaceAll(RegExp(r"[^\w]"), '');
      }

      searchList = searchList.toSet().toList();
      searchList.sort();
      searchList.remove('');
      filteredList = searchList;

      //debugPrint('LIST: $searchList, LENGTH: ${searchList.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    bottomTabPages = <Widget>[
      searchPage(),
      myRentalsPage(),
      myListingsPage(),
      messagesTabPage(),
      profileTabPage(),
    ];

    return pageIsLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
            backgroundColor: coolerWhite,
            body: showBody(),
            floatingActionButton: showFAB(),
            bottomNavigationBar: bottomNavBar(),
          );
  }

  Widget bottomNavBar() {
    return showTOS
        ? SizedBox(height: 0)
        : SizedBox(
            //height: 90,
            child: BottomNavigationBar(
              backgroundColor: coolerWhite,
              selectedItemColor: primaryColor,
              items: bottomNavBarTiles,
              currentIndex: currentTabIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (int index) {
                setState(() {
                  currentTabIndex = index;
                });
              },
            ),
          );
  }

  Widget showTermsOfService() {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              children: <Widget>[Text('private policy here')],
            ),
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  await Firestore.instance
                      .collection('users')
                      .document(myUserID)
                      .updateData({'acceptedTOS': true});

                  showTOS = false;
                  myUserDS = await Firestore.instance
                      .collection('users')
                      .document(myUserID)
                      .get();

                  setState(() {});
                },
                child: Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget showBody() {
    if (isAuthenticated && showTOS) {
      return showTermsOfService();
    }

    return IndexedStack(
      index: currentTabIndex,
      children: bottomTabPages,
    );
  }

  Widget showFAB() {
    if (isAuthenticated && currentTabIndex == 2) {
      return RaisedButton(
          elevation: 3,
          color: Theme.of(context).primaryColor,
          textColor: Colors.white,
          onPressed: () {
            if (myUserDS != null && myUserDS.exists) {
              if (myUserDS['address'] == null ||
                  myUserDS['birthday'] == null ||
                  myUserDS['gender'] == null ||
                  myUserDS['phoneNum'] == null) {
                showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text(
                        'You must complete your profile before adding an item',
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
                          child: const Text('Edit profile'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                            navToProfileEdit();
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {
                navigateToEdit(
                  Item(
                    isVisible: true,
                    creator: Firestore.instance
                        .collection('users')
                        .document(myUserID),
                    name: '',
                    description: '',
                    type: null,
                    condition: null,
                    price: 0,
                    numImages: 0,
                    images: new List(),
                    location: {'geopoint': null},
                  ),
                  false,
                );
              }
            }
          },
          child: Text("Add Item",
              style: TextStyle(
                  fontFamily: 'Quicksand', fontWeight: FontWeight.normal)));
    } else {
      return null;
    }
  }

  BottomNavigationBarItem bottomNavTile(
      String label, Icon icon, bool showBadge) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: <Widget>[
          icon,
          showBadge
              ? StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance
                      .collection('rentals')
                      .where('owner',
                          isEqualTo: Firestore.instance
                              .collection('users')
                              .document(myUserID))
                      .where('requesting', isEqualTo: true)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return new Text('${snapshot.error}');
                    }
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:

                      default:
                        if (snapshot.hasData) {
                          var updated = snapshot.data.documents.toList().length;

                          return updated == 0
                              ? Container(
                                  height: 0,
                                  width: 0,
                                )
                              : Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 13,
                                      minHeight: 13,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$updated',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                        } else {
                          return Container(
                            height: 0,
                            width: 0,
                          );
                        }
                    }
                  },
                )
              : Container(
                  height: 0,
                  width: 0,
                ),
        ],
      ),
      title: Center(
          child: Text(label,
              style: TextStyle(fontFamily: appFont, fontSize: 13.0))),
    );
  }

  Widget cardItemRentals(ds, ownerDS, rentalDS) {
    CachedNetworkImage image = CachedNetworkImage(
      //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
      imageUrl: ds['images'][0],
      placeholder: (context, url) => new CircularProgressIndicator(),
    );

    return new Container(child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double h = constraints.maxHeight;
      double w = constraints.maxWidth;

      return InkWell(
        onTap: () {
          navigateToDetail(ds);
        },
        child: Container(
          decoration: new BoxDecoration(
            boxShadow: <BoxShadow>[
              CustomBoxShadow(
                  color: Colors.black45,
                  blurRadius: 3.0,
                  blurStyle: BlurStyle.outer),
            ],
          ),
          child: Column(
            children: <Widget>[
              Container(
                  height: 1.9 * h / 3,
                  width: w,
                  child: FittedBox(fit: BoxFit.cover, child: image)),
              SizedBox(
                height: 10.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        ds['type'] != null
                            ? Text(
                                '${ds['type']}'.toUpperCase(),
                                style: TextStyle(
                                    fontSize: h / 25,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.bold),
                              )
                            : Text(''),
                        Text('${ownerDS['name']}',
                            style: TextStyle(
                                fontSize: h / 24, fontFamily: 'Quicksand')),
                      ],
                    ),
                    Text('${ds['name']}',
                        style: TextStyle(
                            fontSize: h / 21,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.bold)),
                    Text("\$${ds['price']} per day",
                        style: TextStyle(
                            fontSize: h / 22, fontFamily: 'Quicksand')),
                    Divider(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        ButtonTheme(
                          minWidth: w / 5,
                          height: h / 13,
                          child: FlatButton(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            child: Icon(
                              Icons.add_shopping_cart,
                              size: h / 13,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RentalDetail.routeName,
                                arguments: RentalDetailArgs(
                                  rentalDS,
                                ),
                              );
                            },
                          ),
                        ),
                        ButtonTheme(
                          minWidth: w / 5,
                          height: h / 13,
                          child: FlatButton(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: h / 13,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                Chat.routeName,
                                arguments: ChatArgs(
                                  rentalDS,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }));
  }

  Widget searchPage() {
    return Container(
      child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView(
          //physics: const NeverScrollableScrollPhysics(),
          // shrinkWrap: true,
          children: <Widget>[
            introImageAndSearch(),
            SizedBox(
              height: 30.0,
            ),
            categories(),
            Container(
              height: 10,
            ),
            nearby(),
          ],
        ),
      ),
    );
  }

  Widget nearby() {
    double h = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: h / 55),
      child: Column(
        children: <Widget>[
          Text(
            'Nearby Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: font,
            ),
          ),
          Row(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              searchRangeDropdown(),
              ButtonTheme(
                minWidth: 40,
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: getUserLocation,
                  child: Icon(Icons.location_searching),
                ),
              ),
            ],
          ),
          Container(
            height: 10,
          ),
          showNearbyItems(),
        ],
      ),
    );
  }

  Widget searchRangeDropdown() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
              isDense: true,
              isExpanded: true,
              hint: Text(
                '$searchRange mile range',
                style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
              ),
              onChanged: (value) {
                setState(() {
                  searchRange = value;
                  if (currentLocation == null) {
                    getUserLocation();
                  }
                });
              },
              items: [
                5.0,
                10.0,
                25.0,
                50.0,
                100.0,
              ]
                  .map(
                    (selection) => DropdownMenuItem<double>(
                      value: selection,
                      child: Text(
                        '$selection',
                        style: TextStyle(fontFamily: font),
                      ),
                    ),
                  )
                  .toList()),
        ),
      ),
    );
  }

  Widget showNearbyItems() {
    double h = MediaQuery.of(context).size.height / 3.2;
    double w = MediaQuery.of(context).size.width;

    if (locIsLoading) {
      //return Text('Getting location...');
      return Container(
        height: h,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (currentLocation == null) {
      return Text('No location data');
    } else {
      GeoFirePoint center = geo.point(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude);

      var collectionReference = Firestore.instance
          .collection('items')
          .where('isVisible', isEqualTo: true);

      // kilometers
      double radius = searchRange * 1.609;
      String field = 'location';

      Stream<List<DocumentSnapshot>> stream = geo
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: radius, field: field);

      return Container(
        height: h,
        child: StreamBuilder(
          stream: stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            if (snapshot.hasError) {
              return new Text('${snapshot.error}');
            }
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:

              default:
                if (snapshot.hasData) {
                  List<DocumentSnapshot> items = snapshot.data;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot itemDS = items[index];
                      DocumentReference creatorRef = itemDS['creator'];

                      return myUserID == creatorRef.documentID
                          ? Container()
                          : Container(
                              width: w / 2.2,
                              child: itemCard(itemDS, context),
                            );
                    },
                  );
                } else {
                  return Container();
                }
            }
          },
        ),
      );
    }
  }

  getUserLocation() async {
    setState(() {
      locIsLoading = true;
    });
    GeolocationStatus geolocationStatus =
        await Geolocator().checkGeolocationPermissionStatus();

    if (geolocationStatus != null) {
      if (geolocationStatus != GeolocationStatus.granted) {
        setState(() {
          locIsLoading = false;
        });

        showUserLocationError();
      } else {
        currentLocation = await locateUser();

        if (currentLocation != null) {
          setState(() {
            locIsLoading = false;
          });
        }
      }
    }
  }

  Future<Position> locateUser() async {
    return Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> showUserLocationError() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                'Problem with getting your current location',
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget lookingFor() {
    double h = MediaQuery.of(context).size.height;
    Widget _searchItem(item, user, description) {
      return Card(
        elevation: 0.7,
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                item,
                style: TextStyle(color: Colors.black),
              ),
              Text(
                user,
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          trailing: Container(height: 0, width: 0),
          children: <Widget>[
            Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  description,
                  style: TextStyle(fontFamily: 'Quicksand'),
                )),
            Container(
              padding: EdgeInsets.only(right: 10.0),
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(Icons.chat_bubble_outline),
                onPressed: () => null,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h / 55),
      child: Column(
        children: <Widget>[
          Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "People Are Looking For...",
                style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: h / 40,
                    fontWeight: FontWeight.bold),
              )),
          SizedBox(
            height: 10.0,
          ),
          _searchItem("Keurig Coffee Maker", "Rohith",
              "I'm looking for a Keurig coffee maker because I have excess k-cups but no Keurig."),
          _searchItem("40\"+ TV", "Bob",
              "I'm hosting a football watching party this weekend. I need a big tv, preferably OLED and 4K Resolution."),
          _searchItem("Balloon Pump", "Trent",
              "Need a balloon pump to fill balloons. Manual pump."),
          Align(
            alignment: Alignment.bottomRight,
            child: FlatButton(
              child: Text("View all"),
              onPressed: null,
            ),
          )
        ],
      ),
    );
  }

  Widget introImageAndSearch() {
    double h = MediaQuery.of(context).size.height;

    RegExp regExp = RegExp(r'^' + searchController.text.toLowerCase() + r'.*$');

    if (searchController.text.isNotEmpty) {
      List<String> temp = [];
      for (int i = 0; i < filteredList.length; i++) {
        if (regExp.hasMatch(filteredList[i])) {
          temp.add(filteredList[i]);
        }
      }

      filteredList = temp;
    } else {
      filteredList = searchList;
    }

    Widget searchField() {
      return InkWell(
        onTap: () => navToSearchResults(),
        splashColor: primaryColor,
        child: Container(
          decoration: new BoxDecoration(
              color: Colors.white,
              borderRadius: new BorderRadius.only(
                  bottomLeft: const Radius.circular(10.0),
                  bottomRight: const Radius.circular(10.0),
                  topLeft: const Radius.circular(10.0),
                  topRight: const Radius.circular(10.0))),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20.0,
              ),
              Icon(Icons.search, color: primaryColor),
              SizedBox(
                width: 10,
              ),
              Text("Try \"Vacuum\"", style: TextStyle(fontFamily: 'Quicksand')),
            ],
          ),
          height: h / 20,
        ),
      );
    }

    return Container(
      height: h / 4,
      width: MediaQuery.of(context).size.width,
      decoration: new BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/paddleboard.jpg'), fit: BoxFit.fill),
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
                color: Colors.black,
                blurRadius: 3.0,
                blurStyle: BlurStyle.outer),
          ],
          color: primaryColor,
          borderRadius: new BorderRadius.only(
              bottomLeft: const Radius.circular(40.0),
              bottomRight: const Radius.circular(40.0))),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                    padding: EdgeInsets.only(left: 80.0),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      "make it happen",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: appFont,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w300),
                    )),
                searchField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget iconCategories() {
    double h = MediaQuery.of(context).size.height;

    Widget _categoryTile(category, icon) {
      return ClipRRect(
        borderRadius: new BorderRadius.circular(5.0),
        child: Container(
          height: h / 7.5,
          width: h / 7.5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              Container(
                height: 10,
              ),
              Text(
                category,
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Quicksand',
                    fontSize: h / 60),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h / 55),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                onTap: () => navToItemFilter('Tool'),
                child: _categoryTile('Tools', Icon(Icons.build)),
              ),
              InkWell(
                onTap: () => navToItemFilter('Leisure'),
                child: _categoryTile('Leisure', Icon(Icons.golf_course)),
              ),
              InkWell(
                onTap: () => navToItemFilter('Home'),
                child: _categoryTile('Household', Icon(Icons.home)),
              ),
            ],
          ),
          SizedBox(
            height: 15.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                onTap: () => navToItemFilter('Equipment'),
                child: _categoryTile('Equipment', Icon(Icons.straighten)),
              ),
              InkWell(
                onTap: () => navToItemFilter('Other'),
                child: _categoryTile('Miscellaneous', Icon(Icons.widgets)),
              ),
              InkWell(
                onTap: () => navToItemFilter('All'),
                child: _categoryTile('More', Icon(Icons.more_horiz)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget categories() {
    double h = MediaQuery.of(context).size.height;

    Widget _categoryTile(category, image) {
      return ClipRRect(
        borderRadius: new BorderRadius.circular(5.0),
        child: Container(
          height: h / 7.5,
          width: h / 7.5,
          child: Stack(
            children: <Widget>[
              SizedBox.expand(
                  child: Image.asset(
                image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )),
              SizedBox.expand(
                child: Container(color: Colors.black45),
              ),
              Center(
                  child: Text(category,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Quicksand',
                          fontSize: h / 60)))
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h / 55),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                onTap: () => navToItemFilter('Tools'),
                child: _categoryTile('Tools', 'assets/tools.jpg'),
              ),
              InkWell(
                onTap: () => navToItemFilter('Leisure'),
                child: _categoryTile('Leisure', 'assets/golfclub.jpg'),
              ),
              InkWell(
                onTap: () => navToItemFilter('Household'),
                child: _categoryTile('Household', 'assets/iron.jpg'),
              ),
            ],
          ),
          SizedBox(
            height: 15.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                onTap: () => navToItemFilter('Equipment'),
                child: _categoryTile('Equipment', 'assets/tent.jpg'),
              ),
              InkWell(
                onTap: () => navToItemFilter('Miscellaneous'),
                child: _categoryTile('Miscellaneous', 'assets/lawnchair.jpg'),
              ),
              InkWell(
                onTap: () => navToItemFilter('All'),
                child: _categoryTile('More', 'assets/misc.jpg'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget myRentalsPage() {
    if (!isAuthenticated) {
      return Center(
        child: Text(
          'Sign in to start renting',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
            elevation: 3.0,
            title: Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("My Rentals",
                      style: TextStyle(
                          fontFamily: appFont,
                          fontWeight: FontWeight.w400,
                          fontSize: 25))),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.only(
              bottomRight: const Radius.elliptical(40.0, 25),
              bottomLeft: const Radius.elliptical(40.0, 25),
            ))),
        body: Column(
          children: <Widget>[
            reusableCategoryWithAll("REQUESTING",
                () => navToTransactionsPage(RentalPhase.requesting, 'renter')),
            buildRequests("renter"),
            reusableCategoryWithAll("UPCOMING",
                () => navToTransactionsPage(RentalPhase.upcoming, 'renter')),
            buildTransactions(RentalPhase.upcoming, "renter"),
            reusableCategoryWithAll("CURRENT",
                () => navToTransactionsPage(RentalPhase.current, 'renter')),
            buildTransactions(RentalPhase.current, "renter"),
            reusableCategoryWithAll("PAST",
                () => navToTransactionsPage(RentalPhase.past, 'renter')),
            buildTransactions(RentalPhase.past, "renter"),
          ],
        ));
  }

  void navToTransactionsPage(RentalPhase filter, String person) {
    Navigator.pushNamed(context, TransactionsPage.routeName,
        arguments: TransactionsPageArgs(filter, person));
  }

  Widget buildListingsList() {
    int tilerows = MediaQuery.of(context).size.width > 500 ? 3 : 2;
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('items')
            .where('creator',
                isEqualTo:
                    Firestore.instance.collection('users').document(myUserID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List snapshots = snapshot.data.documents;
                return GridView.count(
                    shrinkWrap: true,
                    mainAxisSpacing: 15.0,
                    crossAxisCount: tilerows,
                    childAspectRatio: (2 / 3),
                    padding: const EdgeInsets.all(15.0),
                    crossAxisSpacing: MediaQuery.of(context).size.width / 25,
                    children: snapshots
                        .map((snapshot) => itemCard(snapshot, context))
                        .toList());
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget buildRequests(person) {
    Stream stream = Firestore.instance
        .collection('rentals')
        .where(person,
            isEqualTo:
                Firestore.instance.collection('users').document(myUserID))
        .where('requesting', isEqualTo: true)
        .snapshots();
    var status;
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return new Text('${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:

          default:
            if (snapshot.hasData) {
              var updated = snapshot.data.documents.toList();

              if (updated.length == 0) {
                return Text('Nothing to show');
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: updated.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot rentalDS = updated[index];
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
                            DocumentSnapshot itemDS = snapshot.data;
                            int durationDays = rentalDS['duration'];
                            String duration =
                                '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

                            return StreamBuilder<DocumentSnapshot>(
                              stream: person == "renter"
                                  ? rentalDS["owner"].snapshots()
                                  : rentalDS["renter"].snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return new Text('${snapshot.error}');
                                }
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:

                                  default:
                                    if (snapshot.hasData) {
                                      DocumentSnapshot otherUserDS =
                                          snapshot.data;
                                      int status = rentalDS['status'];
                                      bool isRenter =
                                          person == 'renter' ? true : false;

                                      CustomBoxShadow cbs =
                                          (isRenter && status == 1) ||
                                                  (!isRenter && status == 0)
                                              ? CustomBoxShadow(
                                                  color: primaryColor,
                                                  blurRadius: 6.0,
                                                  blurStyle: BlurStyle.outer)
                                              : CustomBoxShadow(
                                                  color: Colors.black38,
                                                  blurRadius: 3.0,
                                                  blurStyle: BlurStyle.outer);

                                      return Column(
                                        children: <Widget>[
                                          Container(
                                            decoration: new BoxDecoration(
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        itemDS['images'][0]),
                                                fit: BoxFit.cover,
                                                colorFilter:
                                                    new ColorFilter.mode(
                                                        Colors.black
                                                            .withOpacity(0.45),
                                                        BlendMode.srcATop),
                                              ),
                                              boxShadow: <BoxShadow>[cbs],
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.pushNamed(context,
                                                    RentalDetail.routeName,
                                                    arguments: RentalDetailArgs(
                                                        rentalDS.documentID));
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: <Widget>[
                                                  Column(
                                                    children: <Widget>[
                                                      SizedBox(
                                                        height: 6.0,
                                                      ),
                                                      Container(
                                                          height: 30,
                                                          width: 30,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.white,
                                                              image: DecorationImage(
                                                                  image: CachedNetworkImageProvider(
                                                                      otherUserDS[
                                                                          'avatar']),
                                                                  fit: BoxFit
                                                                      .fill))),
                                                      Text(
                                                        otherUserDS['name'],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Quicksand',
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: <Widget>[
                                                      Row(children: <Widget>[
                                                        Text("Request Sent: ",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Quicksand')),
                                                        Text(
                                                          timeago.format(
                                                              rentalDS[
                                                                      'created']
                                                                  .toDate()),
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontFamily:
                                                                  'Quicksand',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        )
                                                      ]),
                                                      Row(
                                                        children: <Widget>[
                                                          Text(
                                                            "Requested Duration: ",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Quicksand'),
                                                          ),
                                                          Text(duration,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'Quicksand',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold))
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5.0)
                                        ],
                                      );
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
                },
              );
            } else {
              return Container();
            }
        }
      },
    );
  }

  Widget buildTransactions(RentalPhase rentalStatus, person) {
    Query query = Firestore.instance.collection('rentals').where(person,
        isEqualTo: Firestore.instance.collection('users').document(myUserID));

    switch (rentalStatus) {
      case RentalPhase.requesting:
        break;
      case RentalPhase.upcoming:
        query = query
            .where('status', isEqualTo: 2)
            .where('pickupStart', isGreaterThan: DateTime.now())
            .orderBy('pickupStart', descending: false)
            .limit(3);
        break;
      case RentalPhase.current:
        query = query
            .where('status', isEqualTo: 3)
            .where('rentalEnd', isGreaterThan: DateTime.now())
            .limit(3);
        break;
      case RentalPhase.past:
        query = query
            .where('rentalEnd', isLessThan: DateTime.now())
            .orderBy('rentalEnd', descending: true)
            .limit(3);
        break;
    }

    Stream stream = query.snapshots();

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
                var updated = snapshot.data.documents;

                if (updated.length == 0) {
                  return Text('Nothing to show');
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: updated.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot rentalDS = updated[index];
                    String itemName = rentalDS['itemName'];
                    String itemAvatar = rentalDS['itemAvatar'];

                    CachedNetworkImage image = CachedNetworkImage(
                      key: ValueKey<String>(itemAvatar),
                      imageUrl: itemAvatar,
                      placeholder: (context, url) =>
                          new CircularProgressIndicator(),
                      fit: BoxFit.cover,
                    );

                    return Container(
                      width: MediaQuery.of(context).size.width / 2,
                      padding: EdgeInsets.only(left: 10.0),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                            context, RentalDetail.routeName,
                            arguments: RentalDetailArgs(rentalDS.documentID)),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
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
                                color: Colors.black.withOpacity(0.4),
                              )),
                              Center(
                                child: Column(
                                  children: <Widget>[
                                    Text(itemName,
                                        style: TextStyle(color: Colors.white)),
                                    // Text("Pickup Time: \n" + DateTime.fromMillisecondsSinceEpoch(rentalDS[ 'pickupStart'].millisecondsSinceEpoch).toString(), style: TextStyle(color:Colors.white)),
                                    StreamBuilder(
                                        stream: Stream.periodic(
                                            Duration(seconds: 30), (i) => i),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<int> snapshot) {
                                          DateTime now = DateTime.now();
                                          DateTime pickupTime =
                                              rentalDS['pickupStart'].toDate();

                                          int days =
                                              pickupTime.difference(now).inDays;
                                          int hours = pickupTime
                                              .difference(
                                                  now.add(Duration(days: days)))
                                              .inHours;
                                          int minutes = pickupTime
                                              .difference(now.add(Duration(
                                                  days: days, hours: hours)))
                                              .inMinutes;

                                          var dateString = '';

                                          if (days == 0) {
                                            dateString =
                                                '$hours hours, $minutes min until pickup';
                                          } else {
                                            dateString =
                                                '$days days, $hours hours, $minutes min until pickup';
                                          }

                                          /*
                                          int now = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          int pickupTime =
                                              rentalDS['pickupStart']
                                                  .millisecondsSinceEpoch;
                                          Duration remaining = Duration(
                                              milliseconds: (pickupTime - now));
                                          var dateString;
                                          remaining.inDays == 0
                                              ? dateString =
                                                  '${format.format(DateTime.fromMillisecondsSinceEpoch(remaining.inMilliseconds))}'
                                              : dateString =
                                                  '${remaining.inDays} days, ${format.format(DateTime.fromMillisecondsSinceEpoch(remaining.inMilliseconds))}';
                                          */

                                          return Container(
                                            child: Text(
                                              dateString,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          );
                                        })
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget myListingsPage() {
    if (!isAuthenticated) {
      return Center(
        child: Text(
          'Sign in to list items',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      );
    }

    double h = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            bottom: PreferredSize(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(
                        child: Text(
                      "All My Items",
                      style: TextStyle(fontFamily: 'Quicksand'),
                    )),
                    Tab(
                      child: Stack(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(width: 9),
                              Text(
                                "Transactions",
                                style: TextStyle(fontFamily: 'Quicksand'),
                              ),
                              Container(width: 9),
                            ],
                          ),
                          StreamBuilder(
                            stream: Firestore.instance
                                .collection('rentals')
                                .where('owner',
                                    isEqualTo: Firestore.instance
                                        .collection('users')
                                        .document(myUserID))
                                .where('requesting', isEqualTo: true)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasError) {
                                return Container();
                              }
                              switch (snapshot.connectionState) {
                                case (ConnectionState.waiting):
                                default:
                                  if (snapshot.hasData) {
                                    int transactionsCount = 0;
                                    var docs = snapshot.data.documents;

                                    if (docs.length > 0) {
                                      transactionsCount = docs.length;
                                    }

                                    return transactionsCount > 0
                                        ? Positioned(
                                            top: 6,
                                            right: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red[600],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: 15,
                                                minHeight: 15,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${transactionsCount}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container();
                                  } else {
                                    return Container();
                                  }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  labelColor: coolerWhite,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: coolerWhite,
                ),
              ),
              preferredSize: Size.fromHeight(45),
            ),
            elevation: 3.0,
            title: Column(
              children: <Widget>[
                Align(
                    alignment: Alignment.bottomLeft,
                    child: Text("My Listings",
                        style: TextStyle(
                            fontFamily: appFont,
                            fontWeight: FontWeight.w400,
                            fontSize: 25))),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: Text("Your Items That Others Can Rent",
                        style: TextStyle(
                            fontFamily: appFont,
                            fontWeight: FontWeight.w400,
                            fontSize: 15))),
              ],
            ),
            shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.only(
              bottomRight: const Radius.elliptical(40.0, 25),
              bottomLeft: const Radius.elliptical(40.0, 25),
            ))),
        body: Stack(children: <Widget>[
          Container(
            color: coolerWhite,
            child: TabBarView(
              children: [
                Column(
                  children: <Widget>[
                    buildListingsList(),
                  ],
                ),
                Column(
                  children: <Widget>[
                    reusableCategoryWithAll(
                        "REQUESTS",
                        () => navToTransactionsPage(
                            RentalPhase.requesting, 'owner')),
                    buildRequests("owner"),
                    reusableCategoryWithAll(
                        "UPCOMING",
                        () => navToTransactionsPage(
                            RentalPhase.requesting, 'owner')),
                    buildTransactions(RentalPhase.upcoming, "owner"),
                    reusableCategoryWithAll(
                        "CURRENT",
                        () => navToTransactionsPage(
                            RentalPhase.requesting, 'owner')),
                    buildTransactions(RentalPhase.current, "owner"),
                    reusableCategoryWithAll(
                        "PAST",
                        () => navToTransactionsPage(
                            RentalPhase.requesting, 'owner')),
                    buildTransactions(RentalPhase.past, "owner"),
                  ],
                ),
              ],
            ),
          ),
          /*
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Container(
                height: 30.0,
                decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: new BorderRadius.all(
                      Radius.circular(100.0),
                    )),
<<<<<<< HEAD
                child: new TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(
                        child: Text(
                      "All My Items",
                      style: TextStyle(fontFamily: 'Quicksand'),
                    )),
                    Tab(
                        child: Text(
                      "Transactions",
                      style: TextStyle(fontFamily: 'Quicksand'),
                    )),
                  ],
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.transparent,
                ),
=======
                child: new
>>>>>>> 707e04d663dc7c8e83823a7d8002b505d85104bb
              ),
            ),
          ),*/
        ]),
      ),
    );
  }

  Widget messagesTabPage() {
    if (!isAuthenticated) {
      return Center(
        child: Text(
          'Sign in to view messages',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      );
    }

    double h = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.only(top: h / 15),
      child: Column(
        children: <Widget>[
          Align(
              alignment: Alignment.topLeft,
              child: Container(
                  padding: EdgeInsets.only(left: 30.0, bottom: 10.0),
                  child: Text("Messages",
                      style:
                          TextStyle(fontSize: 30.0, fontFamily: 'Quicksand')))),
          Divider(),
          buildMessagesList(),
        ],
      ),
    );
  }

  Widget profileTabPage() {
    return isAuthenticated
        ? profileIntroStream()
        : Center(
            child: RaisedButton(
              child: Text('Logout'),
              onPressed: logout,
            ),
          );
  }

  Widget profileIntroStream() {
    Widget showPersonalInformation() {
      double width = MediaQuery.of(context).size.width;

      Widget _userImage() {
        void onImageButtonPressed(ImageSource source) {
          setState(() {
            selectedImage = ImagePicker.pickImage(source: source);
          });
        }

        Widget _showCurrentProfilePic() {
          double height = MediaQuery.of(context).size.height;
          double width = MediaQuery.of(context).size.width;
          return Container(
            padding: EdgeInsets.only(left: width / 5, right: width / 5),
            height: height / 5,
            child: FittedBox(
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                imageUrl: myUserDS['avatar'],
                placeholder: (context, url) => CircularProgressIndicator(),
              ),
            ),
          );
        }

        return Center(
          child: InkWell(
            //onTap: () => onImageButtonPressed(ImageSource.gallery),
            child: FutureBuilder<File>(
                future: selectedImage,
                builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    imageFile = snapshot.data;
                    return Image.file(imageFile);
                  } else if (snapshot.error != null) {
                    return const Text(
                      'Error',
                      textAlign: TextAlign.center,
                    );
                  } else {
                    return _showCurrentProfilePic();
                  }
                }),
          ),
          // Icon(Icons.edit)
        );
      }

      return Column(
        children: <Widget>[
          _userImage(),
          SizedBox(
            height: 10.0,
          ),
          Center(
              child: Text("${myUserDS['name']}",
                  style: TextStyle(fontFamily: font, fontSize: width / 15))),
          Center(
              child: Text('${myUserDS['email']}',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: width / 27,
                      fontFamily: 'Quicksand'))),
          SizedBox(
            height: 5.0,
          ),
          Center(
              child: Column(children: <Widget>[
            Align(
                alignment: Alignment.topLeft,
                child: Icon(
                  QuoteIcons.quote_left,
                  size: width / 22,
                )),
            Text(
              myUserDS['description'].toString().isEmpty
                  ? "The user hasn't added a description yet!"
                  : myUserDS['description'],
              style: TextStyle(fontFamily: font, fontSize: width / 22),
            ),
            Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  QuoteIcons.quote_right,
                  size: width / 22,
                )),
          ])),
          SizedBox(
            height: 10.0,
          ),
          Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[]
                    .map((Widget child) => Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Column(
                            children: <Widget>[child, Divider()],
                          ),
                        ))
                    .toList(),
              )),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 40.0),
      /* decoration: new BoxDecoration(
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
                color: Colors.black,
                blurRadius: 2.0,
                blurStyle: BlurStyle.outer),
          ],
          color: primaryColor,
          borderRadius: new BorderRadius.only(
            bottomLeft: const Radius.circular(50.0),
            bottomRight: const Radius.circular(50.0),
          )),*/
      child: StreamBuilder<DocumentSnapshot>(
        stream: Firestore.instance
            .collection('users')
            .document(myUserID)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            default:
              if (snapshot.hasData) {
                DocumentSnapshot ds = snapshot.data;
                String name;

                if (ds.exists) {
                  name = ds['name'];
                  prefs.setString('name', name);
                } else {
                  name = 'ERROR';
                  prefs.setString('name', name);
                }

                return Stack(
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.height - 90,
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.all(0),
                        children: <Widget>[
                          showPersonalInformation(),
                          reusableCategory("ACCOUNT"),
                          //reusableFlatButton("Personal information", Icons.person_outline, null),
                          reusableFlatButton("Payments and Payouts",
                              Icons.payment, navToPayouts),
                          reusableFlatButton(
                              "Notifications", Icons.notifications, null),
                          reusableCategory("SUPPORT"),
                          reusableFlatButton("Get help", Icons.help_outline,
                              () => navToSendEmail('Help')),
                          reusableFlatButton("Give us feedback", Icons.feedback,
                              () => navToSendEmail('Feedback')),
                          reusableFlatButton("Log out", null, logout),
                          //getProfileDetails()
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: OutlineButton(
                        color: Colors.white,
                        textColor: primaryColor,
                        onPressed: () {
                          navToProfileEdit();
                        },
                        child: Text(
                          "Edit Profile",
                          style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget getProfileDetails() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(myUserID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;
          List<String> details = new List();
          details.add(ds.documentID);
          details.add(ds['email']);
          var date1 =
              new DateTime.fromMillisecondsSinceEpoch(ds['creationDate']);
          details.add(date1.toString());

          var date2 = new DateTime.fromMillisecondsSinceEpoch(ds['lastActive']);
          details.add(date2.toString());
          return Column(
            children: <Widget>[
              Container(
                height: 15,
              ),
              Text('User ID: ${details[0]}',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Quicksand',
                      fontSize: 13.0)),
              Container(
                height: 15,
              ),
              Text('Account creation: ${details[2]}',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Quicksand',
                      fontSize: 13.0)),
              Container(
                height: 15,
              ),
              Text(
                'Last active: ${details[3]}',
                style: TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Quicksand',
                    fontSize: 13.0),
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget buildRentalsList(bool requesting) {
    int tileRows = MediaQuery.of(context).size.width > 500 ? 3 : 2;

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('rentals')
            .where('renter',
                isEqualTo:
                    Firestore.instance.collection('users').document(myUserID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> items = snapshot.data.documents
                    .where((d) =>
                        requesting ^ (d['status'] == 0 || d['status'] == 1))
                    .toList();
                return GridView.count(
                    padding: EdgeInsets.all(20.0),
                    mainAxisSpacing: 15,
                    shrinkWrap: true,
                    crossAxisCount: tileRows,
                    childAspectRatio: (2 / 3),
                    crossAxisSpacing: MediaQuery.of(context).size.width / 20,
                    children: items.map((DocumentSnapshot rentalDS) {
                      if (snapshot.hasData) {
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
                                  DocumentSnapshot itemDS = snapshot.data;
                                  DocumentReference ownerDR = rentalDS['owner'];

                                  return StreamBuilder<DocumentSnapshot>(
                                    stream: ownerDR.snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            snapshot) {
                                      if (snapshot.hasError) {
                                        return new Text('${snapshot.error}');
                                      }
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.waiting:

                                        default:
                                          if (snapshot.hasData) {
                                            DocumentSnapshot ownerDS =
                                                snapshot.data;

                                            String created = 'Created: ' +
                                                timeago.format(
                                                    rentalDS['created']
                                                        .toDate());

                                            return cardItemRentals(
                                                itemDS, ownerDS, rentalDS);
                                          } else {
                                            return Container();
                                          }
                                      }
                                    },
                                  );
                                } else {
                                  return Container();
                                }
                            }
                          },
                        );
                      } else {
                        return Container();
                      }
                    }).toList());
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget buildMessagesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('messages')
            .where('users', arrayContains: myUserID)
            .orderBy('lastSent.timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            default:
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot chatDS = snapshot.data.documents[index];
                    List combinedID = chatDS['users'];
                    Map otherUser;
                    String otherUserId;
                    String lastMessage = chatDS['lastSent']['content'];
                    var timestamp = chatDS['lastSent']['timestamp'];

                    if (combinedID.length == 2) {
                      if (myUserID == combinedID[0]) {
                        otherUser = chatDS['user1'];
                        otherUserId = combinedID[1];
                      } else if (myUserID == combinedID[1]) {
                        otherUser = chatDS['user0'];
                        otherUserId = combinedID[0];
                      }
                    }
                    Text title = Text(
                      otherUser['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'Quicksand'),
                    );

                    String imageURL = otherUser['avatar'];
                    int cutoff = 30;
                    String lastMessageCrop;

                    if (lastMessage.length > cutoff) {
                      lastMessageCrop = lastMessage.substring(0, cutoff);
                      lastMessageCrop += '...';
                    } else {
                      lastMessageCrop = lastMessage;
                    }

                    return messageCard(
                        imageURL,
                        title,
                        //lastActive,
                        Text(
                            '${timeago.format(DateTime.fromMillisecondsSinceEpoch(timestamp))}'),
                        lastMessageCrop,
                        otherUserId);
                  },
                );
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget messageCard(
      imageURL, title, lastActive, lastMessageCrop, otherUserID) {
    return Column(
      children: <Widget>[
        ListTile(
          leading: Container(
            height: 50,
            width: 50,
            child: ClipOval(
              child: CachedNetworkImage(
                //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
                imageUrl: imageURL,
                placeholder: (context, url) => new Container(),
              ),
            ),
          ),
          title: title,
          subtitle: Container(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Align(alignment: Alignment.centerLeft, child: lastActive),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lastMessageCrop,
                      style: TextStyle(fontFamily: "Quicksand"),
                    )),
              ],
            ),
          ),
          //subtitle: Text( '$lastActive\n$itemName\n$lastMessageCrop'),
          onTap: () {
            Navigator.pushNamed(
              context,
              Chat.routeName,
              arguments: ChatArgs(otherUserID),
            );
          },
        ),
        Divider(),
      ],
    );
  }

  void navigateToEdit(Item newItem, bool isEdit) async {
    if (!isAuthenticated || !myUserDS['acceptedTOS']) {
      return;
    }

    Navigator.pushNamed(
      context,
      ItemEdit.routeName,
      arguments: ItemEditArgs(
        newItem,
        null,
      ),
    );
  }

  void navigateToDetail(DocumentSnapshot itemDS) async {
    Navigator.pushNamed(
      context,
      ItemDetail.routeName,
      arguments: ItemDetailArgs(
        itemDS,
      ),
    );
  }

  void navToItemFilter(String filter) async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => SearchPage(
            typeFilter: filter,
            showSearch: false,
          ),
        ));
  }

  void navToSearchResults() async {
    Navigator.push(
        context,
        SlideUpRoute(
          page: SearchPage(
            typeFilter: 'All',
            showSearch: true,
          ),
        ));
  }

  void navToProfileEdit() async {
    if (myUserDS != null && myUserDS.exists) {
      Timestamp timestampBirthday = myUserDS['birthday'];
      DateTime birthday;

      if (timestampBirthday != null) {
        birthday = timestampBirthday.toDate();
      }

      User userEdit = User.fromMap(myUserDS.data, birthday);

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => ProfileEdit(
              userEdit: userEdit,
            ),
            fullscreenDialog: true,
          ));
    }
  }

  Future<bool> deleteItemError() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Item is currently being rented, so it cannot be deleted'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> deleteItemDialog(DocumentSnapshot ds) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete item?'),
              content: Text('${ds['name']}'),
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
                    deleteItem(ds);
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void deleteItem(DocumentSnapshot ds) {
    deleteImages(ds.documentID, ds['numImages']);
    Firestore.instance.collection('items').document(ds.documentID).delete();
  }

  void deleteImages(String id, int numImages) async {
    for (int i = 0; i < numImages; i++) {
      FirebaseStorage.instance.ref().child('$id/$i').delete();
    }

    FirebaseStorage.instance.ref().child('$id').delete();
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }

  Future<DocumentSnapshot> getUserFromFirestore(String userID) async {
    DocumentSnapshot ds =
        await Firestore.instance.collection('users').document(userID).get();

    return ds;
  }

  void navToPayouts() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => PayoutsPage(),
        ));
  }

  // help=1, feedback=2
  void navToSendEmail(String type) async {
    String email = 'jay@shareapp.app';
    String subject = '';
    String body = '';

    switch (type) {
      case 'Help':
        subject = '[Help] ';
        break;
      case 'Feedback':
        subject = '[Feedback] ';
        break;
    }

    String url = 'mailto:$email?subject=$subject&body=$body';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void logout() async {
    try {
      if (isAuthenticated) {
        await prefs.remove('userID');

        Firestore.instance.collection('users').document(myUserID).updateData({
          'pushToken': FieldValue.arrayRemove([deviceToken]),
        });

        widget.auth.signOut().then((_) {
          widget.onSignOut();
        });
      } else {
        widget.onSignOut();
      }
    } catch (e) {
      print(e);
    }
  }
}

void showSnackBar(BuildContext context, String item) {
  var message = SnackBar(
    content: Text("$item was pressed"),
    action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          // do something
        }),
  );

  Scaffold.of(context).showSnackBar(message);
}

Widget template() {
  // template
  return StreamBuilder<DocumentSnapshot>(
    stream: null,
    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
            DocumentSnapshot ds = snapshot.data;
          } else {
            return Container();
          }
      }
    },
  );
}

void showToast(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIos: 1,
      fontSize: 16.0);
}

// to show all items created by you
//where('creator', isEqualTo: Firestore.instance.collection('users').document(userID)),
