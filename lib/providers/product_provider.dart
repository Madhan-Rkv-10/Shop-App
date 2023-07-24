// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../model/http_exceptions.dart';
import 'orders.dart';
import 'product.dart';

class Products with ChangeNotifier {
  List<Product> items_ = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];

  // var _showOnlyFav = false;
  final String authtoken;
  final String userId;
  Products({
    required this.items_,
    required this.authtoken,
    required this.userId,
  });
  List<Product> get items {
    // if (_showOnlyFav) {
    //   return items_.where((element) => element.isFavorite).toList();
    // }
    return [...items_];
  }

  Product findById(String id) {
    return items_.firstWhere((element) => element.id == id);
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.parse('$baseURL products.json?auth=$authtoken');

    try {
      final value = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId
          // 'isFavorite': product.isFavorite,
        }),
      );

      final newProduct = Product(
          id: json.decode(value.body)['name'],
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          isFavorite: product.isFavorite);
      items_.add(newProduct);
      notifyListeners();
    } catch (error) {
      // print(error);
      rethrow;
    }
  }

  Future<void> fetchAndSetProduct([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse('$baseURL products.json?auth=$authtoken&$filterString');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      print('extracteddata$extractedData');
      final List<Product> loadedProducts = [];
      if (extractedData.isEmpty) {
        return;
      }
      url = Uri.parse('$baseURL userFav/$userId.json?auth=$authtoken');

      final favResponse = await http.get(url);
      final favoriteData = json.decode(favResponse.body);
      // print('favoriteData[2]${favoriteData[0]}');
      extractedData.forEach(
        (pId, pData) {
          loadedProducts.add(Product(
              id: pId,
              title: pData['title'] as String,
              description: pData['description'],
              price: pData['price'],
              imageUrl: pData['imageUrl'],
              isFavorite:
                  favoriteData == null ? false : favoriteData[pId] ?? false));
          // print('pData[' 'title' ']${pData['title']}');
        },
      );
      items_ = loadedProducts;
      notifyListeners();

      // print(json.decode(response.body)); //instance of respone
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final profIndex = items_.indexWhere((element) => element.id == id);
    if (profIndex >= 0) {
      final url = Uri.parse('$baseURL products/$id.json?auth=$authtoken');
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          }));
      items_[profIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  List<Product> get favorites {
    return items_.where((productItems) => productItems.isFavorite).toList();
  }
  // void shoFav() {
  //   _showOnlyFav = true;
  //      notifyListeners();
  // }

  // void showAll() {
  //   _showOnlyFav = false;
  //   notifyListeners();
  // }
  // notifyListeners();
  Future<void> deleteProduct_(String id) async {
    final url = Uri.parse('$baseURL products/$id.json?auth=$authtoken');

    final existingProductIndex =
        items_.indexWhere((element) => element.id == id);
    Product? existingProduct = items_[existingProductIndex];
    items_.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      items_.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw OwnHttpException(message: 'Could not delete product');
    }
    existingProduct = null;
    print(response.statusCode);

    /** Normal removing products 
     http.delete(url);
    _items.removeWhere((element) => element.id == id);
    notifyListeners()
    */
  }
}
