import 'package:flutter/material.dart';
import 'package:shareapp/services/auth.dart';

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

class _LoginPageState extends State<LoginPage> {
  final formKey = new GlobalKey<FormState>();

  String email;
  String password;
  String errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool isIos;
  bool isLoading;

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
        if (_formMode == FormMode.LOGIN) {
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

        if (userId.length > 0 &&
            userId != null &&
            _formMode == FormMode.LOGIN) {
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
  }

  void _changeFormToSignUp() {
    formKey.currentState.reset();
    errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    formKey.currentState.reset();
    errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('ShareApp'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showBody() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              //_showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              googleLogin(),
              //facebookLogin(),
              //otherUserSignin(),
              _showErrorMessage(),
            ],
          ),
        ));
  }

  Widget _showErrorMessage() {
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
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/flutter-icon.png'),
        ),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => password = value,
      ),
    );
  }

  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
          ? new Text('Create an account',
              style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : new Text('Have an account? Sign in',
              style:
                  new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin,
    );
  }

  Widget googleLogin() {
    return new RaisedButton(
      child: Text("Login with Google"),
      onPressed: () => initGoogleLogin(),
    );
  }

  Widget facebookLogin() {
    return new RaisedButton(
        child: Text("Login with Facebook"),
        onPressed: null // () => initFacebookLogin(),
        );
  }

  Widget otherUserSignin() {
    return new RaisedButton(
      color: Colors.blueGrey,
      textColor: Colors.white,
      child: Text("Login as EC (TESTING PURPOSES ONLY)"),
      onPressed: validateAndSubmitOtherUser,
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

  Widget _showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.red,
            child: _formMode == FormMode.LOGIN
                ? new Text('Login',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white))
                : new Text('Create account',
                    style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: _validateAndSubmit,
          ),
        ));
  }

  void validateAndSubmitOtherUser() async {
    setState(() {
      errorMessage = "";
      isLoading = true;
    });

    String userId = "";
    try {
      if (_formMode == FormMode.LOGIN) {
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

      if (userId.length > 0 && userId != null && _formMode == FormMode.LOGIN) {
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
