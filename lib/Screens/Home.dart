// Screens/Home.dart
import 'package:flutter/material.dart';
import '../Colors/theme.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../widgets/FeatureGate.dart';
import 'Signup.dart';
import 'HistoryScreen.dart';
import 'AddMedicationScreen.dart';
import 'ChatBotScreen.dart';
import 'ProfileScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final SessionManager _sessionManager = SessionManager();
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isGuest = await _sessionManager.isGuestMode();
    setState(() {
      _isGuest = isGuest;
    });
  }

  // Updated navigation items with new screens
  static const List<BottomNavigationBarItem> _navBarItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline,size: 32),
      activeIcon: Icon(Icons.add_circle,size: 32),
      label: 'Add',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  // Screens list
  late final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const AddMedicationScreen(),
    const ChatBotScreen(),
    ProfileScreen(isGuest: _isGuest),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    if (_isGuest) {
      await _sessionManager.endGuestSession();
    } else {
      await _authService.signOut();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SecondScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MEDICATA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.textSecondaryDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textSecondaryDark),
      ),

      // Drawer
      drawer: Drawer(
        child: Container(
          color: AppColors.primaryLight,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentLight, AppColors.secondaryLight],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _isGuest ? Icons.person_outline : Icons.person,
                        size: 35,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isGuest ? 'Guest User' : 'Registered User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isGuest ? 'Limited Features' : 'Full Access',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Items
              ListTile(
                leading: Icon(Icons.home, color: AppColors.textSecondaryDark),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(0);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: AppColors.textSecondaryDark,
                ),
                title: const Text('History'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(1);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.add_circle,
                  color: AppColors.textSecondaryDark,
                ),
                title: const Text('Add Medication'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(2);
                },
              ),
              ListTile(
                leading: Icon(Icons.chat, color: AppColors.textSecondaryDark),
                title: const Text('AI Chat Bot'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(3);
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: AppColors.textSecondaryDark),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(4);
                },
              ),

              const Divider(),

              // Upgrade option for guests
              if (_isGuest)
                ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: const Text(
                    'Upgrade Account',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Get full features'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecondScreen(),
                      ),
                    );
                  },
                ),

              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: AppColors.textSecondaryDark,
                ),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),
              ListTile(
                leading: Icon(Icons.help, color: AppColors.textSecondaryDark),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to help
                },
              ),
              ListTile(
                leading: Icon(Icons.info, color: AppColors.textSecondaryDark),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show about dialog
                },
              ),

              const Divider(),

              // Logout at bottom
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
              ),
            ],
          ),
        ),
      ),

      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.accentLight,
        unselectedItemColor: AppColors.textSecondaryDark,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryLight,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}

// Individual Screen Widgets

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 100,
              color: AppColors.accentLight,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Medicata',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your personal medication assistant',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            _buildQuickActionCard(
              context,
              'Today\'s Medications',
              Icons.medication,
              '3 pending',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentLight, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to medication details
        },
      ),
    );
  }
}
