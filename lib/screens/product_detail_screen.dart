  // product_detail_screen.dart
  import 'dart:convert';
  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import '../models/product.dart';
  import '../services/mongodb_service.dart';

  class ProductDetailScreen extends StatefulWidget {
    final Product product;
    final Function onProductUpdated;

    ProductDetailScreen({
      required this.product,
      required this.onProductUpdated,
    });

    @override
    _ProductDetailScreenState createState() => _ProductDetailScreenState();
  }

  class _ProductDetailScreenState extends State<ProductDetailScreen> {
    late TextEditingController _typeController;
    late TextEditingController _priceController;
    late TextEditingController _descriptionController;
    final _formKey = GlobalKey<FormState>();
    File? _imageFile;
    bool _isEditing = false;
    String _currentImageBase64 = '';

    @override
    void initState() {
      super.initState();
      _typeController = TextEditingController(text: widget.product.loaisp);
      _priceController = TextEditingController(text: widget.product.gia.toString());
      _currentImageBase64 = widget.product.hinhanh;
    }

    @override
    void dispose() {
      _typeController.dispose();
      _priceController.dispose();
      _descriptionController.dispose();
      super.dispose();
    }

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }

    String _imageToBase64(File imageFile) {
      List<int> imageBytes = imageFile.readAsBytesSync();
      return base64Encode(imageBytes);
    }

    void _toggleEdit() {
      setState(() {
        _isEditing = !_isEditing;
      });
    }

    void _showDeleteConfirmDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa sản phẩm này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await MongoDBService.deleteProduct(widget.product.idsanpham);
                if (success) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to product list
                  widget.onProductUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa sản phẩm thành công')),
                  );
                }
              },
              child: Text('Xóa'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
    }

    void _saveChanges() async {
      if (_formKey.currentState!.validate()) {
        String imageBase64 = _currentImageBase64;
        if (_imageFile != null) {
          imageBase64 = _imageToBase64(_imageFile!);
        }

        final updatedProduct = Product(
          idsanpham: widget.product.idsanpham,
          loaisp: _typeController.text,
          gia: double.parse(_priceController.text),
          hinhanh: imageBase64,
        );

        final success = await MongoDBService.updateProduct(updatedProduct);
        if (success) {
          setState(() {
            _isEditing = false;
            _currentImageBase64 = imageBase64;
          });
          widget.onProductUpdated();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật sản phẩm thành công')),
          );
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Chỉnh sửa sản phẩm' : 'Chi tiết sản phẩm'),
          backgroundColor: Colors.blue.shade600,
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing ? _saveChanges : _toggleEdit,
            ),
            if (!_isEditing)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _showDeleteConfirmDialog,
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade600,
              ],
            ),
          ),
          child: ListView(
            children: [
              Container(
                height: 250,
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: _isEditing && _imageFile != null
                          ? Image.file(
                        _imageFile!,
                        fit: BoxFit.contain,
                        height: 220,
                      )
                          : Image.memory(
                        base64Decode(_currentImageBase64),
                        fit: BoxFit.contain,
                        height: 220,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(Icons.image_not_supported, size: 80),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(Icons.camera_alt),
                          label: Text("Đổi ảnh"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã sản phẩm: ${widget.product.idsanpham}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        if (_isEditing)
                          TextFormField(
                            controller: _typeController,
                            decoration: InputDecoration(
                              labelText: 'Tên sản phẩm',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Vui lòng nhập tên sản phẩm'
                                : null,
                          )
                        else
                          Text(
                            widget.product.loaisp,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: 16),
                        if (_isEditing)
                          TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Giá',
                              border: OutlineInputBorder(),
                              suffixText: 'đ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                            value?.isEmpty ?? true ? 'Vui lòng nhập giá' : null,
                          )
                        else
                          Row(
                            children: [
                              Text(
                                'Giá: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${widget.product.gia.toStringAsFixed(0)} đ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: 24),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }