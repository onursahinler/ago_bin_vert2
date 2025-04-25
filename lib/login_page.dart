import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  final TextEditingController _nameController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
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
                      // Title
                      Text(
                        _isLogin ? 'Log In' : 'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF77BA69),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      
                      // Name field (only for registration)
                      if (!_isLogin)
                        Container(
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF77BA69)),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              hintText: 'Your Name',
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        
                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF77BA69)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            hintText: 'E-mail',
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      
                      // Login/Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authService.isLoading 
                            ? null 
                            : () => _performAuth(authService),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF77BA69),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: authService.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isLogin ? 'Log In' : 'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Toggle login/register
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLogin 
                            ? 'Don\'t have an account? Register' 
                            : 'Already have an account? Login',
                          style: TextStyle(
                            color: Color(0xFF77BA69),
                            fontSize: 16,
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
  
  void _performAuth(AuthService authService) async {
    setState(() {
      _errorMessage = null;
    });
    
    if (_isLogin) {
      // Login flow
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter email and password';
        });
        return;
      }
      
      final error = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
        return;
      }
      
      Navigator.pushReplacementNamed(context, '/trash_bins');
    } else {
      // Register flow
      if (_emailController.text.isEmpty || 
          _passwordController.text.isEmpty ||
          _nameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill all fields';
        });
        return;
      }
      
      if (_passwordController.text.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters';
        });
        return;
      }
      
      final error = await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
        return;
      }
      
      Navigator.pushReplacementNamed(context, '/trash_bins');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}