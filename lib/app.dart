import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/irrigation_control/irrigation_control_screen.dart';
import 'screens/monitoring/monitoring_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/auth_service.dart';
import 'services/irrigation_service.dart';
import 'widgets/shared/bottom_nav_bar.dart';

class IrrigaTechApp extends StatelessWidget {
  const IrrigaTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IrrigaTech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthService>(
        builder: (context, auth, _) =>
            auth.isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    MonitoringScreen(),
    IrrigationControlScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();

    return Scaffold(
      body: IndexedStack(
        index: service.currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: service.currentTabIndex,
        onTap: (index) => service.setTabIndex(index),
      ),
    );
  }
}