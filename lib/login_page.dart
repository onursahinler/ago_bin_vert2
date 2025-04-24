import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 80),
                      // App name
                      Text(
                        'AGO BinVert',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF77BA69),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Trash bin icon
                      Icon(
                        Icons.delete_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 40),
                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF77BA69)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'E-mail',
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Password field
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF77BA69)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/trash_bins');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF77BA69),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom slogan
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 15),
              color: Color(0xFF77BA69),
              child: Text(
                'Right on Time, No Overflow Crime!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}