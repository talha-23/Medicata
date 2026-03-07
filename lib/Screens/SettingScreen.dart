// Screens/SettingsScreen.dart
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SessionManager _sessionManager = SessionManager();
  final AuthService _authService = AuthService();
  
  bool _isGuest = false;
  bool _isLoading = true;
  
  // Notification Settings
  bool _medicationReminders = true;
  bool _reminderSound = true;
  bool _vibration = true;
  String _snoozeDuration = '10';
  
  // Medication Settings
  String _defaultReminderTime = '30';
  bool _missedDoseAlert = true;
  bool _dailySummary = true;
  
  // Privacy Settings
  bool _appLock = false;
  
  // Snooze options
  final List<String> _snoozeOptions = ['5', '10', '15'];
  
  // Reminder time options
  final List<String> _reminderTimeOptions = ['15', '30', '45', '60'];

  @override
  void initState() {
    super.initState();
    _loadUserType();
    _loadSettings();
  }

  Future<void> _loadUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
    setState(() {
      _isGuest = isGuest;
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    // Load saved settings from SharedPreferences or database
    // This is placeholder - implement actual loading logic
  }

  Future<void> _saveSettings() async {
    // Save settings logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentLight),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.accentLight,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section
            _buildProfileCard(),
            const SizedBox(height: 16),

            // Notification Settings
            _buildSectionHeader('Notification Settings', Icons.notifications_active),
            _buildNotificationCard(),
            const SizedBox(height: 16),

            // Medication Settings
            _buildSectionHeader('Medication Settings', Icons.medication),
            _buildMedicationCard(),
            const SizedBox(height: 16),

            // Privacy and Security
            _buildSectionHeader('Privacy & Security', Icons.security),
            _buildPrivacyCard(),
            const SizedBox(height: 16),

            // Data and Backup
            _buildSectionHeader('Data & Backup', Icons.cloud),
            _buildDataCard(),
            const SizedBox(height: 16),

            // Support and Help
            _buildSectionHeader('Support & Help', Icons.support_agent),
            _buildSupportCard(),
            const SizedBox(height: 16),

            // About
            _buildSectionHeader('About', Icons.info_outline),
            _buildAboutCard(),
            const SizedBox(height: 30),

            // App Version
            Text(
              'Medicata v1.0.0',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentLight, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = _authService.currentUser;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Photo
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentLight, width: 3),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: !_isGuest && user?.photoURL != null
                      ? NetworkImage(user!.photoURL!) as ImageProvider<Object>
                      : null,
                  child: !_isGuest && user?.photoURL != null
                      ? null
                      : Icon(
                          _isGuest ? Icons.person_outline : Icons.person,
                          size: 40,
                          color: AppColors.accentLight,
                        ),
                ),
              ),
              const SizedBox(width: 20),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isGuest ? 'Guest User' : (user?.displayName ?? 'User Name'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isGuest ? 'Age: --' : 'Age: 32 years',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isGuest ? 'Guest Account' : 'Registered User',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Edit Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    // Navigate to edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile - Coming Soon!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Medication Reminders Toggle
            _buildSwitchTile(
              icon: Icons.notifications_active,
              title: 'Medication Reminders',
              value: _medicationReminders,
              onChanged: (value) => setState(() => _medicationReminders = value),
            ),
            const Divider(height: 24),
            
            // Reminder Sound
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: 'Reminder Sound',
              value: _reminderSound,
              onChanged: (value) => setState(() => _reminderSound = value),
            ),
            const Divider(height: 24),
            
            // Vibration
            _buildSwitchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              value: _vibration,
              onChanged: (value) => setState(() => _vibration = value),
            ),
            const Divider(height: 24),
            
            // Snooze Duration
            _buildDropdownTile(
              icon: Icons.timer,
              title: 'Snooze Duration',
              value: _snoozeDuration,
              items: _snoozeOptions,
              onChanged: (value) => setState(() => _snoozeDuration = value!),
              suffix: 'minutes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Default Reminder Time
            _buildDropdownTile(
              icon: Icons.access_time,
              title: 'Reminder before dose',
              value: _defaultReminderTime,
              items: _reminderTimeOptions,
              onChanged: (value) => setState(() => _defaultReminderTime = value!),
              suffix: 'minutes',
            ),
            const Divider(height: 24),
            
            // Missed Dose Alert
            _buildSwitchTile(
              icon: Icons.warning_amber,
              title: 'Missed Dose Alert',
              value: _missedDoseAlert,
              onChanged: (value) => setState(() => _missedDoseAlert = value),
            ),
            const Divider(height: 24),
            
            // Daily Summary
            _buildSwitchTile(
              icon: Icons.summarize,
              title: 'Daily Medication Summary',
              value: _dailySummary,
              onChanged: (value) => setState(() => _dailySummary = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Lock Toggle
            _buildSwitchTile(
              icon: Icons.lock,
              title: 'App Lock (PIN/Fingerprint)',
              value: _appLock,
              onChanged: (value) => setState(() => _appLock = value),
            ),
            const Divider(height: 24),
            
            // Manage Data Permissions
            _buildActionTile(
              icon: Icons.security,
              title: 'Manage Data Permissions',
              onTap: () => _showComingSoon('Manage Permissions'),
            ),
            const Divider(height: 24),
            
            // Clear App Data
            _buildActionTile(
              icon: Icons.delete_sweep,
              title: 'Clear App Data',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _showClearDataDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Backup to Cloud
            _buildActionTile(
              icon: Icons.cloud_upload,
              title: 'Backup Data to Cloud',
              onTap: () => _showComingSoon('Cloud Backup'),
            ),
            const Divider(height: 24),
            
            // Restore Data
            _buildActionTile(
              icon: Icons.cloud_download,
              title: 'Restore Medication Data',
              onTap: () => _showComingSoon('Restore Data'),
            ),
            const Divider(height: 24),
            
            // Export History
            _buildActionTile(
              icon: Icons.import_export,
              title: 'Export Medication History',
              onTap: () => _showComingSoon('Export Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Help Center
            _buildActionTile(
              icon: Icons.help_center,
              title: 'Help Center',
              onTap: () => _showComingSoon('Help Center'),
            ),
            const Divider(height: 24),
            
            // Contact Support
            _buildActionTile(
              icon: Icons.support_agent,
              title: 'Contact Support',
              onTap: () => _showComingSoon('Contact Support'),
            ),
            const Divider(height: 24),
            
            // Report Problem
            _buildActionTile(
              icon: Icons.report_problem,
              title: 'Report a Problem',
              onTap: () => _showComingSoon('Report Problem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Version
            _buildInfoTile(
              icon: Icons.info,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            const Divider(height: 24),
            
            // Privacy Policy
            _buildActionTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () => _showComingSoon('Privacy Policy'),
            ),
            const Divider(height: 24),
            
            // Terms & Conditions
            _buildActionTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () => _showComingSoon('Terms & Conditions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentLight, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accentLight,
          activeTrackColor: AppColors.accentLight.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? suffix,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentLight, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    suffix != null ? '$item $suffix' : item,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.accentLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.grey,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentLight, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.warning_amber, color: Colors.red, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Clear App Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will remove all your medication data and settings. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Data Cleared');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}