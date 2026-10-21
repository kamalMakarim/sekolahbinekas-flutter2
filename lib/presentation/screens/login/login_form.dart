import 'package:flutter/material.dart';
import '../../../data/user_database.dart';
import 'package:url_launcher/url_launcher.dart';
import './login_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sekolahbinekas/data/image_database.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late OverlayEntry _whiteOverlay;
  bool _acceptPolicy = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_acceptPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must accept the policy to continue.')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      await LoginLogic().login(email, password);

      UserDatabase()
          .getCurrentUserData()
          .then((currentUser) async {
            if (currentUser != null) {
              if (_rememberMe) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('saved_email', email);
                await prefs.setString('saved_password', password);
              }

              // find zipline token
              if (currentUser.zipline_token == null ||
                  currentUser.zipline_token!.isEmpty) {
                final ziplineRegister = await ImageDatabase().register(
                  email,
                  password,
                );
                if (!ziplineRegister) {
                  throw Exception('Failed to register on Zipline server.');
                }
              }
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              print('No user logged in');
            }
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            print('Error fetching user data: $error');
          });
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${((error as dynamic).message ?? error.toString())}'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _whiteOverlay = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: Material(color: Colors.white, child: const SizedBox.shrink()),
        ),
      );
      Overlay.of(context).insert(_whiteOverlay);

      LoginLogic()
          .autoLogin()
          .then((auto) {
            if (!mounted) return;
            // remove the white screen before navigating so it doesn't persist
            _whiteOverlay.remove();

            if (auto) {
              Navigator.pushReplacementNamed(context, '/home');
            }
            // if not auto, the login form will be visible after removing the overlay
          })
          .catchError((error) {
            if (!mounted) return;
            // remove white screen and show error
            _whiteOverlay.remove();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.toString())));
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo on top
          Image.asset(
            'assets/images/LogoBinekas.png', // Replace with your asset path
            height: 200,
          ),
          SizedBox(height: 24),

          // Email Field with Icon and Helper Text
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.person), // logo on the left
            ),
          ),
          SizedBox(height: 16),

          // Password Field with Icon and Helper Text
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Accept Policy Section
          Row(
            children: [
              Checkbox(
                value: _acceptPolicy,
                onChanged: (value) {
                  setState(() {
                    _acceptPolicy = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptPolicy = !_acceptPolicy;
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('I have read and agree to the'),
                      SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'https://privacy-policy.app.sekolahbinekas.com',
                            ),
                          );
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Remember me checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: const Text(
                    'Remember me',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
