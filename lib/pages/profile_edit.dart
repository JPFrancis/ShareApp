import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/models/user_edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        padding:
            EdgeInsets.only(top: 30.0, bottom: 10.0, left: 18.0, right: 18.0),
        children: <Widget>[
          previewImage(),
          showDisplayNameEditor(),
          Divider(),
          Text("About me"),
          showAboutMe(),
          Divider(),
          Text("Private Details"),
          showGenderSelecter(),
          datePicker(),
          Text("email placeholder"),
          Text("government ID placeholder"),
          Text("emergency contact placeholder"),
          Divider(),
          Text("Optional Details"),
          showProfileOptions(),
        ].map<Widget>((Widget child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: child,
          );
        }).toList(),
      ),
    );
  }

  Widget datePicker() {
    var formatter = new DateFormat('MMMM d, y');
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
      child: Text(formatted),
      onTap: () => _selectDate(context),
    );
  }

  Widget showGenderSelecter() {
    return Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0),
      child: DropdownButton<String>(
          // [todo value]
          hint: Text('Gender'),
          onChanged: (String newValue) {
            // [todo]
          },
          items: ["Male", "Female", "Other"]
              .map(
                (gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    ),
              )
              .toList()),
    );
  }

  Widget showAboutMe() {
    double width = MediaQuery.of(context).size.width;
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: TextField(
          cursorColor: Colors.blueAccent,
          style: textStyle,
          onChanged: (value) {
//            userEditCopy.displayName = displayNameController.text;
          },
          decoration: InputDecoration.collapsed(hintText: "Description"),
        ),
      ),
    );
  }

  Widget showDisplayNameEditor() {
    double width = MediaQuery.of(context).size.width;
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: TextField(
          cursorColor: Colors.blueAccent,
          controller: displayNameController,
          style: textStyle,
          onChanged: (value) {
            userEditCopy.displayName = displayNameController.text;
          },
          decoration: InputDecoration.collapsed(hintText: "Name"),
        ),
      ),
    );
  }

  Widget showProfileOptions() {
    return Container(
        child: Row(
      children: <Widget>[
        Container(
          height: 120,
          width: 120,
          child: previewImage(),
        ),
        Container(
          width: 15,
        ),
        Column(
          children: <Widget>[
            RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.red,
              textColor: Colors.white,
              child: Text(
                "Take picture",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                onImageButtonPressed(ImageSource.camera);
              },
            ),
            RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.red,
              textColor: Colors.white,
              child: Text(
                "Pick from gallery",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                onImageButtonPressed(ImageSource.gallery);
              },
            ),
          ],
        ),
      ],
    ));
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
          key: new ValueKey<String>(
              DateTime.now().millisecondsSinceEpoch.toString()),
          imageUrl: userEditCopy.photoUrl,
          placeholder: (context, url) => new CircularProgressIndicator(),
        ),
      ),
    );
  }

  void onImageButtonPressed(ImageSource source) {
    setState(() {
      selectedImage = ImagePicker.pickImage(source: source);
    });
  }

  Widget previewImage() {
    return Container(
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
        'photoURL': userEditCopy.photoUrl,
      });

      setState(() {
        isUploading = false;
      });
    }

    Firestore.instance
        .collection('users')
        .document(userEditCopy.id)
        .updateData({
      'displayName': userEditCopy.displayName,
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
