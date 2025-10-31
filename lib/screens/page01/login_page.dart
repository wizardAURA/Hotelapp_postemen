import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:hotelapp/screens/page02/home_screen.dart';
import 'dart:ui';

import '../../services/google_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userCredential = await GoogleSignInService.signInWithGoogle();
      if (!mounted) return;
      if (userCredential != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, 'home');
        print('User signed in: ${userCredential.user?.displayName}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
        ),
      );

      print('Error signing in with Google: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -40,
                    height: 400,
                    width: width,
                    child: FadeInUp(
                      duration: Duration(seconds: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    height: 400,
                    width: width + 20,
                    child: FadeInUp(
                      duration: Duration(milliseconds: 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background-2.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: Duration(milliseconds: 1500),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Color.fromRGBO(49, 39, 79, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  _isLoading
                      ? CircularProgressIndicator()
                      : FadeInUp(
                          duration: Duration(milliseconds: 1900),
                          child: MaterialButton(
                            onPressed: _signInWithGoogle,
                            color: Color.fromRGBO(49, 39, 79, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            height: 50,

                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/icons/google_icon.png',
                                    height: 32,
                                    width: 32,
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Sign in with Google",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  SizedBox(height: 0),
                  FadeInUp(
                    duration: Duration(milliseconds: 1700),
                    child: Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Don't have an account? Create Account",
                          style: TextStyle(
                            color: Color.fromRGBO(196, 135, 198, 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
