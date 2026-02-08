import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app_ui/services/order_service.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:intl/intl.dart';

class OrderDetails extends StatefulWidget {
  @override
  _OrderDetailsState createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  final OrderService _orderService = OrderService();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(child: Text('Order not found - No arguments')),
      );
    }

    final String orderId = args['orderId'] ?? '';
    final orderData = args['orderData'] as Map<String, dynamic>?;
    
    if (orderData == null || orderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Order data not available'),
              SizedBox(height: 10),
              Text('Order ID: $orderId'),
              SizedBox(height: 10),
              Text('Data: ${args.toString()}'),
            ],
          ),
        ),
      );
    }

    String status = orderData['status'] ?? 'pending';
    double totalPrice = (orderData['totalPrice'] ?? 0).toDouble();
    Timestamp? createdAt = orderData['createdAt'];
    Timestamp? pickupDate = orderData['pickupDate'];
    List<dynamic> items = orderData['items'] ?? [];
    String userName = orderData['userName'] ?? 'N/A';
    String userPhone = orderData['userPhone'] ?? 'N/A';
    String pickupAddress = orderData['pickupAddress'] ?? 'N/A';

    String orderDate = createdAt != null
        ? DateFormat('MMM dd, yyyy hh:mm a').format(createdAt.toDate())
        : 'N/A';
    String pickupDateStr = pickupDate != null
        ? DateFormat('MMM dd, yyyy').format(pickupDate.toDate())
        : 'N/A';

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
          'Order Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Status
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '#$orderId',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Divider(height: 1),
                      SizedBox(height: 16.h),
                      _buildInfoRow(Icons.calendar_today, 'Order Date', orderDate),
                      SizedBox(height: 10.h),
                      _buildInfoRow(Icons.schedule, 'Pickup Date', pickupDateStr),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Order Status Timeline
              _buildStatusTimeline(status),

              SizedBox(height: 16.h),

              // Customer Information
              _buildSectionCard(
                'Customer Information',
                [
                  _buildInfoRow(Icons.person, 'Name', userName),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.phone, 'Phone', userPhone),
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.location_on, 'Address', pickupAddress),
                ],
              ),

              SizedBox(height: 16.h),

              // Items
              _buildSectionCard(
                'Items',
                [
                  ...items.map((item) {
                    String itemName = item['name'] ?? 'Item';
                    int quantity = item['quantity'] ?? 0;
                    double price = (item['price'] ?? 0).toDouble();
                    double subtotal = quantity * price;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'Rs. $price x $quantity',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${subtotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  Divider(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Rs. ${totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Cancel button (only for pending orders)
              if (status.toLowerCase() == 'pending')
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _cancelOrder(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 18.h,
                            width: 18.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 3.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    List<Map<String, dynamic>> statuses = [
      {'name': 'Pending', 'value': 'pending', 'icon': Icons.receipt},
      {'name': 'Processing', 'value': 'processing', 'icon': Icons.refresh},
      {'name': 'Washing', 'value': 'washing', 'icon': Icons.local_laundry_service},
      {'name': 'Ready', 'value': 'ready', 'icon': Icons.check_circle},
      {'name': 'Completed', 'value': 'completed', 'icon': Icons.done_all},
    ];

    int currentIndex = statuses.indexWhere(
        (s) => s['value'] == currentStatus.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            ...List.generate(statuses.length, (index) {
              bool isActive = index <= currentIndex;
              bool isCurrent = index == currentIndex;
              bool isLast = index == statuses.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      // Circle
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          color: isActive ? Constants.primaryColor : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statuses[index]['icon'],
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      // Status text
                      Text(
                        statuses[index]['name'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Container(
                      margin: EdgeInsets.only(left: 16.w),
                      width: 2.w,
                      height: 32.h,
                      color: isActive ? Constants.primaryColor : Colors.grey[300],
                    ),
                ],
              );
            }),
          ],
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _orderService.cancelOrder(orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
