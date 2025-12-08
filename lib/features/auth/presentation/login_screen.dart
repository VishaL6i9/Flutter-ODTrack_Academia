import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';

import 'package:odtrack_academia/providers/auth_provider.dart';
import 'package:odtrack_academia/shared/widgets/form_field.dart';
import 'package:odtrack_academia/shared/widgets/form.dart';
import 'package:odtrack_academia/utils/form_validators.dart';

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

  // Student login controllers
  final _registerNumberController = TextEditingController();
  DateTime? _selectedDate;

  // Staff login controllers
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go(AppConstants.dashboardRoute);
      }
      if (next.error != null) {
        // Show enhanced error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(next.error!)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildTabBar(),
              const SizedBox(height: 24),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStudentLogin(authState.isLoading),
                    _buildStaffLogin(authState.isLoading),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.school,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'OD Request Management System',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(
            icon: Icon(Icons.person),
            text: 'Student',
          ),
          Tab(
            icon: Icon(Icons.work),
            text: 'Staff',
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLogin(bool isLoading) {
    return EnhancedForm(
      formKey: _studentFormKey,
      onSubmit: _handleStudentLogin,
      isSubmitting: isLoading,
      submitButtonText: 'Login',
      submitButtonIcon: Icons.login,
      child: Column(
        children: [
          EnhancedFormField(
            controller: _registerNumberController,
            label: 'Register Number',
            hint: 'Enter your register number',
            prefixIcon: Icons.badge,
            validators: [
              RequiredValidator(fieldName: 'Register number'),
              RegisterNumberValidator(),
            ],
            helpText: 'Use your official college register number',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: EnhancedFormField(
              label: 'Date of Birth',
              hint: _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Select your date of birth',
              prefixIcon: Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (_selectedDate == null) {
                  return 'Please select your date of birth';
                }
                return null;
              },
              helpText: 'Select your date of birth for verification',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Demo: Use any register number with any date',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLogin(bool isLoading) {
    return EnhancedForm(
      formKey: _staffFormKey,
      onSubmit: _handleStaffLogin,
      isSubmitting: isLoading,
      submitButtonText: 'Login',
      submitButtonIcon: Icons.login,
      child: Column(
        children: [
          EnhancedFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email address',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validators: [
              RequiredValidator(fieldName: 'Email'),
              EmailValidator(),
            ],
            helpText: 'Use your official college email address',
          ),
          const SizedBox(height: 16),
          EnhancedPasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            validators: [
              RequiredValidator(fieldName: 'Password'),
            ],
            showStrengthIndicator: false,
            helpText: 'Enter your account password',
          ),
          const SizedBox(height: 16),
          Text(
            'Demo: Use any email and password',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleStudentLogin() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please select your date of birth'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }
    
    ref.read(authProvider.notifier).loginStudent(
      _registerNumberController.text,
      _selectedDate!,
    );
  }

  void _handleStaffLogin() {
    ref.read(authProvider.notifier).loginStaff(
      _emailController.text,
      _passwordController.text,
    );
  }
}
