import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../controllers/feed_controller.dart';
import '../models/post.dart';
import '../routes.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

/// The home route: bottom navigation between Feed, Saved and the user's profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.deps.feed.load();
  }

  Future<void> _compose() async {
    final messenger = ScaffoldMessenger.of(context);
    // Untyped on purpose: routes from the `routes:` table are built as
    // Route<dynamic>, so `pushNamed<Post>` fails its runtime cast.
    final created = await Navigator.pushNamed(context, AppRoutes.compose);
    if (created is! Post) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Posted! The server confirmed it (201) and it is now at the top of your feed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          FeedScreen(deps: widget.deps),
          SavedScreen(deps: widget.deps),
          ProfileScreen(
            deps: widget.deps,
            userId: FeedController.currentUserId,
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _compose,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New post'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
