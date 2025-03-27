// product_grid_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/mongodb_service.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

class ProductGridScreen extends StatefulWidget {
  @override
  _ProductGridScreenState createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final _formKey = GlobalKey<FormState>();
  TextEditingController _searchController = TextEditingController();
  late TextEditingController _typeController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  File? _imageFile;
  String? _nextProductId;
  bool _isLoading = true;
  bool _sortAZ = false;

  // Add RefreshController to handle pull-to-refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadProducts();
    _getNextProductId();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _refreshController.dispose(); // Dispose the refresh controller
    super.dispose();
  }

  void _filterProducts() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredProducts = List.from(products);
      });
    } else {
      setState(() {
        filteredProducts = products
            .where((product) => product.loaisp
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
    if (_sortAZ) {
      filteredProducts.sort((a, b) => a.loaisp.compareTo(b.loaisp));
    }
  }

  void _toggleSort() {
    setState(() {
      _sortAZ = !_sortAZ;
      if (_sortAZ) {
        filteredProducts.sort((a, b) => a.loaisp.compareTo(b.loaisp));
      } else {
        _filterProducts(); // Reset to original filter
      }
    });
  }

  Future<void> _getNextProductId() async {
    final id = await MongoDBService.generateProductId();
    setState(() {
      _nextProductId = id;
    });
  }

  // Add _onRefresh function for pull-to-refresh
  void _onRefresh() async {
    await _loadProducts();
    _refreshController.refreshCompleted();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    final productsList = await MongoDBService.getProducts();
    setState(() {
      products = productsList.map((e) => Product.fromMap(e)).toList();
      filteredProducts = List.from(products);
      _isLoading = false;
    });
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

  void _showAddProductDialog() async {
    // Reset the form
    _typeController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _imageFile = null;
    // Get the next product ID
    await _getNextProductId();
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
                Text('ID Sản phẩm: $_nextProductId',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Giá'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập giá' : null,
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40),
                        Text('Chọn hình ảnh')
                      ],
                    ),
                  ),
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
                if (_imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng chọn hình ảnh')),
                  );
                  return;
                }
                String base64Image = _imageToBase64(_imageFile!);
                final product = Product(
                  idsanpham: _nextProductId!,
                  loaisp: _typeController.text,
                  gia: double.parse(_priceController.text),
                  hinhanh: base64Image,
                );
                final success = await MongoDBService.insertProduct(product);
                if (success) {
                  _loadProducts();
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VLS SHOES'),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_sortAZ ? Icons.sort : Icons.sort_by_alpha),
            onPressed: _toggleSort,
            tooltip: 'Sắp xếp A-Z',
          ),
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async {
            await _loadProducts();
          },
          child: filteredProducts.isEmpty
              ? Center(
            child: Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: product,
                          onProductUpdated: () {
                            _loadProducts();
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.memory(
                            base64Decode(product.hinhanh),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.blue.shade700,
        child: Icon(Icons.add),
      ),
    );
  }
}

// Add this class for the RefreshController
class RefreshController {
  bool isRefresh = false;

  RefreshController({required bool initialRefresh}) {
    isRefresh = initialRefresh;
  }

  void refreshCompleted() {
    isRefresh = false;
  }

  void dispose() {
    // Nothing specific to dispose
  }
}