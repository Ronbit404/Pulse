import 'package:flutter/material.dart';

import 'app_dependencies.dart';
import 'routes.dart';
import 'screens/compose_screen.dart';
import 'screens/home_shell.dart';
import 'screens/post_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
import 'theme.dart';
import 'widgets/message_view.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => HomeShell(deps: deps),
        AppRoutes.details: (_) => PostDetailsScreen(deps: deps),
        AppRoutes.favorites: (_) => SavedScreen(deps: deps),
        AppRoutes.compose: (_) => ComposeScreen(deps: deps),
        AppRoutes.profile: (context) {
          final userId = ModalRoute.of(context)!.settings.arguments;
          if (userId is! int) {
            return const ErrorScaffold(
              title: 'Profile',
              message: 'No profile was selected.',
            );
          }
          return ProfileScreen(deps: deps, userId: userId);
        },
      },
    );
  }
}
