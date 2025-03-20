import 'package:mongo_dart/mongo_dart.dart';

import '../models/product.dart';
import '../models/user.dart';

class MongoDBService {
  static late Db db;
  static connect() async {
    db = await Db.create('mongodb://10.0.2.2:27017/vls_shoes_db');
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
}