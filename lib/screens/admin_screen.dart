// admin_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  File? _imageFile;
  List<Product> products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _typeController = TextEditingController();
    _priceController = TextEditingController();
    _loadProducts();
    _generateProductId();
  }

  // Tạo ID sản phẩm tự động
  void _generateProductId() async {
    final id = await MongoDBService.generateProductId();
    setState(() {
      _idController.text = id;
    });
  }

  void _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    final productsList = await MongoDBService.getProducts();
    setState(() {
      products = productsList.map((e) => Product.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng chọn hình ảnh sản phẩm')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Lưu hình ảnh và lấy đường dẫn
      final imagePath = await MongoDBService.saveImage(_imageFile!, _idController.text);

      if (imagePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu hình ảnh')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final product = Product(
        idsanpham: _idController.text,
        loaisp: _typeController.text,
        gia: double.parse(_priceController.text),
        hinhanh: imagePath,
      );

      final success = await MongoDBService.insertProduct(product);
      if (success) {
        _loadProducts();
        _clearForm();
        _generateProductId(); // Tạo ID mới cho lần tiếp theo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm sản phẩm thành công')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _typeController.clear();
    _priceController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý sản phẩm'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Disabled ID field (auto-generated)
                  TextFormField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: 'ID Sản phẩm (tự động)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: false,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      labelText: 'Tên sản phẩm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Giá',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập giá';
                      }
                      return null;
                    },
                  ),
                  // Image picker
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _imageFile != null
                            ? Image.file(
                          _imageFile!,
                          height: 130,
                          fit: BoxFit.contain,
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text('Chọn hình ảnh'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Thêm sản phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.hinhanh.startsWith('/')
                            ? Image.file(
                          File(product.hinhanh),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : Image.network(
                          product.hinhanh,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        product.loaisp,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Giá: ${product.gia.toStringAsFixed(0)} đ'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // Implement edit functionality
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
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