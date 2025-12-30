import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  User? _currentUser;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
    
    // Listen to auth state changes to update UI when user data changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.userUpdated || event == AuthChangeEvent.signedIn) {
        if (mounted) {
          _loadUserData();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_isEditing && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get current user without refreshing session (faster)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Get the latest user metadata
        final metadata = user.userMetadata ?? {};
        final appMetadata = user.appMetadata ?? {};
        
        if (mounted) {
          setState(() {
            _currentUser = user;
            // Try multiple sources for name
            final name = metadata['full_name'] ?? 
                        metadata['name'] ?? 
                        appMetadata['full_name'] ??
                        appMetadata['name'] ??
                        user.email?.split('@')[0] ?? '';
            _nameController.text = name;
            _emailController.text = user.email ?? '';
            // Try multiple sources for phone
            _phoneController.text = metadata['phone'] ?? 
                                   appMetadata['phone'] ??
                                   user.phone ?? '';
          });
        }
      } else if (mounted) {
        // No user logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your profile'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted && !_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadUserData,
            ),
          ),
        );
      }
    } finally {
      if (mounted && !_isEditing) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          _emailNotifications = prefs.getBool('email_notifications') ?? true;
          _pushNotifications = prefs.getBool('push_notifications') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Basic phone validation (digits, spaces, dashes, parentheses, plus)
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    if (value.trim().length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check if anything actually changed
      final currentName = user.userMetadata?['full_name'] ?? 
                         user.userMetadata?['name'] ?? 
                         user.email?.split('@')[0] ?? '';
      final currentPhone = user.userMetadata?['phone'] ?? 
                          user.phone ?? '';

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      if (currentName == newName && currentPhone == newPhone) {
        // No changes made
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes to save'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Update user metadata
      final updates = <String, dynamic>{
        'full_name': newName,
        'name': newName,
      };

      if (newPhone.isNotEmpty) {
        updates['phone'] = newPhone;
      }

      // Update user metadata via Supabase
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );

      final updatedUser = response.user;
      if (updatedUser != null) {
        // Update the current user reference immediately with new data
        final metadata = updatedUser.userMetadata ?? {};
        
        if (mounted) {
          setState(() {
            _currentUser = updatedUser;
            // Update controllers with new values immediately
            _nameController.text = metadata['full_name'] ?? 
                                 metadata['name'] ?? 
                                 (updatedUser.email?.split('@')[0] ?? '');
            _phoneController.text = metadata['phone'] ?? 
                                   updatedUser.phone ?? 
                                   '';
            _isEditing = false;
          });
        }

        // Show success message with animation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Refresh session in background (non-blocking)
        _refreshSessionInBackground();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error updating profile: ${e.toString().split(':').last.trim()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _refreshSessionInBackground() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.refreshSession();
      }
    } catch (e) {
      // Session refresh failed, but we already have the updated user
      debugPrint('Session refresh failed (non-critical): $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout? You will need to sign in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Navigate to login or home page
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification settings saved'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ResponsiveLayout(
      currentRoute: '/settings',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          elevation: 0,
        ),
        body: _isLoading && _currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadUserData();
                  await _loadSettings();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildSection(
                        title: 'Profile',
                        icon: Icons.person,
                        children: [
                          if (!_isEditing) ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: KeyedSubtree(
                                key: ValueKey('profile_${_currentUser?.id}_${_nameController.text}'),
                                child: _buildProfileInfo(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ] else ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.cardColor,
                                    ),
                                    textCapitalization: TextCapitalization.words,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      if (value.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.cardColor,
                                      helperText: 'Email cannot be changed here',
                                    ),
                                    enabled: false,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number (Optional)',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: theme.cardColor,
                                      hintText: '+1 (555) 123-4567',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: _validatePhone,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isSaving ? null : () {
                                            setState(() {
                                              _isEditing = false;
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSaving ? null : _saveProfile,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: _isSaving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Text('Save Changes'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Appearance Section
                      _buildSection(
                        title: 'Appearance',
                        icon: Icons.palette,
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    themeProvider.themeMode == ThemeMode.dark
                                        ? Icons.dark_mode
                                        : themeProvider.themeMode == ThemeMode.light
                                            ? Icons.light_mode
                                            : Icons.brightness_auto,
                                    ),
                                  title: const Text('Theme'),
                                  subtitle: Text(
                                    themeProvider.themeMode == ThemeMode.dark
                                        ? 'Dark mode'
                                        : themeProvider.themeMode == ThemeMode.light
                                            ? 'Light mode'
                                            : 'System default',
                                  ),
                                  trailing: DropdownButton<ThemeMode>(
                                    value: themeProvider.themeMode,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: ThemeMode.system,
                                        child: Row(
                                          children: [
                                            Icon(Icons.brightness_auto, size: 20),
                                            SizedBox(width: 8),
                                            Text('System'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: ThemeMode.light,
                                        child: Row(
                                          children: [
                                            Icon(Icons.light_mode, size: 20),
                                            SizedBox(width: 8),
                                            Text('Light'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: ThemeMode.dark,
                                        child: Row(
                                          children: [
                                            Icon(Icons.dark_mode, size: 20),
                                            SizedBox(width: 8),
                                            Text('Dark'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        themeProvider.setThemeMode(value);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Notifications Section
                      _buildSection(
                        title: 'Notifications',
                        icon: Icons.notifications,
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_active),
                            title: const Text('Enable Notifications'),
                            subtitle: const Text('Receive notifications for important updates'),
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                              _saveNotificationSettings();
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          if (_notificationsEnabled) ...[
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const Icon(Icons.email),
                              title: const Text('Email Notifications'),
                              subtitle: const Text('Receive notifications via email'),
                              value: _emailNotifications,
                              onChanged: (value) {
                                setState(() {
                                  _emailNotifications = value;
                                });
                                _saveNotificationSettings();
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: const Icon(Icons.phone_android),
                              title: const Text('Push Notifications'),
                              subtitle: const Text('Receive push notifications on your device'),
                              value: _pushNotifications,
                              onChanged: (value) {
                                setState(() {
                                  _pushNotifications = value;
                                });
                                _saveNotificationSettings();
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Account Section
                      _buildSection(
                        title: 'Account',
                        icon: Icons.account_circle,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('User ID'),
                            subtitle: Text(
                              _currentUser?.id ?? 'Not available',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Member Since'),
                            subtitle: Text(
                              _currentUser?.createdAt != null
                                  ? _formatDate(_currentUser!.createdAt)
                                  : 'Not available',
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                            onTap: _handleLogout,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // About Section
                      _buildSection(
                        title: 'About',
                        icon: Icons.info,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.apps),
                            title: const Text('App Version'),
                            subtitle: const Text('1.0.0'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Terms of Service'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to terms page
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Terms of Service coming soon')),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to privacy policy page
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Privacy Policy coming soon')),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    // Get the current values from controllers or user
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (_currentUser?.userMetadata?['full_name'] ?? 
           _currentUser?.userMetadata?['name'] ?? 
           _currentUser?.email?.split('@')[0] ?? 
           'Not set');
    
    final displayEmail = _emailController.text.isNotEmpty
        ? _emailController.text
        : (_currentUser?.email ?? 'Not set');
    
    final displayPhone = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : (_currentUser?.userMetadata?['phone'] ?? 
           _currentUser?.phone ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  displayName != 'Not set' && displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : _currentUser?.email?[0].toUpperCase() ?? 'U',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoRow(
          icon: Icons.person,
          label: 'Name',
          value: displayName,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.email,
          label: 'Email',
          value: displayEmail,
        ),
        if (displayPhone.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone,
            label: 'Phone',
            value: displayPhone,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
