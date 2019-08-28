import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  final UsNumberTextInputFormatter phoneNumberFormatter =
      UsNumberTextInputFormatter();
  final UpperCaseTextFormatter stateFormatter = UpperCaseTextFormatter();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController phoneNumController = TextEditingController();
  TextEditingController streetAddressController = TextEditingController();
  TextEditingController cityAddressController = TextEditingController();
  TextEditingController stateAddressController = TextEditingController();
  TextEditingController zipAddressController = TextEditingController();

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

  User userCopy;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getUserID();
    userCopy = User.copy(widget.userEdit);
    nameController.text = userCopy.name;
    descriptionController.text = userCopy.description;
    phoneNumController.text = userCopy.phoneNum ?? '';

    if (userCopy.address != null) {
      Map address = userCopy.address;
      streetAddressController.text = address['street'];
      cityAddressController.text = address['city'];
      stateAddressController.text = address['state'];
      zipAddressController.text = address['zip'];
    } else {
      userCopy.address = {};
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneNumController.dispose();
    super.dispose();
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
        child: Text(
          "SAVE",
          style: TextStyle(color: Colors.white),
        ),
        color: Color(0xff007f6e),
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
                style:
                    TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
            Text(
              '$phoneNum',
              style: TextStyle(fontFamily: font),
            )
          ],
        ),
        onTap: () => showPhoneNumEditor(context));
  }

  showPhoneNumEditor(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Phone Number'),
            content: TextField(
              autofocus: true,
              controller: phoneNumController,
              maxLength: 14,
              inputFormatters: <TextInputFormatter>[
                WhitelistingTextInputFormatter.digitsOnly,
                phoneNumberFormatter,
              ],
              keyboardType: TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              onSubmitted: (text) {
                if (phoneNumController.text.length == 14) {
                  setState(() {
                    userCopy.phoneNum = text;
                  });

                  Navigator.of(context).pop();
                }
              },
            ),
            actions: <Widget>[
              FlatButton(
                child: new Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text('SAVE'),
                onPressed: () {
                  if (phoneNumController.text.length == 14) {
                    setState(() {
                      userCopy.phoneNum = phoneNumController.text;
                    });

                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
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
                style:
                    TextStyle(fontFamily: font, fontWeight: FontWeight.w500)),
            Text(
              address,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: font,
              ),
            )
          ],
        ),
        onTap: () => showAddressEditor(context));
  }

  showAddressEditor(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Address'),
            content: Container(
              height: 170,
              child: Column(
                children: <Widget>[
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Street',
                    ),
                    controller: streetAddressController,
                  ),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'City',
                    ),
                    controller: cityAddressController,
                  ),
                  Row(
                    children: <Widget>[
                      Flexible(
                        flex: 1,
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'State',
                          ),
                          controller: stateAddressController,
                          maxLength: 2,
                          inputFormatters: <TextInputFormatter>[
                            stateFormatter,
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                      ),
                      Flexible(
                        flex: 2,
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Zip',
                          ),
                          controller: zipAddressController,
                          maxLength: 5,
                          keyboardType: TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: new Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: new Text('SAVE'),
                onPressed: () {
                  if (streetAddressController.text.isEmpty) {
                    Fluttertoast.showToast(msg: 'Street name can\'t be empty');
                  } else if (cityAddressController.text.isEmpty) {
                    Fluttertoast.showToast(msg: 'City can\'t be empty');
                  } else if (stateAddressController.text.length != 2) {
                    Fluttertoast.showToast(msg: 'Please enter valid state');
                  } else if (zipAddressController.text.length != 5) {
                    Fluttertoast.showToast(msg: 'Please enter valid zip code');
                  } else {
                    setState(() {
                      userCopy.address['street'] =
                          streetAddressController.text.trim();
                      userCopy.address['city'] =
                          cityAddressController.text.trim();
                      userCopy.address['state'] =
                          stateAddressController.text.trim();
                      userCopy.address['zip'] =
                          zipAddressController.text.trim();
                    });

                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
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
      onTap: showBirthDatePicker,
    );
  }

  void showBirthDatePicker() {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      onConfirm: (date) {
        setState(() {
          userCopy.birthday = date;
        });
      },
      currentTime: userCopy.birthday ?? DateTime.now(),
      locale: LocaleType.en,
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
            hintText: "Where ya from? What do ya do for fun?",
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
    String avatarURL;
    bool updateAvatar = false;

    if (userCopy.address.isEmpty) {
      userCopy.address = null;
    }

    if (imageFile != null) {
      updateAvatar = true;
      avatarURL = await saveImage();

      if (avatarURL != null) {
        userCopy.avatar = avatarURL;
      }

      Firestore.instance.collection('users').document(myUserID).updateData({
        'avatar': userCopy.avatar,
        'name': name,
        'description': description,
        'gender': userCopy.gender,
        'birthday': userCopy.birthday,
        'phoneNum': userCopy.phoneNum,
        'address': userCopy.address,
      });

      setState(() {
        isLoading = false;
      });
    } else {
      Firestore.instance.collection('users').document(myUserID).updateData({
        'name': name,
        'description': description,
        'gender': userCopy.gender,
        'birthday': userCopy.birthday,
        'phoneNum': userCopy.phoneNum,
        'address': userCopy.address,
      });
    }

    UserUpdateInfo userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = name;

    if (updateAvatar) {
      userUpdateInfo.photoUrl = avatarURL;
    }

    await user.updateProfile(userUpdateInfo);
    await user.reload();

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
