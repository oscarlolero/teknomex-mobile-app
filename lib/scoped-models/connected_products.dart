import 'dart:convert';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/user.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  int _selProductIndex;
  User _authenticatedUser;
  bool _isLoading = false;

  Future<Null> addProduct(
      String title, String description, String image, double price) {
    _isLoading = true;
    notifyListeners(); //hace un rebuild a lo que esta dentro del wrap de ScopedModelDescendant
    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'image':
          'https://diccionariodelossuenos.net/wp-content/uploads/2016/10/son%CC%83ar-con-caca-1024x666-731x475.jpg',
      'price': price,
      'username': _authenticatedUser.username,
      'userid': _authenticatedUser.id
    };
//    http://192.168.0.10:3000/test
    return http.post(
      'https://flutter-products-3e91e.firebaseio.com/products.json',
      body: json.encode(productData),
      headers: {
        "content-type": "application/json",
        "accept": "application/json",
      },
    ).then((http.Response response) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final Product newProduct = Product(
          id: responseData['name'],
          title: title,
          description: description,
          price: price,
          image: image,
          username: _authenticatedUser.username,
          userid: _authenticatedUser.id);

      _products.add(newProduct);
      _isLoading = false;
      notifyListeners(); //hace un rebuild a lo que esta dentro del wrap de ScopedModelDescendant
    });
  }
}

mixin ProductsModel on ConnectedProductsModel {
  bool _showFavorites = false;

  List<Product> get allProducts {
    //para myproductsmodel.products
    return List.from(_products); //regresa un pointer a una nueva lista
    // en memoria, para eso, si editamos esta lista, no editariamos la original, es lo que queremos
    //si hacemos return _products; se regresa la direccion de la lista de productos original D:
  }

  List<Product> get displayedProducts {
    if (_showFavorites) {
      return _products.where((Product product) => product.isFavorite).toList();
    }
    return List.from(_products);
  }

  int get selectedProductIndex {
    return _selProductIndex;
  }

  Product get selectedProduct {
    if (selectedProductIndex == null) {
      return null;
    }
    return _products[selectedProductIndex];
  }

  bool get displayFavoritesOnly {
    return _showFavorites;
  }

  Future<Null> updateProduct(
      String title, String description, String image, double price) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'image':
          'https://diccionariodelossuenos.net/wp-content/uploads/2016/10/son%CC%83ar-con-caca-1024x666-731x475.jpg',
      'price': price,
      'username': selectedProduct.username,
      'userid': selectedProduct.userid
    };
    return http
        .put(
            'https://flutter-products-3e91e.firebaseio.com/products/${selectedProduct.id}.json',
            body: json.encode(updateData))
        .then((http.Response response) {
      _isLoading = false;
      final Product updatedProduct = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          price: price,
          image: image,
          username: selectedProduct.username,
          userid: selectedProduct.userid);
      _products[selectedProductIndex] =
          updatedProduct; //no es necesario porque se re genera la lista
      notifyListeners(); //hace un rebuild a lo que esta dentro del wrap de ScopedModelDescendant
    });
  }

  void deleteProduct() {
    _isLoading = true;
    final deletedProductId = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductIndex = null;
    notifyListeners();
    http
        .delete(
            'https://flutter-products-3e91e.firebaseio.com/products/${deletedProductId}.json')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void selectProduct(int index) {
    _selProductIndex = index;
    if (index != null) {
      //https://www.udemy.com/learn-flutter-dart-to-build-ios-android-apps/learn/lecture/10840630#questions/6825196
      notifyListeners(); //This ensures, that existing pages are only immediately updated (=> re-rendered) when a product is selected, not when it's unselected.
    }
  }

  Future<Null> fetchProducts() {
    _isLoading = true;
    notifyListeners(); //hace un rebuild a lo que esta dentro del wrap de ScopedModelDescendant
    return http
        .get('https://flutter-products-3e91e.firebaseio.com/products.json')
        .then((http.Response response) {
      final List<Product> fetchedproductList = [];
      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      productListData.forEach((String productId, dynamic productData) {
        final Product product = Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            price: productData['price'],
            image: productData['image'],
            username: productData['username'],
            userid: productData['userid']);
        fetchedproductList.add(product);
      });
      _products = fetchedproductList;
      _isLoading = false;
      notifyListeners();
    });
  }

  void toggleFavoriteProduct() {
    final bool isCurrentlyFavorite = _products[selectedProductIndex].isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Product updateProduct = Product(
      //unnmutable way, best way
      title: selectedProduct.title,
      description: selectedProduct.description,
      price: selectedProduct.price,
      image: selectedProduct.image,
      username: selectedProduct.username,
      userid: selectedProduct.userid,
      isFavorite: newFavoriteStatus,
    );
    _products[selectedProductIndex] = updateProduct;
    notifyListeners(); //hace un rebuild a lo que esta dentro del wrap de ScopedModelDescendant
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

mixin UserModel on ConnectedProductsModel {
  void login(String username, String password) {
    _authenticatedUser = User(
      id: 'asdasd',
      username: username,
      password: password,
    );
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}