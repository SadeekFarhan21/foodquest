class Product {
  final String? code;
  final String? productName;
  final String? brand;
  final String? imageUrl;
  final Map<String, dynamic>? nutriments;
  final List<String>? ingredients;
  final String? nutritionGrade;
  final String? quantity;
  final Map<String, dynamic>? categories;

  Product({
    this.code,
    this.productName,
    this.brand,
    this.imageUrl,
    this.nutriments,
    this.ingredients,
    this.nutritionGrade,
    this.quantity,
    this.categories,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) {
      throw Exception('Product data not found');
    }

    return Product(
      code: product['code'] as String?,
      productName: product['product_name'] as String? ?? product['product_name_en'] as String?,
      brand: product['brands'] as String?,
      imageUrl: product['image_url'] as String?,
      nutriments: product['nutriments'] as Map<String, dynamic>?,
      ingredients: product['ingredients_text'] != null
          ? (product['ingredients_text'] as String).split(',').map((e) => e.trim()).toList()
          : null,
      nutritionGrade: product['nutrition_grade_fr'] as String?,
      quantity: product['quantity'] as String?,
      categories: product['categories_tags'] != null
          ? {'tags': product['categories_tags']}
          : null,
    );
  }

  bool get isValid => productName != null && productName!.isNotEmpty;
}

