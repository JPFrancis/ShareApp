import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  static const routeName = '/chat';
  final DocumentSnapshot otherUser;

  Chat({Key key, this.otherUser}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatState();
  }
}

class ChatState extends State<Chat> {
  DocumentSnapshot chatDS;

  //DocumentSnapshot otherUserDS;
  //User otherUserDS;

  //DocumentSnapshot myUserDS;
  SharedPreferences prefs;
  DocumentSnapshot otherUser;
  List<String> combinedID;

  File imageFile;
  bool isLoading = true;
  String imageUrl;
  String myUserID;
  String groupChatId;
  String myName;

  var listMessage;

  Color primaryColor = Color.fromRGBO(80, 150, 150, 1);
  double fontSize = 16;
  double headingFontSize = 20;
  Color red = Colors.red;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();

    otherUser = widget.otherUser;
    imageUrl = '';
    getMyUserID();
    getSnapshots();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  void delayPage() async {
    isLoading = true;
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
      myUserID = user.uid;

      if (myUserID.hashCode <= otherUser.documentID.hashCode) {
        groupChatId = '$myUserID-${otherUser.documentID}';
        combinedID = [myUserID, otherUser.documentID];
      } else {
        groupChatId = '${otherUser.documentID}-$myUserID';
        combinedID = [otherUser.documentID, myUserID];
      }
    }
  }

  void getSnapshots() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .get();

    if (ds != null) {
      if (!ds.exists) {
        var documentReference =
            Firestore.instance.collection('messages').document(groupChatId);

        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            documentReference,
            {
              'users': combinedID,
            },
          );
        });
      }

      chatDS = ds;

      if (chatDS != null) {
        delayPage();
      }
    }
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection('messages')
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': myUserID,
            'idTo': otherUser.documentID,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'content': content,
            'type': type,
            'pushToken': otherUser['pushToken'],
            'nameFrom': myName,
          },
        );
      });

      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot ds) {
    bool showRental = false;
    Widget viewRentalWidget;

    Widget textWidget = Text(
      ds['content'],
      style: TextStyle(
          color: Colors.white, fontFamily: 'Quicksand', fontSize: 15.0),
    );

    if (ds['rental'] != null) {
      showRental = true;
      viewRentalWidget = RaisedButton(
        onPressed: () => navToRental(ds['rental']),
        child: Text('View rental'),
      );
    }

    if (ds['idFrom'] == myUserID) {
      // Right (my message)
      return Row(
        children: <Widget>[
          ds['type'] == 0
              // Text
              ? Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      textWidget,
                      showRental ? viewRentalWidget : Container(),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        CustomBoxShadow(
                          color: Colors.black45,
                          blurRadius: 2.0,
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(7.0),
                        topLeft: Radius.circular(7.0),
                        bottomLeft: Radius.circular(7.0),
                      )),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      right: 10.0),
                )
              : ds['type'] == 1
                  // Image
                  ? Container(
                      child: Material(
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(red),
                                ),
                                width: 200.0,
                                height: 200.0,
                                padding: EdgeInsets.all(70.0),
                                decoration: BoxDecoration(
                                  color: greyColor2,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                          imageUrl: ds['content'],
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0),
                    )
                  // Sticker
                  : Container(
                      child: new Image.asset(
                        'images/${ds['content']}.gif',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(red),
                                ),
                                width: 35.0,
                                height: 35.0,
                                padding: EdgeInsets.all(10.0),
                              ),
                          imageUrl: otherUser['avatar'],
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(18.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(width: 35.0),
                ds['type'] == 0
                    ? Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            textWidget,
                            showRental ? viewRentalWidget : Container(),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(
                            boxShadow: <BoxShadow>[
                              CustomBoxShadow(
                                color: Colors.black,
                                blurRadius: 1.5,
                                blurStyle: BlurStyle.normal,
                              ),
                            ],
                            color: Colors.grey,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(7.0),
                              topLeft: Radius.circular(7.0),
                              bottomRight: Radius.circular(7.0),
                            )),
                        margin: EdgeInsets.only(left: 10.0),
                      )
                    : ds['type'] == 1
                        ? Container(
                            child: Material(
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(red),
                                      ),
                                      width: 200.0,
                                      height: 200.0,
                                      padding: EdgeInsets.all(70.0),
                                      decoration: BoxDecoration(
                                        color: greyColor2,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Material(
                                      child: Image.asset(
                                        'images/img_not_available.jpeg',
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                imageUrl: ds['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                            margin: EdgeInsets.only(left: 10.0),
                          )
                        : Container(
                            child: new Image.asset(
                              'images/${ds['content']}.gif',
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(
                                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                                right: 10.0),
                          ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(ds['timestamp'])),
                      style: TextStyle(
                          color: greyColor,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == myUserID) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != myUserID) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        child: isLoading
            ? Container()
            : Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: 30.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton(
                            child: BackButton(),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              '${otherUser['name']}',
                              style: TextStyle(
                                  fontSize: 20.0, fontFamily: 'Quicksand'),
                            ),
                          ),
                          FlatButton(
                            child: Icon(Icons.more_horiz),
                            onPressed: null,
                          )
                        ],
                      ),
                      Divider(
                        color: Colors.black45,
                      ),
                      // List of messages
                      buildListMessage(),
                      Divider(),
                      // Input content
                      buildInput(),
                    ],
                  ),

                  // Loading
                  buildLoading()
                ],
              ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border:
              new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(red)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    bool _buttonEnabled = false;
    return Column(
      children: <Widget>[
        Container(
          height: 50.0,
          padding: EdgeInsets.all(10.0),
          child: TextFormField(
            expands: true,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            style: TextStyle(color: Colors.black, fontSize: 15.0),
            controller: textEditingController,
            decoration: InputDecoration.collapsed(
              hintText: 'Type your message',
              hintStyle: TextStyle(color: greyColor),
            ),
            //focusNode: focusNode,
          ),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 10.0,
            ),
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () => debugPrint,
            ),
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () => debugPrint,
            ),
            Spacer(flex: 1000),
            IconButton(
              icon: new Icon(Icons.send),
              onPressed: () => onSendMessage(textEditingController.text, 0),
              color: primaryColor,
            ),
            SizedBox(width: 10.0),
          ],
        )
      ],
    );
  }

  Widget buildListMessage() {
    return Expanded(
      flex: 5,
      child: chatDS.documentID == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(red)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(red)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  void navToRental(DocumentReference rentalDR) async {
    Navigator.of(context).pushNamed(RentalDetail.routeName,
        arguments: RentalDetailArgs(
          rentalDR.documentID,
        ));
  }
}
