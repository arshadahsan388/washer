import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:laundry_app_ui/utils/constants.dart';
import 'package:laundry_app_ui/widgets/app_button.dart';
import 'package:laundry_app_ui/widgets/input_widget.dart';
import 'package:laundry_app_ui/services/auth_service.dart';
import 'package:laundry_app_ui/services/order_service.dart';

class CreateOrder extends StatefulWidget {
  @override
  _CreateOrderState createState() => _CreateOrderState();
}

class _CreateOrderState extends State<CreateOrder> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  bool _isLoading = false;
  
  // Laundry items with prices
  Map<String, int> _items = {
    'Shirt': 0,
    'Pants': 0,
    'T-Shirt': 0,
    'Jeans': 0,
    'Bedsheet': 0,
    'Towel': 0,
  };

  Map<String, double> _prices = {
    'Shirt': 50.0,
    'Pants': 60.0,
    'T-Shirt': 40.0,
    'Jeans': 70.0,
    'Bedsheet': 100.0,
    'Towel': 30.0,
  };

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    double total = 0;
    _items.forEach((key, value) {
      total += (_prices[key] ?? 0) * value;
    });
    return total;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Constants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createOrder() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill address and phone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if at least one item is selected
    bool hasItems = _items.values.any((count) => count > 0);
    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare items list
      List<Map<String, dynamic>> orderItems = [];
      _items.forEach((key, value) {
        if (value > 0) {
          orderItems.add({
            'name': key,
            'quantity': value,
            'price': _prices[key],
            'total': (_prices[key] ?? 0) * value,
          });
        }
      });

      final orderId = await _orderService.createOrder(
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userPhone: _phoneController.text,
        pickupAddress: _addressController.text,
        pickupDate: _selectedDate,
        items: orderItems,
        totalPrice: _calculateTotal(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to dashboard
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.primaryColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 15.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            FlutterIcons.keyboard_backspace_mdi,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Text(
                          "Create New Order",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 40.0),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 180.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        topRight: Radius.circular(30.0),
                      ),
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InputWidget(
                          topLabel: "Pickup Address",
                          hintText: "Enter your address",
                          controller: _addressController,
                        ),
                        SizedBox(height: 20.0),
                        InputWidget(
                          topLabel: "Phone Number",
                          hintText: "Enter your phone",
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 20.0),
                        Text(
                          "Pickup Date",
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color.fromRGBO(74, 77, 84, 0.2),
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                  style: TextStyle(fontSize: 14.0),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: Constants.primaryColor,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 25.0),
                        Text(
                          "Select Items",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15.0),
                        ..._items.keys.map((item) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "Rs ${_prices[item]?.toStringAsFixed(0)} each",
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_items[item]! > 0) {
                                            _items[item] = _items[item]! - 1;
                                          }
                                        });
                                      },
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: Constants.primaryColor,
                                    ),
                                    Text(
                                      '${_items[item]}',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _items[item] = _items[item]! + 1;
                                        });
                                      },
                                      icon: Icon(Icons.add_circle_outline),
                                      color: Constants.primaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 20.0),
                        Divider(),
                        SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total:",
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Rs ${_calculateTotal().toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                                color: Constants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.0),
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Constants.primaryColor,
                                ),
                              )
                            : AppButton(
                                type: ButtonType.PRIMARY,
                                text: "Create Order",
                                onPressed: _createOrder,
                              ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
