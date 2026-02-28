// Screens/ProfileScreen.dart
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screens/Signup.dart';

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, required this.isGuest});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  String? _userEmail;
  
  // Initialize with a default value instead of late
  bool _actualIsGuest = true; // Default to true, will be updated
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('========== PROFILE SCREEN INIT ==========');
    print('Initial widget.isGuest: ${widget.isGuest}');
    
    // Set initial value from widget
    _actualIsGuest = widget.isGuest;
    
    // Then verify the actual user type
    _verifyUserType();
  }

  Future<void> _verifyUserType() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check Firebase first
      User? currentUser = FirebaseAuth.instance.currentUser;
      bool hasFirebaseUser = currentUser != null && currentUser.emailVerified;
      
      print('Firebase check - hasFirebaseUser: $hasFirebaseUser');
      if (currentUser != null) {
        print('Firebase user email: ${currentUser.email}');
        print('Firebase verified: ${currentUser.emailVerified}');
      }
      
      if (hasFirebaseUser) {
        print('✅ Firebase verified user found - setting isGuest to false');
        setState(() {
          _actualIsGuest = false;
        });
        await _loadUserData();
      } else {
        // Check session manager
        final isGuest = await _sessionManager.isGuestMode();
        print('Session manager says isGuest: $isGuest');
        setState(() {
          _actualIsGuest = isGuest;
        });
        await _loadUserData();
      }
    } catch (e) {
      print('Error verifying user type: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (!_actualIsGuest) {
        // Registered user
        final user = _authService.currentUser;
        if (user != null) {
          setState(() {
            _userEmail = user.email;
          });
          final data = await _authService.getUserData(user.uid);
          setState(() {
            _userData = data;
          });
        }
      } else {
        // Guest user
        final guestData = await _sessionManager.getGuestData();
        setState(() {
          _userData = guestData;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('========== PROFILE SCREEN BUILD ==========');
    print('widget.isGuest: ${widget.isGuest}');
    print('_actualIsGuest: $_actualIsGuest');
    print('_isLoading: $_isLoading');
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.accentLight,
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accentLight,
                  child: Icon(
                    _actualIsGuest ? Icons.person_outline : Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _actualIsGuest 
                      ? 'Guest User' 
                      : (_userData?['username'] ?? _userData?['displayName'] ?? _userEmail ?? 'User'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (!_actualIsGuest && _userEmail != null)
                  Text(
                    _userEmail!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                const SizedBox(height: 10),
                
                // User type badge - using _actualIsGuest
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _actualIsGuest ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _actualIsGuest ? 'Guest Account' : 'Registered User',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (_actualIsGuest)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Limited Features',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Stats Section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Your Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Medications', '12', Icons.medication),
                      _buildStatItem('Days Tracked', '45', Icons.calendar_today),
                      _buildStatItem('Adherence', '94%', Icons.trending_up),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Type Specific Sections
          if (!_actualIsGuest) ...[
            // Registered User Features
            _buildSectionHeader('Premium Features'),
            _buildMenuItem(
              icon: Icons.cloud_sync,
              title: 'Cloud Sync',
              subtitle: 'Your data is backed up securely',
              onTap: () {
                // TODO: Implement cloud sync settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud Sync - Coming Soon!')),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              subtitle: 'Get reminders anywhere',
              onTap: () {
                // TODO: Implement notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Push Notifications - Coming Soon!')),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.analytics,
              title: 'Health Analytics',
              subtitle: 'Track your progress over time',
              onTap: () {
                // TODO: Implement analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health Analytics - Coming Soon!')),
                );
              },
            ),
          ],
          
          _buildSectionHeader('General Settings'),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Personal Information - Coming Soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming Soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy & Security - Coming Soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help Center - Coming Soon!')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              _showAboutDialog();
            },
          ),
          
          if (_actualIsGuest) ...[
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.accentLight, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    'Upgrade to Registered Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get access to AI chat, medication tracking, cloud sync, and more!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SecondScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLight,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accentLight, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accentLight, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null 
            ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)) 
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Medicata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png', 
              height: 100, 
              errorBuilder: (_, __, ___) => Icon(
                Icons.medical_services, 
                size: 100, 
                color: AppColors.accentLight
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Medicata v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your personal medication assistant. '
              'Track medications, get reminders, and chat with our AI assistant.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}