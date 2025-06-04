import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'my_items_screen.dart';
import 'more_screen.dart';
import 'notifications_screen.dart';
import '../providers/login_provider.dart';
import '../providers/item_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  //latest index choose by user
  late int _currentIndex;
  
  // Keep instances of the screens to maintain their state
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Maintains the state of which tab is currently selected across the entire widget. It's updated when navigation occurs and persists between builds.
    _currentIndex = widget.initialIndex;
    
    // Initialize screens
    // these screens directly correspond to the indices used in the _onNavTap method and in the navigation bar.
    // Index 0 is HomeScreen, 
    // index 1 is MyItemsScreen,
    // index 2 is a placeholder (the add item button that triggers a push navigation instead), 
    // index 3 is NotificationsScreen, and 
    // index 4 is MoreScreen. This makes the currently selected screen accessible via _screens[_currentIndex].
    _screens = [
      const HomeScreen(isInTabNavigator: true),
      const MyItemsScreen(isInTabNavigator: true),
      Container(), // Placeholder for add item
      const NotificationsScreen(isInTabNavigator: true),
      const MoreScreen(isInTabNavigator: true),
    ];
    
    // Check for unread notifications when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).checkUnreadNotifications();
      }
    });
  }
  
  void _onNavTap(int index) {
    if (index == 2) {
      // Navigate to the add item screen when the '+' button is pressed
      Navigator.pushNamed(
        context,
        '/add_item',
      ).then((needsRefresh) {
        // Refresh the items list if the screen returns with true (item added)
        if (needsRefresh == true) {
          if (!mounted) return;
          Provider.of<ItemProvider>(context, listen: false).loadItems();
        }
      });
    } else {
      // Handle preloading data for specific tabs if needed
      if (index == 1) {
        // It will reload user items EVERY time the tab is tapped
// Even if you're already on the My Items tab and tap it again, it triggers another data reload
        // Always reload user items when switching to My Items tab
        final loginProvider = Provider.of<LoginProvider>(context, listen: false);
        final studentId = loginProvider.student?.id;
        
        if (studentId != null) {
          final itemProvider = Provider.of<ItemProvider>(context, listen: false);
          // Use the current filter type from the My Items screen or default to 'lost'
          final filterType = itemProvider.userItems.isNotEmpty && 
                           itemProvider.userItems.first.type == 'found' ? 'found' : 'lost';
          itemProvider.loadUserItems(studentId, type: filterType);
        }
      } else if (index == 3 && _currentIndex != 3) {
        // index == 3 checks if the user is navigating TO the Notifications tab
        // _currentIndex != 3 ensures this code only runs when SWITCHING to the tab from elsewhere
        // run this code only if the user is switching to the notifications tab
        // Preload notifications when switching to Notifications tab
        Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      } else if (index == 0 && _currentIndex != 0) {
        // Refresh home screen items when switching back to home
        Provider.of<ItemProvider>(context, listen: false).loadItems();
      }
      
      // For index 0 (Home) and index 4 (More), there's no special preloading logic implemented like there is for index 1 (My Items) and index 3 (Notifications). This is intentional because:
      // These screens likely don't require special data preloading when navigating to them
      // They probably load their data independently in their own initState() methods or when they become visible
      // The code simply updates _currentIndex for these tabs, which causes the IndexedStack to show the corresponding screen without additional preparation steps.

      // Update the current index to switch screens
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
} 