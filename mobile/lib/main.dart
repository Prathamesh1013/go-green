import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'config/supabase_config.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vehicle_details_screen.dart';
import 'screens/add_service_screen.dart';
import 'screens/upload_photos_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_issue_screen.dart';
import 'screens/vehicle_summary_screen.dart';
import 'screens/inventory_photos_screen.dart';
import 'widgets/bottom_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  debugPrint('✅ Supabase initialized successfully');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const OGManagerApp(),
    ),
  );
}

class OGManagerApp extends StatefulWidget {
  const OGManagerApp({super.key});

  @override
  State<OGManagerApp> createState() => _OGManagerAppState();
}

class _OGManagerAppState extends State<OGManagerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appProvider = context.read<AppProvider>();
    _router = GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatorKey,
      refreshListenable: appProvider,
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ScaffoldWithBottomNav(child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/vehicle/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VehicleDetailsScreen(vehicleId: id);
          },
        ),
        GoRoute(
          path: '/add-service/:id',
          builder: (context, state) => AddServiceScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/upload-photos/:id',
          builder: (context, state) => UploadPhotosScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/add-issue/:id',
          builder: (context, state) => AddIssueScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/vehicle-summary/:id',
          builder: (context, state) => VehicleSummaryScreen(vehicleId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/inventory-photos/:id',
          builder: (context, state) => InventoryPhotosScreen(vehicleId: state.pathParameters['id']!),
        ),
      ],
      redirect: (context, state) {
        // If not initialized, don't redirect yet
        if (!appProvider.isInitialized) {
          debugPrint('GoRouter: [WAIT] Provider not initialized. Staying at ${state.matchedLocation}');
          return null;
        }

        final isLoggedIn = appProvider.isLoggedIn;
        final currentPath = state.matchedLocation;
        final isLoggingIn = currentPath == '/login';
        
        debugPrint('GoRouter: [REDIRECT CHECK] Path: $currentPath, isLoggedIn: $isLoggedIn');

        // If not logged in and not on login page, go to login
        if (!isLoggedIn && !isLoggingIn) {
          debugPrint('GoRouter: [AUTH GUARD] Unauthorized access to $currentPath. Redirecting to /login');
          return '/login';
        }

        // Save current path for persistence if authorized
        if (isLoggedIn && !isLoggingIn && currentPath != '/') {
          appProvider.setLastRoute(currentPath);
        }
        
        // Recovery logic: if at root and logged in, check for saved route
        if (isLoggedIn && (currentPath == '/' || currentPath == '/dashboard')) {
          if (appProvider.lastRoute != null && appProvider.lastRoute != currentPath) {
            final target = appProvider.lastRoute!;
            debugPrint('GoRouter: [RECOVERY] Found saved route: $target');
            appProvider.clearLastRoute(); // Clear so it only happens once
            return target;
          }
        }
        
        // If logged in and on login page, go to dashboard
        if (isLoggedIn && isLoggingIn) {
          debugPrint('GoRouter: [AUTH GUARD] Already logged in. Redirecting from /login to /dashboard');
          return '/dashboard';
        }

        debugPrint('GoRouter: [AUTH GUARD] Proceeding to $currentPath');
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Error: ${state.error}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = context.watch<AppProvider>().isInitialized;

    if (!isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'OG Manager App',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}
