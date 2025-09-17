import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';

class CreateAccountWithSchoolPage extends StatefulWidget {
  const CreateAccountWithSchoolPage({Key? key}) : super(key: key);

  @override
  _CreateAccountWithSchoolPageState createState() => _CreateAccountWithSchoolPageState();
}

class _CreateAccountWithSchoolPageState extends State<CreateAccountWithSchoolPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _userNameCodeController = TextEditingController();

  String? _selectedSchool;
  List<Map<String, dynamic>> _schools = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    final response = await Supabase.instance.client.from('schools').select();
    setState(() {
      _schools = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final enteredCode = _schoolCodeController.text.trim();
    final username = _userNameCodeController.text.trim();

    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a school')),
      );
      return;
    }

    final school = _schools.firstWhere((s) => s['school_name'] == _selectedSchool);
    if (school['school_code'] != enteredCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid school code')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      // 🔹 Step 1: Check if email already exists in user_schools
      final existingUser = await supabase
          .from('user_schools')
          .select('id')
          .eq('user_email', email);

      if (existingUser.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This email is already used with another account.')),
        );
        setState(() => _loading = false);
        return;
      }

      // 🔹 Step 2: Sign up with Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await supabase.from('user_schools').insert({
          'user_id': response.user!.id,
          'school_id': school['id'],
          'user_name': username, // TODO: Replace with user input
          'user_email': email,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              userName: username,        // Replace with user input later
              userEmail: email,
              schoolName: school['school_name'],
            ),
          ),
              (route) => false, // This removes all previous routes
        );


      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $error')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white,fontWeight:FontWeight.bold ),
        ),
        centerTitle: false,
        backgroundColor: Colors.deepPurple,
        elevation: 2,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
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

            // User Name
            TextField(
              controller: _userNameCodeController,
              decoration: InputDecoration(
                labelText: 'User Name',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

        // 1️⃣ Add these variables in your StatefulWidget class

// 2️⃣ Password TextField
      TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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

// 3️⃣ Confirm Password TextField
      TextField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          prefixIcon: const Icon(Icons.lock_outline),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
      ),

      const SizedBox(height: 16),

            // School Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSchool,
              items: _schools.map((school) {
                return DropdownMenuItem<String>(
                  value: school['school_name'],
                  child: Text(school['school_name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSchool = val;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Institute',
                prefixIcon: const Icon(Icons.school),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // School Code
            TextField(
              keyboardType: TextInputType.number,
              controller: _schoolCodeController,
              decoration: InputDecoration(
                labelText: 'Institute Code',
                prefixIcon: const Icon(Icons.code),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create Account Button
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: () {
                // Step 1: Check all fields
                final email = _emailController.text.trim();
                final username = _userNameCodeController.text.trim();
                final password = _passwordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();
                final schoolCode = _schoolCodeController.text.trim();
                final school = _selectedSchool;

                if (email.isEmpty ||
                    username.isEmpty ||
                    password.isEmpty ||
                    confirmPassword.isEmpty ||
                    schoolCode.isEmpty ||
                    school == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all the fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Stop here, do not call _createAccount
                }

                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Stop here
                }

                // Step 2: Call _createAccount since all fields are valid
                _createAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            // Optional: Terms & Privacy
            Text(
              'By creating an account, you agree to our Terms & Privacy Policy.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  }
}
