// lib/widgets/feature_gate.dart
import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../utils/feature_flags.dart';
import '../Screens/Signup.dart';

class FeatureGate extends StatelessWidget {
  final String featureName;
  final Widget child;
  final Widget? fallback;

  const FeatureGate({
    Key? key,
    required this.featureName,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFeatureAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return fallback ?? _buildUpgradePrompt(context);
      },
    );
  }

  Future<bool> _checkFeatureAccess() async {
    final sessionManager = SessionManager();
    final isGuest = await sessionManager.isGuestMode();
    return FeatureFlags.canUseFeature(featureName, isGuest);
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Feature Locked',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Create an account to access this feature',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SecondScreen()),
              );
            },
            child: Text('Sign Up Now'),
          ),
        ],
      ),
    );
  }
}