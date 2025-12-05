import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class OpenFoodFactsService {
  static const String baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  /// Fetch product information by barcode/UPC
  /// 
  /// [barcode] - The barcode/UPC code to look up
  /// Returns [Product] if found, null otherwise
  static Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$baseUrl/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Check if product was found
        if (jsonData['status'] == 1 && jsonData['product'] != null) {
          return Product.fromJson(jsonData);
        } else {
          // Product not found
          return null;
        }
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }
}

