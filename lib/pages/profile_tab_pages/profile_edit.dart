import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/models/user_edit.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/functions.dart';

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
  final UsNumberTextInputFormatter phoneNumberFormatter =
      UsNumberTextInputFormatter();

  CurrentUser currentUser;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController phoneNumController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  Future<File> selectedImage;
  File imageFile;
  String photoURL;
  String myUserID;
  FirebaseUser user;
  bool isLoading = true;

  String font = 'Quicksand';

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;

  double statusBarHeight;
  double pageHeight;
  double pageWidth;

  UserEdit userCopy;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getUserID();
    currentUser = CurrentUser.getModel(context);
    userCopy = UserEdit.copy(widget.userEdit);
    nameController.text = userCopy.name;
    descriptionController.text = userCopy.description;
    phoneNumController.text = userCopy.phoneNum ?? '';

    if (userCopy.address == null) {
      userCopy.address = {};
    }
  }

  @override
  void dispose() {
    super.dispose();

    nameController.dispose();
    descriptionController.dispose();
    phoneNumController.dispose();
  }

  void getUserID() async {
    FirebaseAuth.instance.currentUser().then((user) {
      this.user = user;
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
    statusBarHeight = MediaQuery.of(context).padding.top;
    pageHeight = MediaQuery.of(context).size.height - statusBarHeight;
    pageWidth = MediaQuery.of(context).size.width;

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
      floatingActionButton: isLoading
          ? Container()
          : RaisedButton(
              child: Text(
                "SAVE",
                style: TextStyle(color: Colors.white),
              ),
              color: Color(0xff007f6e),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  showToast('Name can\'t be empty');
                } else {
                  saveProfile();
                }
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
                    birthDatePicker(),
                    emailEntry(),
                    phoneEntry(),
                    addressEntry(),
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
    String phoneNum = userCopy.phoneNum ?? 'Tap to enter';

    return InkWell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text("Phone",
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
          Text(
            '$phoneNum',
            style: TextStyle(fontFamily: font),
          )
        ],
      ),
      onTap: () async {
        String value = await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              child: PhoneNumberDialog(
                pageHeight: pageHeight,
                pageWidth: pageWidth,
                phoneNumber: userCopy.phoneNum,
              ),
            );
          },
        );

        if (value != null && value is String && value.isNotEmpty) {
          setState(() {
            userCopy.phoneNum = value;
          });
        }
      },
    );
  }

  Widget addressEntry() {
    Map userAddress = userCopy.address;
    String address = 'Tap to enter';

    if (userAddress.isNotEmpty) {
      String street = userAddress['street'];
      String city = userAddress['city'];
      String state = userAddress['state'];
      String zip = userAddress['zip'];

      address = '$street\n$city, $state\n$zip';
    }

    return InkWell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text("Address",
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
          Text(
            address,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: font,
            ),
          )
        ],
      ),
      onTap: () async {
        Map value = await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              child: AddressDialog(
                pageHeight: pageHeight,
                pageWidth: pageWidth,
                address: userCopy.address,
              ),
            );
          },
        );

        if (value != null && value is Map && value.isNotEmpty) {
          setState(() {
            userCopy.address = value;
          });
        }
      },
    );
  }

  Widget birthDatePicker() {
    var dateFormat = intl.DateFormat('MMMM d, y');
    String userBirthDate = 'Tap to select';

    if (userCopy.birthday != null) {
      userBirthDate = dateFormat.format(userCopy.birthday);
    }

    return InkWell(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'Birth Date',
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          Text(
            '$userBirthDate',
            style: TextStyle(fontFamily: font),
          ),
        ],
      ),
      onTap: () async {
        var value = await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              child: BirthdayDialog(
                pageHeight: pageHeight,
                pageWidth: pageWidth,
                birthday: userCopy.birthday,
              ),
            );
          },
        );

        if (value != null && value is DateTime) {
          setState(() {
            userCopy.birthday = value;
          });
        }
      },
    );
  }

  Widget showGenderSelecter() {
    return Container(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            isExpanded: true,
            hint: Text(
              '${userCopy.gender ?? 'Gender'}',
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (String newValue) {
              setState(() {
                userCopy.gender = newValue;
              });
            },
            items: [
              "Male",
              "Female",
              "Other",
            ]
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

    userCopy.name = nameController.text.trim();
    userCopy.description = descriptionController.text.trim();
    String avatarURL;
    bool updateAvatar = false;

    if (userCopy.address.isEmpty) {
      userCopy.address = null;
    }

    Map<String, dynamic> data = {
      'name': userCopy.name,
      'description': userCopy.description,
      'gender': userCopy.gender,
      'birthday': userCopy.birthday,
      'phoneNum': userCopy.phoneNum,
      'address': userCopy.address,
    };

    if (imageFile != null) {
      updateAvatar = true;
      avatarURL = await saveImage();

      if (avatarURL != null) {
        userCopy.avatar = avatarURL;
      }

      data.addAll({'avatar': userCopy.avatar});
    }

    await Firestore.instance
        .collection('users')
        .document(myUserID)
        .updateData(data);

    currentUser.updateUser(userEdit: userCopy);

    UserUpdateInfo userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = userCopy.name;

    if (updateAvatar) {
      userUpdateInfo.photoUrl = avatarURL;
    }

    await user.updateProfile(userUpdateInfo);
    await user.reload();

    Navigator.of(context).pop(userCopy);
  }

  Future<File> compressFile(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minHeight: 1000,
      minWidth: 1080,
      quality: 95,
    );

    return result;
  }

  Future<String> saveImage() async {
    File compressedImage =
        await compressFile(imageFile, imageFile.absolute.path);

    StorageReference ref =
        FirebaseStorage.instance.ref().child('/profile_pics/${myUserID}.jpg');
    StorageUploadTask uploadTask = ref.putFile(
        compressedImage, StorageMetadata(contentType: 'image/jpeg'));

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
