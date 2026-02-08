import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry_app_ui/pages/dashboard.dart';
import 'package:laundry_app_ui/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_app_ui/pages/login.dart';
import 'package:laundry_app_ui/pages/signup.dart';
import 'package:laundry_app_ui/pages/create_order.dart';
import 'package:laundry_app_ui/pages/single_order.dart';
import 'package:laundry_app_ui/pages/order_history.dart';
import 'package:laundry_app_ui/pages/order_details.dart';
import 'package:laundry_app_ui/pages/admin_dashboard.dart';
import 'package:laundry_app_ui/pages/user_profile.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:laundry_app_ui/services/firestore_initializer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Initialize Firestore collections
  try {
    await FirestoreInitializer.initializeCollections();
    print('Firestore collections initialized');
  } catch (e) {
    print('Firestore initialization error: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Laundry App",
        theme: ThemeData(
          scaffoldBackgroundColor: Constants.scaffoldBackgroundColor,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: child,
        initialRoute: "/",
        onGenerateRoute: _onGenerateRoute,
      ),
      child: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isAdmin = prefs.getBool('isAdmin') ?? false;

    // Small delay for smooth transition
    await Future.delayed(Duration(milliseconds: 500));

    if (isLoggedIn) {
      // User is logged in, navigate to appropriate dashboard
      if (isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      // User not logged in, show home/login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Home()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.primaryColor,
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case "/":
      return MaterialPageRoute(builder: (BuildContext context) {
        return Home();
      });
    case "/login":
      return MaterialPageRoute(builder: (BuildContext context) {
        return Login();
      });
    case "/signup":
      return MaterialPageRoute(builder: (BuildContext context) {
        return SignUp();
      });
    case "/dashboard":
      return MaterialPageRoute(builder: (BuildContext context) {
        return Dashboard();
      });
    case "/create-order":
      return MaterialPageRoute(builder: (BuildContext context) {
        return CreateOrder();
      });
    case "/single-order":
      return MaterialPageRoute(builder: (BuildContext context) {
        return SingleOrder();
      });
    case "/order-history":
      return MaterialPageRoute(builder: (BuildContext context) {
        return OrderHistory();
      });
    case "/order-details":
      return MaterialPageRoute(builder: (BuildContext context) {
        return OrderDetails();
      });
    case "/admin":
      return MaterialPageRoute(builder: (BuildContext context) {
        return AdminDashboard();
      });
    case "/profile":
      return MaterialPageRoute(builder: (BuildContext context) {
        return UserProfile();
      });
    default:
      return MaterialPageRoute(builder: (BuildContext context) {
        return Home();
      });
  }
}
