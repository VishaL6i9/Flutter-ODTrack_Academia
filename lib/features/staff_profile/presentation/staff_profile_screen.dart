import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:odtrack_academia/providers/auth_provider.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _departmentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user!;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _departmentController = TextEditingController(text: user.department ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: _saveProfile,
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              )
            else
              IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 32),
                _buildProfileForm(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (user.name as String).split(' ').map((String n) => n[0]).take(2).join(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              (user.role as String).toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _nameController,
              label: 'Full Name',
              icon: MdiIcons.account,
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _emailController,
              label: 'Email',
              icon: MdiIcons.email,
              enabled: false, // Email shouldn't be editable
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: MdiIcons.phone,
              validator: (value) {
                if (value?.isNotEmpty == true && !RegExp(r'^\+?[\d\s-()]+$').hasMatch(value!)) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _departmentController,
              label: 'Department',
              icon: MdiIcons.domain,
              validator: (value) => value?.isEmpty == true ? 'Department is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing && enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !(_isEditing && enabled),
        fillColor: !(_isEditing && enabled) ? Colors.grey[100] : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isEditing) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(MdiIcons.key, color: Colors.blue),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
            ListTile(
              leading: Icon(MdiIcons.bell, color: Colors.orange),
              title: const Text('Notification Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.help, color: Colors.green),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact IT Support: support@academia.edu')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this would call an API to update the profile
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelEditing() {
    // Reset form fields to original values
    final user = ref.read(authProvider).user!;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
    _departmentController.text = user.department ?? '';
    
    setState(() => _isEditing = false);
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }
}
