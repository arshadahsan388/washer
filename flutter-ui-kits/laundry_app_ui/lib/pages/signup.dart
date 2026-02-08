import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:laundry_app_ui/utils/helper.dart';
import 'package:laundry_app_ui/widgets/app_button.dart';
import 'package:laundry_app_ui/widgets/input_widget.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (result != null) {
        // Save user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', result.user!.uid);
        await prefs.setBool('isAdmin', false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to dashboard after successful signup
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
                              "Create an account",
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
                              InputWidget(
                                topLabel: "Full Name",
                                hintText: "Enter your full name",
                                controller: _nameController,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              InputWidget(
                                topLabel: "Email",
                                hintText: "Enter your email address",
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              InputWidget(
                                topLabel: "Phone",
                                hintText: "Enter your phone number",
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              InputWidget(
                                topLabel: "Password",
                                obscureText: true,
                                hintText: "Enter your password",
                                controller: _passwordController,
                              ),
                              SizedBox(
                                height: 25.0,
                              ),
                              _isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: Constants.primaryColor,
                                      ),
                                    )
                                  : AppButton(
                                      type: ButtonType.PRIMARY,
                                      text: "Create Account",
                                      onPressed: _handleSignUp,
                                    ),
                              SizedBox(
                                height: 15.0,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Color.fromRGBO(74, 77, 84, 1),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    },
                                    child: Text(
                                      "Log In",
                                      style: TextStyle(
                                        color: Constants.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
