import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:laundry_app_ui/services/order_service.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:intl/intl.dart';

class OrderHistory extends StatefulWidget {
  @override
  _OrderHistoryState createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please login to view orders')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _orderService.getUserOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Constants.primaryColor));
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
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your orders will appear here',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderDoc = snapshot.data!.docs[index];
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
    Timestamp? pickupDate = orderData['pickupDate'];
    List<dynamic> items = orderData['items'] ?? [];

    // Format dates
    String orderDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'N/A';
    String pickupDateStr = pickupDate != null
        ? DateFormat('MMM dd, yyyy').format(pickupDate.toDate())
        : 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/order-details',
            arguments: {'orderId': orderId, 'orderData': orderData},
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              SizedBox(height: 8.h),

              // Order Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11.sp, color: Colors.grey),
                  SizedBox(width: 6.w),
                  Text(
                    'Ordered: $orderDate',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 5.h),

              // Pickup Date
              Row(
                children: [
                  Icon(Icons.schedule, size: 11.sp, color: Colors.grey),
                  SizedBox(width: 6.w),
                  Text(
                    'Pickup: $pickupDateStr',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Items count
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.h),

              // Divider
              Divider(height: 1),
              SizedBox(height: 8.h),

              // Total Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Rs. ${totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Constants.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
