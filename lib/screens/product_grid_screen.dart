import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/mongodb_service.dart';
import 'login_screen.dart';

class ProductGridScreen extends StatefulWidget {
  @override
  _ProductGridScreenState createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  List<Product> products = [];
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _typeController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm sản phẩm mới'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(labelText: 'ID Sản phẩm'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập ID sản phẩm' : null,
                ),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(labelText: 'Loại sản phẩm'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập loại sản phẩm' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Giá'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập giá' : null,
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: 'URL Hình ảnh'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập URL hình ảnh' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
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
                  Navigator.pop(context);
                  _clearForm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm sản phẩm thành công')),
                  );
                }
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    _idController.text = product.idsanpham;
    _typeController.text = product.loaisp;
    _priceController.text = product.gia.toString();
    _imageUrlController.text = product.hinhanh;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa sản phẩm'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(labelText: 'Loại sản phẩm'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập loại sản phẩm' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Giá'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập giá' : null,
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: 'URL Hình ảnh'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập URL hình ảnh' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final updatedProduct = Product(
                  idsanpham: product.idsanpham,
                  loaisp: _typeController.text,
                  gia: double.parse(_priceController.text),
                  hinhanh: _imageUrlController.text,
                );
                final success = await MongoDBService.updateProduct(updatedProduct);
                if (success) {
                  _loadProducts();
                  Navigator.pop(context);
                  _clearForm();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cập nhật sản phẩm thành công')),
                  );
                }
              }
            },
            child: Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String productId) {
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
              final success = await MongoDBService.deleteProduct(productId);
              if (success) {
                _loadProducts();
                Navigator.pop(context);
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
        title: Text('Danh sách sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Sửa sản phẩm'),
                          onTap: () {
                            Navigator.pop(context);
                            _showEditProductDialog(product);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Xóa sản phẩm',
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmDialog(product.idsanpham);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(
                      product.hinhanh,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.loaisp,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${product.gia.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}