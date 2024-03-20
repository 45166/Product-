import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdProduct extends StatefulWidget {
  const AdProduct({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _AdProductState createState() => _AdProductState();
}

class ListProductType {
  int? value;
  String? name;

  ListProductType(this.value, this.name);

  static List<ListProductType> getListProductType() {
    return [
      ListProductType(1, 'เคส'),
      ListProductType(2, 'การ์ดจอ'),
      ListProductType(3, 'โน้ตบุ๊ก'),
    ];
  }
}

class _AdProductState extends State<AdProduct> {
  String _token = '';
  int? selectedProductType;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Future<void> _addProduct(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    setState(() {
      _token = token!;
    });

    if (_formKey.currentState!.validate()) {
      var url = Uri.parse('https://642021195.pungpingcoding.online/api/update');

      var productData = {
        'pd_name': _nameController.text,
        'pd_type': selectedProductType, // Using selected type value
        'pd_price': int.parse(_priceController.text),
      };

      try {
        var response = await http.post(
          url,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: "Bearer $_token"
          },
          body: jsonEncode(productData),
        );

        if (response.statusCode == 200) {
          // ignore: use_build_context_synchronously
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Product added successfully',
            showConfirmBtn: false,
            autoCloseDuration: const Duration(seconds: 2),
          ).then((value) async {
            Navigator.of(context).pop();
          });

          // Clear input fields after successful addition
          _nameController.clear();
          _priceController.clear();
        } 
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error adding product. Please try again later.'),
          ),
        );
      }
    } else {
      // ignore: use_build_context_synchronously
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Please fix the validation errors before adding the product.',
        showConfirmBtn: false,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedProductType,
                items: ListProductType.getListProductType().map((productType) {
                  return DropdownMenuItem<int>(
                    value: productType.value,
                    child: Text(productType.name!),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    selectedProductType = value;
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
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _addProduct(context),
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
