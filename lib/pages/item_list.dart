import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/models/user.dart';
import 'package:shareapp/models/user_edit.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/edit_profile.dart';
import 'package:shareapp/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shareapp/pages/chat.dart';

class ItemList extends StatefulWidget {
  BaseAuth auth;
  FirebaseUser firebaseUser;
  VoidCallback onSignOut;

  ItemList({this.auth, this.firebaseUser, this.onSignOut});

  @override
  State<StatefulWidget> createState() {
    return ItemListState();
  }
}

class ItemListState extends State<ItemList> {
  List<Item> itemList;
  DocumentSnapshot currentUser;

  String userID;
  int currentTabIndex = 0;

  EdgeInsets edgeInset;
  double padding;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    padding = 12;
    edgeInset = EdgeInsets.all(padding);

    userID = widget.firebaseUser.uid;

    // get user object from firestore
    Firestore.instance
        .collection('users')
        .document(userID)
        .get()
        .then((DocumentSnapshot ds) {
      // if user is not in database, create user
      if (!ds.exists) {
        Firestore.instance.collection('users').document(userID).setData({
          'displayName': widget.firebaseUser.displayName,
          'userID': widget.firebaseUser.uid,
          'photoURL': widget.firebaseUser.photoUrl,
          'email': widget.firebaseUser.email,
          'lastActiveTimestamp': DateTime.now().millisecondsSinceEpoch,
          'accountCreationTimestamp':
              widget.firebaseUser.metadata.creationTimestamp,
        });
      }

      // if user is already in db
      else {
        //Firestore.instance.collection('users').document(userID).updateData({});
      }
    });

