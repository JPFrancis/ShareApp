import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shareapp/models/user_edit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class EditProfile extends StatefulWidget {
  static const routeName = '/editProfile';
  final UserEdit userEdit;

  EditProfile({Key key, this.userEdit}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EditProfileState();
  }
}

/// We initially assume we are in editing mode
class EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  bool isUploading = false;
  String photoURL;

  TextEditingController displayNameController = TextEditingController();

  TextStyle textStyle;
  TextStyle inputTextStyle;

  ThemeData theme;

  UserEdit userEditCopy;

  Future<File> selectedImage;
  File imageFile;

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
      appBar: AppBar(
        title: Text('Edit User Profile'),
        actions: <Widget>[
          FlatButton(
            child: Text('SAVE',
                textScaleFactor: 1.05,
                style: theme.textTheme.body2.copyWith(color: Colors.white)),
            onPressed: () {
              saveItem();
              //Navigator.pop(context, DismissDialogAction.save);
            },
          ),
        ],
      ),
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
    );
  }

  Widget showBody() {
    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: ListView(
        padding: EdgeInsets.only(top: 00.0, bottom: 10.0, left: 18.0, right: 18.0),
        children: <Widget>[
          previewImage(),
          showProfileOptions(),
          showDisplayNameEditor(),
        ].map<Widget>((Widget child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: child,
          );
        }).toList(),
      ),
    );
  }
  
  Widget showUserID() {
    return Container(
        child: Text(
      "Your user id: ${userEditCopy.id}",
      style: TextStyle(fontSize: 16),
    ));
  }

  Widget showDisplayNameEditor() {
    return Container(
      child: TextField(
        controller: displayNameController,
        style: textStyle,
        onChanged: (value) {
          userEditCopy.displayName = displayNameController.text;
        },
        decoration: InputDecoration(
          labelText: 'Display name',
          filled: true,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
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
                //addButton + " Images",
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
    return Container(
      height: MediaQuery.of(context).size.height / 4,
      width: MediaQuery.of(context).size.height / 4,
      child: CachedNetworkImage(
      key: new ValueKey<String>(
          DateTime.now().millisecondsSinceEpoch.toString()),
      imageUrl: userEditCopy.photoUrl,
      placeholder: (context, url) => new CircularProgressIndicator(),
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
      //return Center(child: CircularProgressIndicator());

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

  void saveItem() async {
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
