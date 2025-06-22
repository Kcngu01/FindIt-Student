import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/characteristic.dart';
import '../providers/login_provider.dart';
import '../providers/item_provider.dart';
import '../services/item_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'add_item_screen.dart';
import '../config/api_config.dart';
import '../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool isInTabNavigator;

  const HomeScreen({
    super.key,
    this.isInTabNavigator = false,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showSearchClear = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
     // Add listeners to search controller
    _searchController.addListener(_onSearchChanged);
    _searchController.addListener(() {
      setState(() {
        _showSearchClear = _searchController.text.isNotEmpty;
      });
    });
    
    // Initialize data
    // Use post-frame callback to avoid build-time state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        itemProvider.loadItems();
        itemProvider.loadFilterCharacteristics();
        
        // Check for unread notifications
        Provider.of<NotificationProvider>(context, listen: false).checkUnreadNotifications();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _logout(LoginProvider loginProvider) async {
    try {
      await loginProvider.logout();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      
      // Clear the entire navigation stack and go to login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // This predicate returns false for all routes, removing everything
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  // Debounce search to avoid excessive API calls
  void _onSearchChanged() {
    // Simple debounce
    Future.delayed(const Duration(milliseconds: 500), () {
      // Only proceed if the text hasn't changed in the last 500ms
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      if (itemProvider.searchQuery != _searchController.text) {
        if (!mounted) return;
        
        final query = _searchController.text.isNotEmpty ? _searchController.text : null;
        itemProvider.updateSearchQuery(query);
      }
    });
  }

  // void _onNavTap(int index) {
  //   if (index == 2) {
  //     // Navigate to the add item screen when the '+' button is pressed
  //     Navigator.pushNamed(
  //       context,
  //       '/add_item',
  //     ).then((needsRefresh) {
  //       // Refresh the items list if the screen returns with true (item added)
  //       if (needsRefresh == true) {
  //         if (!mounted) return;
  //         Provider.of<ItemProvider>(context, listen: false).loadItems();
  //       }
  //     });
  //   } else if (index == 1) {
  //     // Navigate to my items screen
  //     final loginProvider = Provider.of<LoginProvider>(context, listen: false);
  //     final studentId = loginProvider.student?.id;
      
  //     if (studentId != null) {
  //       // Preload user items before navigating
  //       Provider.of<ItemProvider>(context, listen: false).loadUserItems(studentId);
  //     }
      
  //     Navigator.pushNamed(
  //       context,
  //       '/my_items',
  //     ).then((_) {
  //       // Reset to home tab when returning
  //       if (mounted) {
  //         setState(() {
  //           _selectedIndex = 0;
  //         });
  //       }
  //     });
  //   } else if (index == 3) {
  //     // Navigate to notifications screen
  //     Navigator.pushNamed(
  //       context,
  //       '/notifications',
  //     ).then((_) {
  //       // Reset to home tab when returning
  //       if (mounted) {
  //         setState(() {
  //           _selectedIndex = 0;
  //         });
  //       }
  //     });
  //   } else if (index == 4) {
  //     Navigator.pushNamed(
  //       context,
  //       '/more',
  //     );
  //   } else {
  //     setState(() {
  //       _selectedIndex = index;
  //     });
  //   }
  // }

  // Show the filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    // Get current filter values from provider
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    int? tempCategoryId = itemProvider.filterCategoryId;
    int? tempColorId = itemProvider.filterColorId;
    int? tempLocationId = itemProvider.filterLocationId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and clear button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                tempCategoryId = null;
                                tempColorId = null;
                                tempLocationId = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category filter
                      _buildFilterDropdown(
                        title: 'Category',
                        items: itemProvider.categories,
                        value: tempCategoryId,
                        onChanged: (value) {
                          setState(() {
                            tempCategoryId = value;
                          });
                        },
                        loading: itemProvider.loadingCharacteristics,
                      ),
                      const SizedBox(height: 16),
                      
                      // Color filter
                      _buildFilterDropdown(
                        title: 'Color',
                        items: itemProvider.colors,
                        value: tempColorId,
                        onChanged: (value) {
                          setState(() {
                            tempColorId = value;
                          });
                        },
                        loading: itemProvider.loadingCharacteristics,
                      ),
                      const SizedBox(height: 16),
                      
                      // Location filter
                      _buildFilterDropdown(
                        title: 'Location',
                        items: itemProvider.locations,
                        value: tempLocationId,
                        onChanged: (value) {
                          setState(() {
                            tempLocationId = value;
                          });
                        },
                        loading: itemProvider.loadingCharacteristics,
                      ),
                      
                      const Spacer(),
                      
                      // Apply filter button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Apply filters and close the bottom sheet
                            Navigator.pop(context);
                            
                            // Only reload if filters actually changed
                            if (itemProvider.filterCategoryId != tempCategoryId) {
                              itemProvider.updateCategoryFilter(tempCategoryId);
                            }
                            
                            if (itemProvider.filterColorId != tempColorId) {
                              itemProvider.updateColorFilter(tempColorId);
                            }
                            
                            if (itemProvider.filterLocationId != tempLocationId) {
                              itemProvider.updateLocationFilter(tempLocationId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }
  
  // Build a dropdown for a filter option
  Widget _buildFilterDropdown({
    required String title,
    required List<Characteristic> items,
    required int? value,
    required Function(int?) onChanged,
    required bool loading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loading)
          const LinearProgressIndicator(minHeight: 2)
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(title),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                style: const TextStyle(color: Colors.black),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onChanged: onChanged,
                items: [
                  // 'All' option with the title as the display text
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(title),
                  ),
                  // Dynamic items
                  ...items.map<DropdownMenuItem<int>>((characteristic) {
                    return DropdownMenuItem<int>(
                      value: characteristic.id,
                      child: Text(characteristic.name),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoginProvider, ItemProvider>(
      builder: (context, loginProvider, itemProvider, child) {
        final student = loginProvider.student;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Item Listing'),
            // Hide the back button when in tab navigator
            automaticallyImplyLeading: !widget.isInTabNavigator,
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.logout),
            //     onPressed: () => _logout(loginProvider),
            //   ),
            // ],
          ),
          body: Column(
            children: [
              // Search bar and filter icon
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                // Add a clear button that clears the search when pressed
                                suffixIcon: _showSearchClear
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          itemProvider.updateSearchQuery(null);
                                          setState(() {
                                            _showSearchClear = false;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              autocorrect: false,
                              enableSuggestions: false, 
                              onSubmitted: (value) {
                                itemProvider.updateSearchQuery(
                                  value.isNotEmpty ? value : null
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.filter_list),
                                onPressed: () {
                                  _showFilterBottomSheet(context);
                                },
                              ),
                              // Show a dot indicator if any filter is active
                              if (itemProvider.filterCategoryId != null || 
                                  itemProvider.filterColorId != null || 
                                  itemProvider.filterLocationId != null)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Active filter chips
                    if (itemProvider.filterCategoryId != null || 
                        itemProvider.filterColorId != null || 
                        itemProvider.filterLocationId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (itemProvider.filterCategoryId != null)
                                _buildFilterChip(
                                  'Category: ${itemProvider.getCategoryName(itemProvider.filterCategoryId!)}',
                                  () => itemProvider.updateCategoryFilter(null),
                                ),
                              if (itemProvider.filterColorId != null)
                                _buildFilterChip(
                                  'Color: ${itemProvider.getColorName(itemProvider.filterColorId!)}',
                                  () => itemProvider.updateColorFilter(null),
                                ),
                              if (itemProvider.filterLocationId != null)
                                _buildFilterChip(
                                  'Location: ${itemProvider.getLocationName(itemProvider.filterLocationId!)}',
                                  () => itemProvider.updateLocationFilter(null),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Filter tabs - Found/Lost/Recovered
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab('found', 'Found', itemProvider),
                      _buildFilterTab('lost', 'Lost', itemProvider),
                      _buildFilterTab('recovered', 'Recovered', itemProvider),
                    ],
                  ),
                ),
              ),

              // Grid of items
              Expanded(
                child: itemProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : itemProvider.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(itemProvider.error!,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => itemProvider.loadItems(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : itemProvider.items.isEmpty
                            ? const Center(child: Text('No items found'))
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: RefreshIndicator(
                                  onRefresh: () => itemProvider.loadItems(),
                                  child: GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16.0,
                                      mainAxisSpacing: 16.0,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemCount: itemProvider.items.length,
                                    itemBuilder: (context, index) {
                                      final item = itemProvider.items[index];
                                      return InkWell(
                                        onTap: () {
                                          // Navigate to item details
                                          Navigator.pushNamed(
                                            context,
                                            '/item_details',
                                            arguments: item.id,
                                          );
                                        },
                                        child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                      top: Radius.circular(8.0),
                                                    ),
                                                  ),
                                                  width: double.infinity,
                                                  child: item.image
                                                              ?.isNotEmpty ??
                                                          false
                                                      ? Image.network(
                                                          ApiConfig.getItemImageUrl(item.image!, item.type),
                                                          fit: BoxFit.contain,
                                                          errorBuilder:(context, error,stackTrace) {
                                                            print("image error:$error");  
                                                            return Center(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(
                                                                    Icons.image,
                                                                    size: 40,
                                                                    color: Colors.grey[400],
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Text(
                                                                    'No Image',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      color: Colors.grey[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Center(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(
                                                                Icons.image,
                                                                size: 40,
                                                                color: Colors.grey[400],
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                'No Image',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.grey[600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: item.type ==
                                                                'lost'
                                                            ? Colors.red[100]
                                                            : item.type ==
                                                                    'found'
                                                                ? Colors
                                                                    .green[100]
                                                                : Colors
                                                                    .blue[100],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        item.type.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: item.type ==
                                                                  'lost'
                                                              ? Colors.red[800]
                                                              : item.type ==
                                                                      'found'
                                                                  ? Colors.green[
                                                                      800]
                                                                  : Colors.blue[
                                                                      800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
              ),
            ],
          ),
          // bottomNavigationBar: widget.isInTabNavigator ? null : CustomBottomNavBar(
          //   currentIndex: _selectedIndex,
          //   onTap: _onNavTap,
          // ),
        );
      },
    );
  }

  // Helper function to build filter chips
  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.cancel, size: 18),
        onDeleted: onDelete,
        backgroundColor: Colors.grey[200],
        deleteIconColor: Colors.grey[700],
        labelStyle: TextStyle(color: Colors.grey[800], fontSize: 12),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterTab(String type, String label, ItemProvider itemProvider) {
    return Expanded(
      child: InkWell(
        onTap: () => itemProvider.updateFilterType(type),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: itemProvider.filterType == type ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: itemProvider.filterType == type ? Colors.black : Colors.grey[600],
              fontWeight: itemProvider.filterType == type ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
