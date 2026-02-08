import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:laundry_app_ui/utils/helper.dart';
import 'package:laundry_app_ui/widgets/app_button.dart';
import 'package:laundry_app_ui/widgets/input_widget.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result != null) {
        // Save user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', result.user!.uid);
        
        // Check if admin credentials
        String email = _emailController.text.trim().toLowerCase();
        await prefs.setBool('isAdmin', email == 'admin@laundry.com');
        
        if (email == 'admin@laundry.com') {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.primaryColor,
      body: SafeArea(
        bottom: false,
        child: Container(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0.0,
                top: -20.0,
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    "assets/images/washing_machine_illustration.png",
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 15.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Icon(
                                FlutterIcons.keyboard_backspace_mdi,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            Text(
                              "Log in to your account",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40.0,
                      ),
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.of(context).size.height - 180.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.0),
                              topRight: Radius.circular(30.0),
                            ),
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Lets make a generic input widget
                              InputWidget(
                                topLabel: "Email",
                                hintText: "Enter your email address",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(
                                height: 25.0,
                              ),
                              InputWidget(
                                topLabel: "Password",
                                obscureText: true,
                                hintText: "Enter your password",
                                controller: _passwordController,
                              ),
                              SizedBox(
                                height: 15.0,
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "Forgot Password?",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Constants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              _isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Constants.primaryColor,
                                      ),
                                    )
                                  : AppButton(
                                      type: ButtonType.PRIMARY,
                                      text: "Log In",
                                      onPressed: _handleLogin,
                                    )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
