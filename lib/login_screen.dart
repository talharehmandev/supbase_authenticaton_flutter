import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';
import 'create_account.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _loading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 🔑 Step 1: Login
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // 🔎 Step 2: Fetch user + related school name
        final userData = await supabase
            .from('user_schools')
            .select('user_name, user_email, schools(school_name)')
            .eq('user_id', userId)
            .maybeSingle();

        if (userData != null) {
          final userName = userData['user_name'] ?? "Unknown";
          final userEmail =
              userData['user_email'] ?? response.user!.email ?? "No Email";
          final schoolName =
              userData['schools']?['school_name'] ?? "Unknown School";

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                userName: userName,
                userEmail: userEmail,
                schoolName: schoolName,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage =
            "Profile not found. Please complete registration or contact support.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Invalid credentials, please try again.";
        });
      }
    } catch (e) {
      String message = "Something went wrong. Please try again.";

      if (e.toString().contains("Invalid login credentials")) {
        message = "Invalid email or password. Please try again.";
      } else if (e.toString().contains("network")) {
        message = "Network error. Please check your internet connection.";
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }



  bool _isPasswordVisible = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo / Header
            const Icon(Icons.school, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Login to continue',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // Email Field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // toggle visibility
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                // Eye icon to show/hide password
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Login",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign Up Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don’t have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAccountWithSchoolPage()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  }
}
