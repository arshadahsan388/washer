import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:laundry_app_ui/services/user_service.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  Map<String, dynamic>? userData;
  Map<String, dynamic> statistics = {
    'totalOrders': 0,
    'totalSpent': 0.0,
    'pendingOrders': 0,
    'completedOrders': 0,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await _userService.getUserProfile();
    final stats = await _userService.getUserStatistics();
    
    setState(() {
      userData = profile;
      statistics = stats;
      isLoading = false;
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userData?['name'] ?? '');
    final phoneController = TextEditingController(text: userData?['phone'] ?? '');
    final addressController = TextEditingController(text: userData?['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _userService.updateUserProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated successfully')),
                );
                _loadUserData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (e.g., Home, Office)',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: zipController,
                  decoration: InputDecoration(
                    labelText: 'Zip Code',
                    prefixIcon: Icon(Icons.mail),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12.h),
                CheckboxListTile(
                  title: Text('Set as default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() {
                      isDefault = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isEmpty || addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                final success = await _userService.addDeliveryAddress(
                  label: labelController.text.trim(),
                  address: addressController.text.trim(),
                  city: cityController.text.trim(),
                  zipCode: zipController.text.trim(),
                  isDefault: isDefault,
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Address added successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add address')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
              ),
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureCurrent,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureNew,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                  obscureText: obscureConfirm,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }

                final success = await _userService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password changed successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password. Check current password.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
              ),
              child: Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        title: Text('Profile & Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with stats
                  Container(
                    color: Constants.primaryColor,
                    padding: EdgeInsets.only(bottom: 30.h, left: 20.w, right: 20.w),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50.r,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 60.sp,
                            color: Constants.primaryColor,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          userData?['name'] ?? 'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          userData?['email'] ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Statistics Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'Total Orders',
                              '${statistics['totalOrders']}',
                              Icons.shopping_bag,
                            ),
                            _buildStatCard(
                              'Pending',
                              '${statistics['pendingOrders']}',
                              Icons.pending_actions,
                            ),
                            _buildStatCard(
                              'Completed',
                              '${statistics['completedOrders']}',
                              Icons.check_circle,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Total Spent: PKR ${statistics['totalSpent'].toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Info Section
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Personal Information'),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Name',
                    value: userData?['name'] ?? 'Not set',
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: userData?['phone'] ?? 'Not set',
                  ),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Address',
                    value: userData?['address'] ?? 'Not set',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: Icon(Icons.edit),
                      label: Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),

                  // Delivery Addresses Section
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Delivery Addresses'),
                  StreamBuilder<QuerySnapshot>(
                    stream: _userService.getDeliveryAddresses(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Text(
                            'No saved addresses',
                            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isDefault = data['isDefault'] ?? false;

                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isDefault ? Constants.primaryColor : Colors.grey[300]!,
                                width: isDefault ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isDefault ? Constants.primaryColor : Colors.grey,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data['label'] ?? 'Address',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.sp,
                                            ),
                                          ),
                                          if (isDefault) ...[
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: Constants.primaryColor,
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                'Default',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        data['address'] ?? '',
                                        style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '${data['city'] ?? ''} ${data['zipCode'] ?? ''}',
                                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    if (!isDefault)
                                      PopupMenuItem(
                                        child: Text('Set as Default'),
                                        onTap: () async {
                                          await _userService.setDefaultAddress(doc.id);
                                        },
                                      ),
                                    PopupMenuItem(
                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      onTap: () async {
                                        await _userService.deleteDeliveryAddress(doc.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: _showAddAddressDialog,
                      icon: Icon(Icons.add),
                      label: Text('Add New Address'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Constants.primaryColor,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: Constants.primaryColor),
                        ),
                      ),
                    ),
                  ),

                  // Security Section
                  SizedBox(height: 16.h),
                  _buildSectionTitle('Security'),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: Icon(Icons.lock),
                      label: Text('Change Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Constants.primaryColor,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: Constants.primaryColor),
                        ),
                      ),
                    ),
                  ),

                  // Logout Button
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Clear saved session
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        
                        await _authService.signOut();
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Constants.primaryColor, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
