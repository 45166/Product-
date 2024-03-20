import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProduct extends StatefulWidget {
  final int productId;

  const EditProduct({Key? key, required this.productId}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  late String _name;
  late int _price;
  int? _selectedProductType;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails(widget.productId);
  }

  Future<void> _fetchProductDetails(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userToken = prefs.getString('userToken');
    var url = Uri.parse('https://642021195.pungpingcoding.online/api/products/$productId');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      Map<String, dynamic> payload = jsonResponse['payload'];
      String productName = payload['product_name'];
      double price = payload['price'].toDouble();
      int productType = payload['product_type']; // Assuming 'product_type' is the field name for product type
      setState(() {
        _nameController.text = productName;
        _priceController.text = price.toString();
        _selectedProductType = productType;
      });
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedProductType,
                items: ListProductType.getListProductType().map((productType) {
                  return DropdownMenuItem<int>(
                    value: productType.value,
                    child: Text(productType.name!),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedProductType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Product Type',
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select product type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _price = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitFormData();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFormData() async {
    Map<String, dynamic> formData = {
      'pd_name': _name,
      'pd_type': _selectedProductType,
      'price': _price,
    };
    String jsonPayload = json.encode(formData);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userToken = prefs.getString('userToken');

    var url = Uri.parse('https://642021195.pungpingcoding.online/api/products/${widget.productId}');
    var response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
      body: jsonPayload,
    );
    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Edit successful',
        showConfirmBtn: false,
        autoCloseDuration: const Duration(seconds: 2),
      ).then((value) async {
        Navigator.of(context).pop();
      });
    } else {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Failed to edit product. Please try again later.',
        showConfirmBtn: false,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }
}

class ListProductType {
  int? value;
  String? name;

  ListProductType(this.value, this.name);

  static List<ListProductType> getListProductType() {
    return [
      ListProductType(1, 'โทรศัพท์มือถือ'),
      ListProductType(2, 'สมาร์ททีวี'),
      ListProductType(3, 'โน้ตบุ๊ก'),
    ];
  }
}
