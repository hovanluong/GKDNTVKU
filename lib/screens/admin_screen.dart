import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/mongodb_service.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _typeController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _typeController = TextEditingController();
    _priceController = TextEditingController();
    _imageUrlController = TextEditingController();
    _loadProducts();
  }

  void _loadProducts() async {
    final productsList = await MongoDBService.getProducts();
    setState(() {
      products = productsList.map((e) => Product.fromMap(e)).toList();
    });
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        idsanpham: _idController.text,
        loaisp: _typeController.text,
        gia: double.parse(_priceController.text),
        hinhanh: _imageUrlController.text,
      );

      final success = await MongoDBService.insertProduct(product);
      if (success) {
        _loadProducts();
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm sản phẩm thành công')),
        );
      }
    }
  }

  void _clearForm() {
    _idController.clear();
    _typeController.clear();
    _priceController.clear();
    _imageUrlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý sản phẩm'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(labelText: 'ID Sản phẩm'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập ID sản phẩm';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _typeController,
                    decoration: InputDecoration(labelText: 'Loại sản phẩm'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập loại sản phẩm';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Giá'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập giá';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(labelText: 'URL Hình ảnh'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập URL hình ảnh';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addProduct,
                    child: Text('Thêm sản phẩm'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        product.hinhanh,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(product.loaisp),
                      subtitle: Text('Giá: ${product.gia}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Implement edit functionality
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final success = await MongoDBService.deleteProduct(
                                  product.idsanpham);
                              if (success) {
                                _loadProducts();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Xóa sản phẩm thành công')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}