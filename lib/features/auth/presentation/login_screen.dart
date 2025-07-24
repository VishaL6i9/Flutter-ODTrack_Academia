import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _studentFormKey = GlobalKey<FormState>();
  final _staffFormKey = GlobalKey<FormState>();
  
  // Student form controllers
  final _registerNumberController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Staff form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _registerNumberController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App Logo and Title
              const Icon(
                Icons.school,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'ODTrack Academia™',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'OD Request Management System',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              
              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Student'),
                  Tab(text: 'Staff'),
                ],
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentLogin(),
                    _buildStaffLogin(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentLogin() {
    return Form(
      key: _studentFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _registerNumberController,
            decoration: const InputDecoration(
              labelText: 'Register Number',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your register number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth (DDMMYYYY)',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your date of birth';
              }
              if (value.length != 8) {
                return 'Please enter date in DDMMYYYY format';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleStudentLogin,
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLogin() {
    return Form(
      key: _staffFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleStaffLogin,
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStudentLogin() {
    if (_studentFormKey.currentState!.validate()) {
      // TODO: Implement student login logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student login not implemented yet')),
      );
    }
  }

  void _handleStaffLogin() {
    if (_staffFormKey.currentState!.validate()) {
      // TODO: Implement staff login logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff login not implemented yet')),
      );
    }
  }
}