    //sleep(const Duration(seconds:1));
  }

  @override
  Widget build(BuildContext context) {
    Firestore.instance
        .collection('users')
        .document(userID)
        .get()
        .then((DocumentSnapshot ds) {
      Firestore.instance.collection('users').document(userID).updateData({
        'lastActiveTimestamp': DateTime.now().millisecondsSinceEpoch,

        /// TAKE BELOW TWO LINES OUT SOON
        'email': widget.firebaseUser.email,

        'accountCreationTimestamp':
            widget.firebaseUser.metadata.creationTimestamp,
      });
    });

    void signOut() async {
      try {
        await widget.auth.signOut();
        widget.onSignOut();
      } catch (e) {
        print(e);
      }
    }

    final bottomTabPages = <Widget>[
      homeTabPage(),
      //rentalsTabPage(),
      usersTabPage(),
      myListingsTabPage(),
      messagesTabPage(),
      profileTabPage(),
    ];

    final bottomNavBarTiles = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.search), title: Text('Search')),
      BottomNavigationBarItem(icon: Icon(Icons.people), title: Text('Users')),
      /*
      BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart), title: Text('Rentals')),
      */
      BottomNavigationBarItem(
          icon: Icon(Icons.style), title: Text('My Listings')),
      BottomNavigationBarItem(icon: Icon(Icons.forum), title: Text('Messages')),
      BottomNavigationBarItem(
          icon: Icon(Icons.account_circle), title: Text('Profile')),
      //more_horiz
      //view_headline
    ];
    assert(bottomTabPages.length == bottomNavBarTiles.length);
    final bottomNavBar = BottomNavigationBar(
      items: bottomNavBarTiles,
      currentIndex: currentTabIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          currentTabIndex = index;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text('ShareApp'), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.exit_to_app),
          tooltip: 'Sign out',
          onPressed: () {
            signOut();
          },
        ),
      ]),
      body: bottomTabPages[currentTabIndex],
      floatingActionButton: showFAB(),
      bottomNavigationBar: bottomNavBar,
    );
  }

  FloatingActionButton showFAB() {
    if (currentTabIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          navigateToEdit(
            Item(
              id: null,
              creator: Firestore.instance.collection('users').document(userID),
              creatorID: userID,
              name: '',
              description: '',
              type: null,
              condition: null,
              price: 0,
              numImages: 0,
              images: new List(),
              location: null,
            ),
          );
          //navigateToEdit(Item({null, '', '', true}));
          //navigateToDetail(Item('', '', 2), 'Add Item');
        },

        // Help text when you hold down FAB
        tooltip: 'Add New Item',

        // Set FAB icon
        child: Icon(Icons.add),
      );
    }

    if (currentTabIndex == 4) {
      return FloatingActionButton(
        onPressed: () {
          navToProfileEdit();
        },

        // Help text when you hold down FAB
        tooltip: 'Edit profile',

        // Set FAB icon
        child: Icon(Icons.edit),
      );
    }

    return null;
  }

  Widget homeTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          /*
      Container(child: showSignedInAs()),
          Container(
            height: padding,
          ),
          */
          buildItemList(),
        ],
      ),
    );
  }

  Widget usersTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          buildUserList(),
        ],
      ),
    );
  }

  Widget rentalsTabPage() {
    return Padding(
      padding: edgeInset,
      child: Center(
        child: Text(
          'Rentals',
          textScaleFactor: 2.5,
        ),
      ),
    );
  }

  Widget myListingsTabPage() {
    return Padding(
      padding: edgeInset,
      child: Center(
        child: Text(
          'My Listings',
          textScaleFactor: 2.5,
        ),
      ),
    );
  }

  Widget messagesTabPage() {
    return Padding(
      padding: edgeInset,
      child: Center(
        child: Text(
          'Messages',
          textScaleFactor: 2.5,
        ),
      ),
    );
  }

  Widget profileTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          showProfile(),
          getProfileDetails(),
        ],
      ),
    );
  }

  Widget getProfileDetails() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;
          List<String> details = new List();
          details.add(ds['userID'].toString());
          details.add(ds['email']);
          var date1 = new DateTime.fromMillisecondsSinceEpoch(
              ds['accountCreationTimestamp']);
          details.add(date1.toString());

          var date2 = new DateTime.fromMillisecondsSinceEpoch(
              ds['lastActiveTimestamp']);
          details.add(date2.toString());
          return Column(
            children: <Widget>[
              Container(
                height: 15,
              ),
              Text(
                'User ID: ${details[0]}',
                textScaleFactor: 1,
              ),
              Container(
                height: 15,
              ),
              Text(
                'Email: ${details[1]}',
                textScaleFactor: 1,
              ),
              Container(
                height: 15,
              ),
              Text(
                'Account creation: ${details[2]}',
                textScaleFactor: 1,
              ),
              Container(
                height: 15,
              ),
              Text(
                'Last active: ${details[3]}',
                textScaleFactor: 1,
              ),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget showProfile() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;
          return new Container(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CachedNetworkImage(
                    key: new ValueKey<String>(
                        DateTime.now().millisecondsSinceEpoch.toString()),
                    imageUrl: ds['photoURL'],
                    placeholder: (context, url) => new Container(),
                  ),
                ),
                Container(
                  height: 10,
                ),
                Text(
                  '${ds['displayName']}',
                  textScaleFactor: 1.5,
                ),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget showSignedInAs() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;

          return new Text('Signed in as: ${ds['displayName']}');
        } else {
          return new Text('');
        }
      },
    );
  }

  Widget buildItemList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  Icon tileIcon;
                  String itemType = ds['type'];

                  switch (itemType) {
                    case 'tool':
                      tileIcon = Icon(Icons.build);
                      break;
                    case 'leisure':
                      tileIcon = Icon(Icons.golf_course);
                      break;
                    case 'home':
                      tileIcon = Icon(Icons.home);
                      break;
                    case 'other':
                      tileIcon = Icon(Icons.device_unknown);
                      break;
                  }

                  return ListTile(
                    leading: tileIcon,
                    //leading: Icon(Icons.build),
                    title: Text(
                      ds['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(ds['description']),
                    onTap: () {
                      navigateToDetail(ds['id']);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteImages(Item.fromMap(ds.data, ds['id']));
                        Firestore.instance
                            .collection('items')
                            .document(ds['id'])
                            .delete();
                      },
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildUserList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('users');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference
            .where('lastActiveTimestamp', isGreaterThan: 0)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  return ListTile(
                    leading: Container(
                      height: 40,
                      child: CachedNetworkImage(
                        key: new ValueKey<String>(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        imageUrl: ds['photoURL'],
                        placeholder: (context, url) => new Container(),
                      ),
                    ),
                    title: Text(
                      ds['displayName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Last seen: ${DateTime.fromMillisecondsSinceEpoch(ds['lastActiveTimestamp']).toString()}'),
                    onTap: () {},
                    trailing: ds['userID'] != userID
                        ? IconButton(
                            icon: Icon(Icons.chat),
                            tooltip: 'Chat',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(
                                        myID: userID,
                                        peerId: ds['userID'],
                                        peerAvatar: ds['photoURL'],
                                      ),
                                ),
                              );
                            },
                          )
                        : null,
                  );
                },
              );
          }
        },
      ),
    );
  }

  void navigateToEdit(Item newItem) async {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ItemEdit(
                item: newItem,
              ),
          fullscreenDialog: true,
        ));
/* old
    String result =
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item);
    }));
    */
  }

  void navigateToDetail(String itemID) async {
    bool result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemDetail(itemID);
    }));

    /*
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item, title);
    }));*/
  }

  Future<UserEdit> getUserEdit() async {
    UserEdit out;
    DocumentSnapshot ds =
        await Firestore.instance.collection('users').document(userID).get();
    if (ds != null) {
      out = new UserEdit(
          id: userID, photoUrl: ds['photoURL'], displayName: ds['displayName']);
    }

    return out;
  }

  void navToProfileEdit() async {
    UserEdit userEdit = await getUserEdit();

    UserEdit result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => EditProfile(
                userEdit: userEdit,
              ),
          fullscreenDialog: true,
        ));

    if (result != null) {
      Firestore.instance.collection('users').document(userID).updateData({
        'displayName': result.displayName,
        'photoURL': result.photoUrl,
      });
    }
  }

  void deleteImages(Item item) async {
    String id = item.id;
    for (int i = 0; i < item.numImages; i++) {
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
}

void showSnackBar(BuildContext context, String item) {
  var message = SnackBar(
    content: Text("$item was pressed"),
    action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          debugPrint('Performing dummy UNDO operation');
        }),
  );

  Scaffold.of(context).showSnackBar(message);
}
