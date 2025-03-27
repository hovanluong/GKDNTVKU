// mongodb_service.dart
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'dart:convert';

class MongoDBService {
  static late Db db;

  static connect() async {
    db = await Db.create('mongodb://192.168.1.15:27017/vls_shoes_db');
    await db.open();
  }

  // Product CRUD operations
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final products = await db.collection('products').find().toList();
      return products;
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final products = await db.collection('products').find(
          where.match('loaisp', query, caseInsensitive: true)
      ).toList();
      return products;
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Fixed auto-increment ID generation
  static Future<String> generateProductId() async {
    try {
      // Get the highest existing ID
      var collection = db.collection('products');
      var result = await collection.find().toList();

      if (result.isEmpty) {
        return 'S0001'; // First product
      }

      // Find the highest ID
      String highestId = 'S0000';
      for (var doc in result) {
        String id = doc['idsanpham'] as String;
        if (id.startsWith('S') && id.compareTo(highestId) > 0) {
          highestId = id;
        }
      }

      // Extract the number part and increment
      int idNumber = int.parse(highestId.substring(1));
      String nextId = 'S${(idNumber + 1).toString().padLeft(4, '0')}';
      return nextId;
    } catch (e) {
      print('Error generating product ID: $e');
      return 'S0001'; // Default if error
    }
  }

  static Future<bool> insertProduct(Product product) async {
    try {
      await db.collection('products').insert(product.toMap());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> updateProduct(Product product) async {
    try {
      await db.collection('products').update(
        where.eq('idsanpham', product.idsanpham),
        product.toMap(),
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<bool> deleteProduct(String idsanpham) async {
    try {
      await db.collection('products').remove(
        where.eq('idsanpham', idsanpham),
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // User operations
  static Future<bool> registerUser(User user) async {
    try {
      await db.collection('users').insert(user.toMap());
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  static Future<User?> loginUser(String username, String password) async {
    try {
      final user = await db.collection('users').findOne(
        where.eq('username', username).eq('password', password),
      );
      if (user != null) {
        return User.fromMap(user);
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Image handling
  static Future<String> saveImage(File file, String productId) async {
    try {
      // For simplicity, just convert to base64 and store directly
      List<int> imageBytes = file.readAsBytesSync();
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      print("Error saving image: $e");
      return "";
    }
  }
}

// Add this missing import
