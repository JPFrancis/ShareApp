import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/models/user.dart';
import 'package:shareapp/services/const.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class ProfileEdit extends StatefulWidget {
  static const routeName = '/editProfile';
  final User userEdit;

  ProfileEdit({Key key, this.userEdit}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProfileEditState();
  }
}

/// We initially assume we are in editing mode
class ProfileEditState extends State<ProfileEdit> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  Future<File> selectedImage;
  File imageFile;
  String photoURL;
  String myUserID;
  bool isLoading = true;

  String font = 'Quicksand';

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;

  User userCopy;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setUserID();
    userCopy = User.copy(widget.userEdit);
    nameController.text = userCopy.name;
    descriptionController.text = userCopy.description;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void setUserID() async {
    FirebaseAuth.instance.currentUser().then((user) {
      myUserID = user.uid;

      if (myUserID != null) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    textStyle = TextStyle(fontSize: 20, fontFamily: 'Quicksand');
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          isLoading
              ? Container(
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)))
              : showBody(),
          showCircularProgress(),
        ],
      ),
      floatingActionButton: RaisedButton(
        child: Text("SAVE"),
        onPressed: () {
          saveProfile();
        },
      ),
    );
  }

  Widget showBody() {
    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: ListView(
          padding: EdgeInsets.only(top: 30.0, left: 25.0, right: 25.0),
          children: <Widget>[
            Container(
              alignment: Alignment.topLeft,
              child: FloatingActionButton(
                  onPressed: () => Navigator.pop(context),
                  child: Icon(Icons.close),
                  elevation: 1,
                  backgroundColor: Colors.white70,
                  foregroundColor: primaryColor),
            ),
            image(),
            SizedBox(height: 15.0),
            showDisplayNameEditor(),
            divider(),
            reusableCategory("ABOUT ME"),
            showAboutMe(),
            divider(),
            reusableCategory("PRIVATE DETAILS"),
            Container(
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    showGenderSelecter(),
                    birthPicker(),
                    emailEntry(),
                    phoneEntry(),
                  ]
                      .map((Widget child) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
                            child: Column(
                              children: <Widget>[child, Divider()],
                            ),
                          ))
                      .toList(),
                )),
            Container(
              height: 70,
            ),
          ]),
    );
  }

  Widget reusableCategory(text) {
    return Container(
        padding: EdgeInsets.only(top: 10.0, bottom: 15.0),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
              fontSize: 11.0, fontWeight: FontWeight.w400, fontFamily: font),
        ));
  }

  Widget emailEntry() {
    return InkWell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text("Email",
                style:
                    TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
            Text(
              '${userCopy.email}',
              style: TextStyle(fontFamily: font),
            )
          ],
        ),
        onTap: null);
  }

  Widget phoneEntry() {
    return InkWell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text("Phone",
                style:
                    TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
            Text(
              "999-999-9999",
              style: TextStyle(fontFamily: font),
            )
          ],
        ),
        onTap: null);
  }

  Widget birthPicker() {
    var formatter = new intl.DateFormat('MMMM d, y');
    String formatted = formatter.format(selectedDate);

    Future<Null> _selectDate(BuildContext context) async {
      final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1930),
        lastDate: DateTime(2020),
      );
      if (picked != null && picked != selectedDate)
        setState(() {
          selectedDate = picked;
        });
    }

    return InkWell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "Birth Date",
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          Text(
            formatted,
            style: TextStyle(fontFamily: font),
          ),
        ],
      ),
      onTap: () => null, //_selectDate(context),
    );
  }

  Widget showGenderSelecter() {
    return Container(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            isExpanded: true,
            // [todo value]
            hint: Text(
              'Gender',
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (String newValue) {
              // [todo]
            },
            items: ["Male", "Female", "Other"]
                .map(
                  (gender) => DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: TextStyle(fontFamily: font),
                        ),
                      ),
                )
                .toList()),
      ),
    );
  }

  Widget showAboutMe() {
    double width = MediaQuery.of(context).size.width;
    return Center(
      child: Column(children: <Widget>[
        Align(alignment: Alignment.topLeft, child: Icon(QuoteIcons.quote_left)),
        TextField(
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textAlign: TextAlign.center,
          controller: descriptionController,
          cursorColor: Colors.blueAccent,
          style: TextStyle(fontFamily: font, fontSize: width / 20),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Description",
          ),
        ),
        Align(
            alignment: Alignment.bottomRight,
            child: Icon(QuoteIcons.quote_right)),
      ]),
    );
  }

  Widget showDisplayNameEditor() {
    double width = MediaQuery.of(context).size.width;
    return Center(
      child: TextField(
        textAlign: TextAlign.center,
        cursorColor: Colors.blueAccent,
        controller: nameController,
        style: TextStyle(fontFamily: font, fontSize: width / 15),
        decoration: InputDecoration.collapsed(hintText: "Name"),
      ),
    );
  }

  Widget showCurrentProfilePic() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.only(left: width / 5, right: width / 5),
      height: height / 5,
      child: FittedBox(
        fit: BoxFit.cover,
        child: CachedNetworkImage(
          //key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          imageUrl: userCopy.avatar,
          placeholder: (context, url) => CircularProgressIndicator(),
        ),
      ),
    );
  }

  void onImageButtonPressed(ImageSource source) {
    setState(() {
      selectedImage = ImagePicker.pickImage(source: source);
    });
  }

  Widget image() {
    return Center(
      child: InkWell(
        onTap: () => onImageButtonPressed(ImageSource.gallery),
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
                return showCurrentProfilePic();
              }
            }),
      ),
      // Icon(Icons.edit)
    );
  }

  Widget showCircularProgress() {
    if (isLoading) {
      return Container(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Saving...",
                style: TextStyle(fontSize: 30),
              ),
              Container(
                height: 20.0,
              ),
              Center(child: CircularProgressIndicator())
            ]),
      );
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  void saveProfile() async {
    setState(() {
      isLoading = true;
    });

    String name = nameController.text.trim();
    String description = descriptionController.text.trim();

    if (imageFile != null) {
      String result = await saveImage();

      if (result != null) {
        userCopy.avatar = result;
      }

      Firestore.instance.collection('users').document(myUserID).updateData({
        'avatar': userCopy.avatar,
        'name': name,
        'description': description,
      });

      setState(() {
        isLoading = false;
      });
    } else {
      Firestore.instance.collection('users').document(myUserID).updateData({
        'name': name,
        'description': description,
      });
    }

    Navigator.of(context).pop(userCopy);
  }

  Future<String> saveImage() async {
    StorageReference ref =
        FirebaseStorage.instance.ref().child('/profile_pics/${myUserID}.jpg');
    StorageUploadTask uploadTask =
        ref.putFile(imageFile, StorageMetadata(contentType: 'image/jpeg'));

    return await (await uploadTask.onComplete).ref.getDownloadURL();
  }

  Future<bool> onWillPop() async {
    if (widget.userEdit.name == userCopy.name) return true;

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                'Discard changes?',
                style: dialogTextStyle,
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
                  child: const Text('Discard'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        true); // Returning true to _onWillPop will pop again.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
