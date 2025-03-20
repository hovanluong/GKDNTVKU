class Product {
  final String idsanpham;
  final String loaisp;
  final double gia;
  final String hinhanh;

  Product({
    required this.idsanpham,
    required this.loaisp,
    required this.gia,
    required this.hinhanh,
  });

  Map<String, dynamic> toMap() {
    return {
      'idsanpham': idsanpham,
      'loaisp': loaisp,
      'gia': gia,
      'hinhanh': hinhanh,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      idsanpham: map['idsanpham'] ?? '',  // Kiểm tra có null không
      loaisp: map['loaisp'] ?? '',
      gia: map['gia'] != null ? map['gia'].toDouble() : 0.0,
      hinhanh: map['hinhanh'] ?? '',
    );
  }

}