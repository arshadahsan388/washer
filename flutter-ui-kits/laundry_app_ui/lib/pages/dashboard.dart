import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:laundry_app_ui/widgets/latest_orders.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Track active index
  int activeIndex = 0;
  final AuthService _authService = AuthService();
  String userName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Get user data from Firestore
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userData.exists) {
          setState(() {
            userName = userData.data()?['name'] ?? user.displayName ?? 'User';
            isLoading = false;
          });
        } else {
          setState(() {
            userName = user.displayName ?? 'User';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Clear saved session
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    await _authService.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Constants.scaffoldBackgroundColor,
        buttonBackgroundColor: Constants.primaryColor,
        items: [
          Icon(
            FlutterIcons.ios_home_ion,
            size: 30.0,
            color: activeIndex == 0 ? Colors.white : Color(0xFFC8C9CB),
          ),
          Icon(
            FlutterIcons.map_marker_radius_mco,
            size: 30.0,
            color: activeIndex == 1 ? Colors.white : Color(0xFFC8C9CB),
          ),
          Icon(
            FlutterIcons.plus_ant,
            size: 30.0,
            color: activeIndex == 2 ? Colors.white : Color(0xFFC8C9CB),
          ),
          Icon(
            FlutterIcons.heart_fea,
            size: 30.0,
            color: activeIndex == 3 ? Colors.white : Color(0xFFC8C9CB),
          ),
          Icon(
            FlutterIcons.setting_ant,
            size: 30.0,
            color: activeIndex == 4 ? Colors.white : Color(0xFFC8C9CB),
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            // Middle button - Create Order
            Navigator.of(context).pushNamed('/create-order');
          } else if (index == 3) {
            // Heart button - Order History
            Navigator.of(context).pushNamed('/order-history');
          } else if (index == 4) {
            // Settings button - Profile
            Navigator.of(context).pushNamed('/profile');
          } else {
            setState(() {
              activeIndex = index;
            });
          }
        },
      ),
      backgroundColor: Constants.primaryColor,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0.0,
            top: -20.0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                "assets/images/washing_machine_illustration.png",
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            FlutterIcons.keyboard_backspace_mdi,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Welcome Back,\n",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                  TextSpan(
                                    text: isLoading ? "Loading..." : "$userName!",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  )
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleLogout,
                              child: Icon(
                                FlutterIcons.logout_ant,
                                color: Colors.white,
                                size: 24.0,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50.0,
                  ),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 200.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      color: Constants.scaffoldBackgroundColor,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 24.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "We Care for What You Wear",
                                style: TextStyle(
                                  color: Color.fromRGBO(19, 22, 33, 1),
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                "Premium laundry service delivered to your door",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        LatestOrders(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
