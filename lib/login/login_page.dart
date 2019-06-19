import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/services/const.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/loginPage';

  LoginPage({Key key, this.title, this.auth, this.onSignIn}) : super(key: key);

  final String title;
  final BaseAuth auth;
  final VoidCallback onSignIn;

  @override
  _LoginPageState createState() => new _LoginPageState();
}

//enum FormType { login, register }
enum FormMode { LOGIN, SIGNUP }

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final formKey = new GlobalKey<FormState>();

  String email;
  String password;
  String errorMessage;

  // Initial form is login form
  FormMode formMode = FormMode.LOGIN;
  bool isIos;
  bool isLoading;

  // for animation
  AnimationController logoController;
  Animation<double> logoAnimation;
  AnimationController contentController;
  Animation<double> contentAnimation;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void _validateAndSubmit() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });
    if (_validateAndSave()) {
      String userId = "";
      try {
        if (formMode == FormMode.LOGIN) {
          userId = await widget.auth.signIn(email, password);
          print('Signed in: $userId');
        } else {
          userId = await widget.auth.createUser(email, password);
          print('Signed up user: $userId');
          widget.onSignIn();
        }
        setState(() {
          isLoading = false;
        });

        if (userId.length > 0 && userId != null && formMode == FormMode.LOGIN) {
          widget.onSignIn();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          isLoading = false;
          if (isIos) {
            errorMessage = e.details;
          } else
            errorMessage = e.message;
        });
      }
    }
  }

  @override
  void initState() {
    errorMessage = "";
    isLoading = false;
    super.initState();

    timeDilation = 3.0;
    logoController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    logoAnimation = CurvedAnimation(
        parent: logoController, curve: Interval(0, 0.5, curve: Curves.easeIn));
    contentController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    contentAnimation = CurvedAnimation(
        parent: logoController, curve: Interval(0.5, 1, curve: Curves.easeIn));
    logoController.forward();
    delayPage();
    contentController.forward();
  }

  void _changeFormToSignUp() {
    //formKey.currentState.reset();
    errorMessage = "";
    setState(() {
      formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    //formKey.currentState.reset();
    errorMessage = "";
    setState(() {
      formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Material(
      color: primaryColor,
      child: Column(
        children: <Widget>[
          FadeTransition(opacity: logoAnimation, child: _showLogo()),
          SizedBox(
            height: 20.0,
          ),
          FadeTransition(opacity: contentAnimation, child: showBody()),
        ],
      ),
    );
  }

  Widget showCircularProgress() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget showBody() {
    return new Container(
        child: new Form(
      key: formKey,
      child: new ListView(
        padding: EdgeInsets.all(0),
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Column(
              children: <Widget>[
                showEmailInput(),
                SizedBox(
                  height: 10.0,
                ),
                showPasswordInput(),
              ],
            ),
          ),
          SizedBox(
            height: 30.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: showPrimaryButton(),
          ),
          showSecondaryButton(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              googleLogin(),
              otherUserSignin(),
            ],
          ),
          /*
              showErrorMessage(),*/
        ],
      ),
    ));
  }

  Widget showErrorMessage() {
    if (errorMessage.length > 0 && errorMessage != null) {
      return new Text(
        errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget _showLogo() {
    double w = MediaQuery.of(context).size.width;
    return Column(
      children: <Widget>[
        Container(
            padding: EdgeInsets.only(top: w / 7),
            child: SvgPicture.asset(
              'assets/Borderless.svg',
              width: w / 1.5,
            )),
        Text(
          "S H A R E",
          style: TextStyle(
              fontFamily: 'Quicksand', color: Colors.white, fontSize: w / 18),
        )
      ],
    );
  }

  Widget showEmailInput() {
    return Container(
      height: 70,
      padding: EdgeInsets.only(left: 10.0),
      decoration: new BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white, width: 3)),
      ),
      child: Center(
        child: new TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.emailAddress,
          autofocus: false,
          decoration: new InputDecoration(
              hintStyle:
                  TextStyle(color: Colors.white54, fontFamily: 'Quicksand'),
              hintText: 'Email',
              border: InputBorder.none,
              icon: new Icon(
                Icons.mail,
                color: Colors.white,
              )),
          validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
          onSaved: (value) => email = value,
        ),
      ),
    );
  }

  Widget showPasswordInput() {
    return Container(
      height: 70,
      padding: const EdgeInsets.only(left: 10),
      decoration: new BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white, width: 3)),
      ),
      child: Center(
        child: new TextFormField(
          maxLines: 1,
          obscureText: true,
          autofocus: false,
          decoration: new InputDecoration(
              hintText: 'Password',
              border: InputBorder.none,
              hintStyle:
                  TextStyle(color: Colors.white54, fontFamily: 'Quicksand'),
              icon: new Icon(
                Icons.lock,
                color: Colors.white,
              )),
          validator: (value) =>
              value.isEmpty ? 'Password can\'t be empty' : null,
          onSaved: (value) => password = value,
        ),
      ),
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
      child: formMode == FormMode.LOGIN
          ? new Text('Create an account',
              style: new TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: 'Quicksand'))
          : new Text('Have an account? Sign in',
              style: new TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: 'Quicksand')),
      onPressed:
          formMode == FormMode.LOGIN ? _changeFormToSignUp : _changeFormToLogin,
    );
  }

  Widget googleLogin() {
    return Container(
      height: 60.0,
      child: new FlatButton(
        child: ClipOval(
          child: Image.asset('assets/google.jpg'),
        ),
        onPressed: () => initGoogleLogin(),
      ),
    );
  }

  Widget facebookLogin() {
    return new RaisedButton(
        child: Text("Login with Facebook"),
        onPressed: null // () => initFacebookLogin(),
        );
  }

  Widget otherUserSignin() {
    return Container(
      height: 60.0,
      width: 60.0,
      child: new FlatButton(
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
        ),
        onPressed: validateAndSubmitOtherUser,
      ),
    );
  }

  void initGoogleLogin() async {
    try {
      String userId = await widget.auth.logInGoogle();

      setState(() {
        errorMessage = 'Signed In\n\nUser id: $userId';
      });
      widget.onSignIn();
    } catch (e) {
      setState(() {
        errorMessage = 'Sign In Error\n\n${e.toString()}';
      });
      print(e);
    }
  }

  void initFacebookLogin() async {
    try {
      String userId = await widget.auth.loginFB();

      setState(() {
        errorMessage = 'Signed In\n\nUser id: $userId';
      });
      widget.onSignIn();
    } catch (e) {
      setState(() {
        errorMessage = 'Sign In Error\n\n${e.toString()}';
      });
      print(e);
    }
  }

  Widget showPrimaryButton() {
    return SizedBox(
      height: 40.0,
      child: new RaisedButton(
        elevation: 2.0,
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(10.0)),
        color: Colors.white,
        child: formMode == FormMode.LOGIN
            ? new Text('Login',
                style: new TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontFamily: 'Quicksand'))
            : new Text('Create account',
                style: new TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontFamily: 'Quicksand')),
        onPressed: _validateAndSubmit,
      ),
    );
  }

  void validateAndSubmitOtherUser() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    String userId = "";
    try {
      if (formMode == FormMode.LOGIN) {
        userId = await widget.auth.signIn('e@c.com', '000000');
        print('Signed in: $userId');
      } else {
        userId = await widget.auth.createUser(email, password);
        print('Signed up user: $userId');
        widget.onSignIn();
      }
      setState(() {
        isLoading = false;
      });

      if (userId.length > 0 && userId != null && formMode == FormMode.LOGIN) {
        widget.onSignIn();
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
        if (isIos) {
          errorMessage = e.details;
        } else
          errorMessage = e.message;
      });
    }
  }
}
