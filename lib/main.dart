import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/providers/login_provider.dart';
import 'src/providers/item_provider.dart';
import 'src/providers/notification_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/add_item_screen.dart';
import 'src/screens/item_details_screen.dart';
import 'src/screens/email_verification_screen.dart';
import 'src/screens/forgot_password_screen.dart';
import 'src/screens/my_items_screen.dart';
import 'src/screens/my_item_details_screen.dart';
import 'src/screens/edit_item_screen.dart';
import 'src/screens/claims_screen.dart';
import 'src/screens/claim_details_screen.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/more_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/models/item.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/services/firebase_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Global navigator key to use for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Store the initial notification for handling after app is fully initialized
RemoteMessage? initialMessage;

// Flag to indicate if the app was launched from a notification
bool launchedFromNotification = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Get any initial notification that launched the app
  initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  
  // Set the flag if we have an initial message
  if (initialMessage != null) {
    launchedFromNotification = true;
    print("App launched from notification: ${initialMessage!.data}");
  }
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FirebaseMessagingService _messagingService;
  
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }
  
  Future<void> _initializeFirebaseMessaging() async {
    _messagingService = FirebaseMessagingService(
      onNotificationTapped: _handleNotificationTap,
    );
    await _messagingService.initialize();
    
    // Handle the initial message after the app is fully initialized
    if (initialMessage != null) {
      // Add a slight delay to ensure the app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage!);
      });
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    
    // Navigate to appropriate screen based on notification data
    if (message.data.containsKey('claim_id')) {
      try {
        // Convert the claim_id to an integer
        final claimId = int.parse(message.data['claim_id'].toString());
        
        // Use the global navigator key to navigate from anywhere
        if (launchedFromNotification) {
          // For terminated state, we need to first ensure the user is logged in
          // and then navigate to the claims screen
          
          // Check if we have a valid NavigatorState and context
          if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
            final loginProvider = Provider.of<LoginProvider>(
              navigatorKey.currentContext!,
              listen: false,
            );
            
            // Add a sufficient delay to ensure the splash screen has finished loading
            Future.delayed(const Duration(milliseconds: 1500), () {
              // If user is logged in, go directly to claim details
              if (loginProvider.token != null) {
                // First navigate to home screen to establish proper navigation stack
                navigatorKey.currentState!.pushReplacementNamed('/home');
                
                // Then after a brief delay, push the claim details screen
                Future.delayed(const Duration(milliseconds: 300), () {
                  navigatorKey.currentState!.pushNamed('/claim_details', arguments: claimId);
                });
              } else {
                // If user is not logged in, go to login screen
                // The user will need to log in before seeing the claim
                navigatorKey.currentState!.pushReplacementNamed('/login');
              }
            });
          }
        } else {
          // For foreground/background, we can navigate directly
          navigatorKey.currentState?.pushNamed('/claim_details', arguments: claimId);
        }
      } catch (e) {
        print('Error navigating to claim details: $e');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginProvider()),
        ChangeNotifierProvider(create: (context) => ItemProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Use the global navigator key
        initialRoute: '/splash', // Start with a splash screen
        routes: {
          '/splash': (context) => SplashScreen(launchedFromNotification: launchedFromNotification),
          '/register': (context) => const RegisterScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/add_item': (context) => const AddItemScreen(),
          '/email_verification': (context) => const EmailVerificationScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/my_items': (context) => const MyItemsScreen(),
          '/claims': (context) => const ClaimsScreen(),
          '/account': (context) => const AccountScreen(),
          '/more': (context) => const MoreScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/item_details') {
            // Extract the arguments - could be either an Item object or just an ID
            final args = settings.arguments;
            late int itemId;
            
            // Handle different argument types
            if (args is Item) {
              itemId = args.id;
            } else if (args is int) {
              itemId = args;
            } else {
              throw ArgumentError('Arguments must be either an Item or an integer itemId');
            }
            
            return MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(itemId: itemId),
            );
          } else if (settings.name == '/my_item_details') {
            // Extract the arguments - could be either an Item object or just an ID
            final args = settings.arguments;
            late int itemId;
            
            // Handle different argument types
            if (args is Item) {
              itemId = args.id;
            } else if (args is int) {
              itemId = args;
            } else {
              throw ArgumentError('Arguments must be either an Item or an integer itemId');
            }
            
            return MaterialPageRoute(
              builder: (context) => MyItemDetailsScreen(itemId: itemId),
            );
          } else if (settings.name == '/claim_details') {
            // Extract the claim ID
            final args = settings.arguments;
            late int claimId;
            String? similarityScore;
            bool fromMyItemDetails = false;
            
            // Handle different argument types
            if (args is int) {
              claimId = args;
            } else if (args is String) {
              // Try to parse string to int
              try {
                claimId = int.parse(args);
              } catch (e) {
                throw ArgumentError('String claim ID could not be parsed to int: $args');
              }
            } else if (args is Map<String, dynamic>) {
              // Handle the map argument format from My Claims tab
              claimId = args['claimId'] as int;
              similarityScore = args['similarityScore'] as String?;
              fromMyItemDetails = args['fromMyItemDetails'] as bool? ?? false;
            } else {
              throw ArgumentError('Argument must be either an integer, string claimId, or a map with claimId');
            }
            
            return MaterialPageRoute(
              builder: (context) => ClaimDetailsScreen(
                claimId: claimId,
                similarityScore: similarityScore,
                fromMyItemDetails: fromMyItemDetails,
              ),
            );
          } else if (settings.name == '/edit_item') {
            // Extract the arguments - should be an item ID
            final args = settings.arguments;
            late int itemId;
            
            // Handle different argument types
            if (args is Item) {
              itemId = args.id;
            } else if (args is int) {
              itemId = args;
            } else {
              throw ArgumentError('Arguments must be either an Item or an integer itemId');
            }
            
            return MaterialPageRoute(
              builder: (context) => EditItemScreen(itemId: itemId),
            );
          } else if (settings.name == '/potential_match_details') {
            // Extract the arguments
            final args = settings.arguments as Map<String, dynamic>;
            final foundItemId = args['foundItemId'] as int;
            final lostItemId = args['lostItemId'] as int;
            final tabIndex = args['tabIndex'] as int;
            final similarityScore = args['similarityScore'] as String?;
            final matchId = args['matchId'] as int?;
            
            return MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(
                itemId: foundItemId,
                lostItemId: lostItemId,
                matchId: matchId,
                similarityScore: similarityScore,
                onBack: () {
                  // Pop back to the lost item details screen
                  Navigator.pop(context);
                  // Navigate back to the lost item with the correct tab
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyItemDetailsScreen(
                        itemId: lostItemId,
                        initialTabIndex: tabIndex,
                      ),
                    ),
                  );
                },
              ),
            );
          }
          // If route not found, return error page
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final bool launchedFromNotification;

  const SplashScreen({super.key, required this.launchedFromNotification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LoginProvider>(
        builder: (context, loginProvider, child) {
          // Show loading indicator while initializing
          if (loginProvider.isLoading) {
            return Container(
              color: Colors.white,
              child:Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/logo.png', // Replace with your logo asset path
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text('Loading...'),
                  ],
                ),
              )
            );
          }
          
          // Show error message if there's an error
          if (loginProvider.error != null) {
            // Check for connection timeout error
            final isConnectionError = loginProvider.error!.contains('Connection timed out') || 
                                     loginProvider.error!.contains('errno = 110');
            
            return Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/logo.png', // Replace with your logo asset path
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      isConnectionError ? Icons.wifi_off : Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        isConnectionError 
                            ? 'Connection timed out. Please check your internet connection.'
                            : 'An error occurred: ${loginProvider.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            );
          }

          // Only navigate if we're not launched from a notification
          // If launched from notification, the app will navigate to claim details via the handler
          if (!launchedFromNotification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(loginProvider.error == null){
                final hasToken = loginProvider.token != null;
                final isVerified = loginProvider.isVerified;
                
                print("SplashScreen: Token: $hasToken, Verified: $isVerified");
                
                if (!hasToken) {
                  // No token - go to login
                  Navigator.pushReplacementNamed(context, '/login');
                } else if (hasToken && !isVerified) {
                  // Has token but not verified - go to verification screen
                  Navigator.pushReplacementNamed(context, '/email_verification');
                } else {
                  // Has token and is verified - go to home
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            });
          } else {
            // If launched from notification, we need to prepare the environment
            // but not navigate away from the splash screen automatically
            // The notification handler will handle the navigation
            // WidgetsBinding.instance.addPostFrameCallback((_) {
            //   if(loginProvider.error == null) {
            //     print("SplashScreen: Launched from notification, waiting for notification handler");
                
            //     // Silently prepare the app state but don't navigate
            //     final hasToken = loginProvider.token != null;
            //     final isVerified = loginProvider.isVerified;
                
            //     if (!hasToken) {
            //       // If no token, we should still go to login
            //       Navigator.pushReplacementNamed(context, '/login');
            //     }
            //     // Otherwise stay on splash screen and let notification handler take over
            //   }
            // });
            // If launched from notification, just wait for the notification handler
            // The notification handler will handle navigation after checking login state
            print("SplashScreen: Launched from notification, waiting for notification handler");
          }
          
          // Return a loading indicator while navigating
          return Container(
              color: Colors.white,
              child:Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/logo.png', // Replace with your logo asset path
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text('Loading...'),
                  ],
                ),
              )
            );
        },
      ),
    );
  }
}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Student App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//         useMaterial3: true,
//       ),
//       home: const LoginPage(),
//     );
//   }
// }

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isPasswordVisible = false;

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _login() {
//     if (_formKey.currentState!.validate()) {
//       // TODO: Implement actual login logic
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Processing login...')),
//       );
//       
//       // For demo purposes, navigate to a home page after login
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const HomePage()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Icon(
//                     Icons.school,
//                     size: 80,
//                     color: Colors.blue,
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'Student Login',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 48),
//                   TextFormField(
//                     controller: _usernameController,
//                     decoration: const InputDecoration(
//                       labelText: 'Username',
//                       prefixIcon: Icon(Icons.person),
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your username';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: !_isPasswordVisible,
//                     decoration: InputDecoration(
//                       labelText: 'Password',
//                       prefixIcon: const Icon(Icons.lock),
//                       border: const OutlineInputBorder(),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isPasswordVisible
//                               ? Icons.visibility_off
//                               : Icons.visibility,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your password';
//                       }
//                       return null;
//                     },
//                   ),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () {
//                         // TODO: Implement forgot password functionality
//                       },
//                       child: const Text('Forgot Password?'),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: _login,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text(
//                       'LOGIN',
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Don't have an account?"),
//                       TextButton(
//                         onPressed: () {
//                           // TODO: Navigate to registration page
//                         },
//                         child: const Text('Register'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Simple home page to navigate to after login
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Student Dashboard'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Welcome to Student Dashboard!',
//               style: TextStyle(fontSize: 20),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (context) => const LoginPage()),
//                 );
//               },
//               child: const Text('Logout'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
