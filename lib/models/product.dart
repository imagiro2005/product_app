import '../core/exceptions/app_exception.dart';
import '../core/mixins/logger_mixin.dart';
import '../core/mixins/validation_mixin.dart';

/// Class phụ trợ giúp Factory Constructor sử dụng các phương thức kiểm tra của [ValidationMixin].
class _ProductValidator with ValidationMixin {}

/// Model Sản phẩm áp dụng đầy đủ:
/// - Named Constructor (Product.draft, Product.discounted)
/// - Factory Constructor (Product.fromJson)
/// - Mixin (LoggerMixin)
class Product with LoggerMixin {
  final String id;
  final String name;
  final double price;
  final String category;
  final double discountPercent; // 0.0 -> 100.0
  final int stock;
  final bool isDraft;
  final DateTime createdAt;

  // 1. Generative Constructor cơ bản (Internal để quản lý khởi tạo tập trung)
  Product._internal({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.discountPercent,
    required this.stock,
    required this.isDraft,
    required this.createdAt,
  });

  // 2. Named Constructor: Tạo sản phẩm bản nháp (Draft) với giá 0đ
  Product.draft({
    required this.id,
    required this.name,
    this.category = 'Chưa phân loại',
    this.stock = 0,
  })  : price = 0.0,
        discountPercent = 0.0,
        isDraft = true,
        createdAt = DateTime.now();

  // 3. Named Constructor: Tạo sản phẩm khuyến mãi có chiết khấu định sẵn
  Product.discounted({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPercent,
    this.category = 'Khuyến mãi',
    this.stock = 10,
  })  : isDraft = false,
        createdAt = DateTime.now() {
    final validator = _ProductValidator();
    validator.requirePositiveNumber(price, 'Giá gốc');
    validator.requireRange(discountPercent, 1, 99, 'Tỷ lệ giảm giá');
  }

  // 4. Factory Constructor: Phân tích cú pháp dữ liệu từ Map/JSON
  // Kết hợp ValidationMixin để bắt lỗi dữ liệu đầu vào ngay khi tạo đối tượng
  factory Product.fromJson(Map<String, dynamic> json) {
    final validator = _ProductValidator();

    // 4.1. Kiểm tra ID
    final id = json['id'] as String?;
    validator.requireNotEmpty(id, 'Mã sản phẩm (id)');

    // 4.2. Kiểm tra Tên sản phẩm
    final name = json['name'] as String?;
    validator.requireNotEmpty(name, 'Tên sản phẩm (name)');
    validator.requireMinLength(name, 2, 'Tên sản phẩm (name)');

    // 4.3. Kiểm tra Giá sản phẩm (bắt lỗi sai kiểu dữ liệu)
    final rawPrice = json['price'];
    if (rawPrice == null) {
      throw ValidationException(
        'Giá sản phẩm không được để trống.',
        fieldName: 'price',
      );
    }
    if (rawPrice is! num) {
      throw DataParsingException(
        'Giá sản phẩm phải là một số (Hiện tại là ${rawPrice.runtimeType}: "$rawPrice").',
        malformedKey: 'price',
      );
    }

    final price = rawPrice.toDouble();
    validator.requirePositiveNumber(price, 'Giá sản phẩm (price)');

    // 4.4. Kiểm tra giảm giá (nếu có)
    final rawDiscount = json['discountPercent'] ?? 0.0;
    if (rawDiscount is! num) {
      throw DataParsingException(
        'Tỷ lệ giảm giá phải là số hợp lệ.',
        malformedKey: 'discountPercent',
      );
    }
    final discountPercent = rawDiscount.toDouble();
    validator.requireRange(discountPercent, 0, 100, 'Tỷ lệ giảm giá');

    // 4.5. Kiểm tra số lượng tồn kho
    final rawStock = json['stock'] ?? 1;
    if (rawStock is! int && rawStock is! num) {
      throw DataParsingException(
        'Số lượng tồn kho phải là số nguyên.',
        malformedKey: 'stock',
      );
    }
    final stock = rawStock is int ? rawStock : (rawStock as num).toInt();

    final category = json['category'] as String? ?? 'Tổng hợp';
    final isDraft = json['isDraft'] as bool? ?? false;

    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    return Product._internal(
      id: id!,
      name: name!,
      price: price,
      category: category,
      discountPercent: discountPercent,
      stock: stock,
      isDraft: isDraft,
      createdAt: createdAt,
    );
  }

  /// Tính giá thực tế sau khi trừ khuyến mãi
  double get finalPrice {
    if (discountPercent <= 0) return price;
    return price * (1.0 - (discountPercent / 100.0));
  }

  /// Chuyển đối tượng thành Map/JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'discountPercent': discountPercent,
        'stock': stock,
        'isDraft': isDraft,
        'createdAt': createdAt.toIso8601String(),
      };

  Product copyWith({
    String? name,
    double? price,
    String? category,
    double? discountPercent,
    int? stock,
    bool? isDraft,
  }) {
    return Product._internal(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      discountPercent: discountPercent ?? this.discountPercent,
      stock: stock ?? this.stock,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'Product(id: $id, name: "$name", price: \$$price, discount: $discountPercent%)';
}
