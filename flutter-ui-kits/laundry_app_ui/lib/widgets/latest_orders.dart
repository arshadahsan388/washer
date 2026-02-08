import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:laundry_app_ui/services/order_service.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:laundry_app_ui/pages/order_details.dart';
import 'package:intl/intl.dart';

class LatestOrders extends StatelessWidget {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Orders",
                style: TextStyle(
                  color: Color.fromRGBO(19, 22, 33, 1),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/order-history');
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot>(
          stream: _orderService.getUserOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: CircularProgressIndicator(
                    color: Constants.primaryColor,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                      SizedBox(height: 8.h),
                      Text(
                        'Error loading orders',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64.sp,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Create your first order!',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort orders by createdAt
            var docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              var aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              var bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            // Take only latest 5 orders
            var latestOrders = docs.take(5).toList();

            return Container(
              height: 230.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: latestOrders.length,
                separatorBuilder: (context, index) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  var orderDoc = latestOrders[index];
                  var orderData = orderDoc.data() as Map<String, dynamic>?;
                  if (orderData == null) return SizedBox.shrink();
                  var orderId = orderDoc.id;

                  return _buildOrderCard(context, orderId, orderData);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    String status = orderData['status'] ?? 'pending';
    double totalPrice = (orderData['totalPrice'] ?? 0).toDouble();
    Timestamp? createdAt = orderData['createdAt'];
    List<dynamic> items = orderData['items'] ?? [];

    String orderDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetails(),
            settings: RouteSettings(
              arguments: {'orderId': orderId, 'orderData': orderData},
            ),
          ),
        );
      },
      child: Container(
        width: 240.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[600]),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    orderDate,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14.sp, color: Colors.grey[600]),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    '${items.length} item${items.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Divider(height: 1),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
        displayText = 'Done';
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
