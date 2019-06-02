import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/models/user_edit.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class ProfileEdit extends StatefulWidget {
  static const routeName = '/editProfile';
  final UserEdit userEdit;

  ProfileEdit({Key key, this.userEdit}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProfileEditState();
  }
}

/// We initially assume we are in editing mode
class ProfileEditState extends State<ProfileEdit> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  TextEditingController displayNameController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  Future<File> selectedImage;
  File imageFile;
  String photoURL;
  bool isUploading = false;

  String font = 'Quicksand';

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;

  UserEdit userEditCopy;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    userEditCopy = UserEdit.copy(widget.userEdit);
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    displayNameController.text = userEditCopy.displayName;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          isUploading
              ? Container(
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                )
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
          padding: EdgeInsets.only(top: 40.0, left: 25.0, right: 25.0),
          children: <Widget>[
            image(),
            SizedBox(height: 10.0),
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
              "rohith2017324@gmail.com",
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
      onTap: () => _selectDate(context),
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
          cursorColor: Colors.blueAccent,
          style: TextStyle(fontFamily: font, fontSize: width / 20),
          // onChanged: (value) { userEditCopy.displayName = displayNameController.text; },
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
        controller: displayNameController,
        style: TextStyle(fontFamily: font, fontSize: width / 15),
        onChanged: (value) {
          userEditCopy.displayName = displayNameController.text;
        },
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
          key: ValueKey<String>(userEditCopy.photoUrl),
          imageUrl: userEditCopy.photoUrl,
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
    if (isUploading) {
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
      isUploading = true;
    });

    if (imageFile != null) {
      String result = await saveImage();

      if (result != null) {
        userEditCopy.photoUrl = result;
      }

      Firestore.instance
          .collection('users')
          .document(userEditCopy.id)
          .updateData({
        'avatar': userEditCopy.photoUrl,
      });

      setState(() {
        isUploading = false;
      });
    }

    Firestore.instance
        .collection('users')
        .document(userEditCopy.id)
        .updateData({
      'name': userEditCopy.displayName,
    });

    Navigator.of(context).pop(userEditCopy);
  }

  Future<String> saveImage() async {
    StorageReference ref = FirebaseStorage.instance
        .ref()
        .child('/profile_pics/${userEditCopy.id}');
    StorageUploadTask uploadTask = ref.putFile(imageFile);

    return await (await uploadTask.onComplete).ref.getDownloadURL();
  }

  Future<bool> onWillPop() async {
    if (widget.userEdit.displayName == userEditCopy.displayName) return true;

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
