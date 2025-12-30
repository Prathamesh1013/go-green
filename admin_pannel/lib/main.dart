import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gogreen_admin/theme/app_theme.dart';
import 'package:gogreen_admin/routes/app_router.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/providers/job_provider.dart';
import 'package:gogreen_admin/providers/interaction_provider.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:gogreen_admin/config/supabase_config.dart';
import 'package:gogreen_admin/providers/analytics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    // Supabase not configured, will use mock data
    debugPrint('Supabase initialization failed: $e - using mock data');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const GoGreenAdminApp());
}

class GoGreenAdminApp extends StatelessWidget {
  const GoGreenAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => InteractionProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'GoGreen Fleet Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
