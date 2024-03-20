import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lab10/LoginPage.dart';
import 'package:lab10/editproduct.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adproduct.dart'; // Import your AdProduct widget

class Product {
  final int id;
  final String productName;
  final int productType;
  final int price;

  Product({
    required this.id,
    required this.productName,
    required this.productType,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"] ?? 0,
      productName: json["product_name"] ?? '',
      productType: json["product_type"] ?? 0,
      price: json["price"] ?? 0,
    );
  }
}

class ShowProductPage extends StatefulWidget {
  const ShowProductPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShowProductPageState createState() => _ShowProductPageState();
}

class _ShowProductPageState extends State<ShowProductPage> {
  String _token = '';
  // ignore: unused_field
  int _userId = 0;
  String _name = '';
  List<Product>? _products;

  String _getTypeName(int type) {
    switch (type) {
      case 1:
        return 'เคส';
      case 2:
        return 'การ์ดจอ';
      case 3:
        return 'โน้ตบุ๊ก';
      default:
        return 'ไม่ระบุ';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      // If the token is null, navigate back to the login page
      return;
    }

    setState(() {
      _token = token;
      _userId = prefs.getInt('userId') ?? 0;
      _name = prefs.getString('userName') ?? '';
    });

    var url = Uri.parse('https://642021195.pungpingcoding.online/api/product');

    var response = await http.get(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      setState(() {
        _products = (jsonData['payload'] as List)
            .map<Product>((json) => Product.fromJson(json))
            .toList();
      });
    }
  }

  Future<void> _deleteProduct(int id) async {
    var url =
        Uri.parse('https://642021195.pungpingcoding.online/api/products/$id');

    var response = await http.delete(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: "Bearer $_token"
      },
    );

    if (response.statusCode == 200) {
      // If deletion is successful, remove the product from the list
      setState(() {
        _products!.removeWhere((product) => product.id == id);
      });
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    // Perform logout API call
    setState(() {
      _token = token!;
      _userId = prefs.getInt('userId') ?? 0;
      _name = prefs.getString('userName') ?? '';
    });
    var logoutUrl =
        Uri.parse('https://642021195.pungpingcoding.online/api/logout');
    var logoutResponse = await http.post(
      logoutUrl,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: "Bearer $_token"
      },
    );

    if (logoutResponse.statusCode == 200) {
      prefs.remove("token");

      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginPage(), // Replace LoginPage() with your actual login page
        ),
      );
    }
  }

  void _navigateToAddProductPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdProduct()),
    ).then((_) {
      // Refresh the state when returning from the AdProduct page
      _fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลิตภัณฑ์'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: _products == null || _products!.isEmpty
            ? const CircularProgressIndicator()
            : ListView.builder(
                itemCount: _products!.length,
                itemBuilder: (context, index) {
                  var product = _products![index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      title: Text(
                        'Product Name: ${product.productName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Price: ${product.price}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type: ${_getTypeName(product.productType)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProduct(productId: product.id),
                                ),
                              ).then((_) {
                                // Callback function after returning from EditProduct page
                                _fetchProducts(); // Refresh product list
                              });
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Create a local variable for the context
                              BuildContext dialogContext = context;
                              QuickAlert.show(
                                onCancelBtnTap: () {
                                  Navigator.pop(
                                      dialogContext); // Use the local variable here
                                },
                                context: context,
                                type: QuickAlertType.confirm,
                                title: 'คุณแน่ใจที่ต้องการจะลบ',
                               
                                titleAlignment: TextAlign.center,
                                textAlignment: TextAlign.center,
                                confirmBtnText: 'ตกลง',
                                cancelBtnText: 'ยกเลิก',
                                confirmBtnColor:
                                    const Color.fromARGB(255, 185, 37, 37),
                                backgroundColor: Colors.white,
                                headerBackgroundColor: Colors.grey,
                                confirmBtnTextStyle: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                                barrierColor:
                                    const Color.fromARGB(139, 46, 46, 46),
                                titleColor: const Color.fromARGB(255, 1, 1, 1),
                                textColor: const Color.fromARGB(255, 1, 1, 1),
                                cancelBtnTextStyle: const TextStyle(
                                  color: Color.fromARGB(255, 33, 33, 33),
                                  fontWeight: FontWeight.bold,
                                ),
                                onConfirmBtnTap: () async {
                                  Navigator.pop(
                                      dialogContext); // Close the confirmation dialog using the local variable
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.success,
                                    text: 'ลบข้อมูลสำเร็จ!',
                                    showConfirmBtn: false,
                                    autoCloseDuration:
                                        const Duration(seconds: 3),
                                  ).then((value) async {
                                    await _deleteProduct(
                                        product.id); // Delete the product
                                  });
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline_outlined,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProductPage(context),
        child: const Icon(Icons.add_box_outlined),
      ),
    );
  }
}
