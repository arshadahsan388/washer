import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app_ui/services/order_service.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app_ui/pages/order_details.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final OrderService _orderService = OrderService();
  String selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.primaryColor,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Orders')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'processing', child: Text('Processing')),
              PopupMenuItem(value: 'washing', child: Text('Washing')),
              PopupMenuItem(value: 'ready', child: Text('Ready')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Constants.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80.sp, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var orders = snapshot.data!.docs;

          // Filter orders by status
          if (selectedStatus != 'all') {
            orders = orders.where((doc) {
              var data = doc.data() as Map<String, dynamic>?;
              return data?['status'] == selectedStatus;
            }).toList();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderDoc = orders[index];
              var orderData = orderDoc.data() as Map<String, dynamic>?;
              if (orderData == null) return SizedBox.shrink();
              var orderId = orderDoc.id;

              return _buildOrderCard(orderId, orderData);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> orderData) {
    String status = orderData['status'] ?? 'pending';
    double totalPrice = (orderData['totalPrice'] ?? 0).toDouble();
    Timestamp? createdAt = orderData['createdAt'];
    String userName = orderData['userName'] ?? 'N/A';
    String userPhone = orderData['userPhone'] ?? 'N/A';
    List<dynamic> items = orderData['items'] ?? [];

    String orderDate = createdAt != null
        ? DateFormat('MMM dd, yyyy hh:mm a').format(createdAt.toDate())
        : 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          // Navigate to order details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetails(),
              settings: RouteSettings(
                arguments: {
                  'orderId': orderId,
                  'orderData': orderData,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            SizedBox(height: 12.h),

            // Customer Info
            Row(
              children: [
                Icon(Icons.person, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  userName,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.phone, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  userPhone,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  orderDate,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Items
            Text(
              '${items.length} item${items.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Rs. ${totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Action Buttons
            if (status != 'completed' && status != 'cancelled')
              _buildActionButtons(orderId, status),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String orderId, String currentStatus) {
    String nextStatus = _getNextStatus(currentStatus);
    
    return Row(
      children: [
        if (currentStatus == 'pending')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.cancel, size: 18.sp),
              label: Text('Reject', style: TextStyle(fontSize: 14.sp)),
            ),
          ),
        if (currentStatus == 'pending') SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(orderId, nextStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: Icon(Icons.check_circle, size: 18.sp),
            label: Text(
              _getButtonText(nextStatus),
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'processing';
      case 'processing':
        return 'washing';
      case 'washing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return 'completed';
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'processing':
        return 'Accept Order';
      case 'washing':
        return 'Start Washing';
      case 'ready':
        return 'Mark Ready';
      case 'completed':
        return 'Complete';
      default:
        return 'Update';
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        displayText = 'Pending';
        break;
      case 'processing':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        displayText = 'Processing';
        break;
      case 'washing':
        bgColor = Colors.cyan[100]!;
        textColor = Colors.cyan[800]!;
        displayText = 'Washing';
        break;
      case 'ready':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        displayText = 'Ready';
        break;
      case 'completed':
        bgColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        displayText = 'Completed';
        break;
      case 'cancelled':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        displayText = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
