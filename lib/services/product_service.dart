import 'dart:async';
import '../core/exceptions/app_exception.dart';
import '../core/mixins/logger_mixin.dart';
import '../models/product.dart';

/// Dịch vụ quản lý dữ liệu sản phẩm (Product Service)
/// Áp dụng [LoggerMixin] để tự động ghi nhật ký các thao tác.
class ProductService with LoggerMixin {
  final List<Product> _products = [];

  ProductService() {
    _initDefaultData();
  }

  void _initDefaultData() {
    logInfo('Khởi tạo kho dữ liệu sản phẩm mặc định');
    _products.addAll([
      Product.fromJson({
        'id': 'PRD-001',
        'name': 'Bàn phím cơ không dây NuPhy Air75',
        'price': 2450000.0,
        'category': 'Phụ kiện máy tính',
        'discountPercent': 10.0,
        'stock': 15,
      }),
      Product.fromJson({
        'id': 'PRD-002',
        'name': 'Chuột công thái học Logitech MX Master 3S',
        'price': 2290000.0,
        'category': 'Phụ kiện máy tính',
        'discountPercent': 5.0,
        'stock': 20,
      }),
      Product.discounted(
        id: 'PRD-003',
        name: 'Màn hình Dell UltraSharp 27" 4K',
        price: 13500000.0,
        discountPercent: 15.0,
        category: 'Màn hình',
        stock: 8,
      ),
      Product.draft(
        id: 'PRD-004',
        name: 'Tai nghe chụp tai Sony WH-1000XM5 (Bản nháp)',
        category: 'Âm thanh',
        stock: 0,
      ),
    ]);
  }

  /// Lấy toàn bộ danh sách sản phẩm hiện có
  Future<List<Product>> getProducts() async {
    logInfo('Đang tải danh sách sản phẩm từ kho dữ liệu...');
    await Future.delayed(const Duration(milliseconds: 300)); // Giả lập độ trễ I/O
    return List.unmodifiable(_products);
  }

  /// Thêm một sản phẩm mới vào kho
  Future<Product> addProduct(Product product) async {
    logInfo('Thực hiện thêm sản phẩm mới: ${product.name}');
    await Future.delayed(const Duration(milliseconds: 300));

    // Kiểm tra trùng mã sản phẩm
    final existingIndex = _products.indexWhere((p) => p.id == product.id);
    if (existingIndex >= 0) {
      throw ValidationException(
        'Mã sản phẩm "${product.id}" đã tồn tại trong hệ thống.',
        fieldName: 'id',
      );
    }

    _products.insert(0, product);
    logInfo('Đã thêm sản phẩm thành công: ID = ${product.id}');
    return product;
  }

  /// Xóa sản phẩm khỏi kho
  Future<void> deleteProduct(String id) async {
    logInfo('Yêu cầu xóa sản phẩm ID: $id');
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _products.indexWhere((p) => p.id == id);
    if (index < 0) {
      throw NotFoundException(
        'Không tìm thấy sản phẩm có mã "$id" để xóa.',
        resourceId: id,
      );
    }

    final removed = _products.removeAt(index);
    logInfo('Đã xóa thành công sản phẩm: ${removed.name}');
  }

  // ===========================================================================
  // CÁC KỊCH BẢN THỬ NGHIỆM XỬ LÝ LỖI (ERROR HANDLING TEST SCENARIOS)
  // ===========================================================================

  /// Kịch bản 1: Tải dữ liệu chuẩn (Thành công 100%)
  Future<Product> scenarioValidProduct() async {
    logInfo('[Kịch bản 1] Giả lập API trả về JSON sản phẩm hoàn chỉnh');
    await Future.delayed(const Duration(milliseconds: 400));

    final rawJson = {
      'id': 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'name': 'MacBook Air M3 15-inch',
      'price': 32990000.0,
      'category': 'Laptop',
      'discountPercent': 8.0,
      'stock': 12,
    };

    final product = Product.fromJson(rawJson);
    _products.insert(0, product);
    return product;
  }

  /// Kịch bản 2: Dữ liệu bị giá âm (Kích hoạt ValidationException từ Mixin)
  Future<Product> scenarioNegativePrice() async {
    logWarning('[Kịch bản 2] Giả lập dữ liệu trả về bị lỗi GIÁ ÂM');
    await Future.delayed(const Duration(milliseconds: 400));

    final badJson = {
      'id': 'PRD-ERR-01',
      'name': 'Loa Bluetooth JBL Flip 6',
      'price': -1250000.0, // Lỗi: Giá âm
      'category': 'Âm thanh',
    };

    // Khi gọi Product.fromJson, ValidationMixin sẽ ném ValidationException
    return Product.fromJson(badJson);
  }

  /// Kịch bản 3: Dữ liệu thiếu trường bắt buộc (Tên rỗng)
  Future<Product> scenarioEmptyName() async {
    logWarning('[Kịch bản 3] Giả lập dữ liệu trả về bị TÊN RỖNG');
    await Future.delayed(const Duration(milliseconds: 400));

    final badJson = {
      'id': 'PRD-ERR-02',
      'name': '   ', // Lỗi: Tên rỗng
      'price': 500000.0,
      'category': 'Phụ kiện',
    };

    return Product.fromJson(badJson);
  }

  /// Kịch bản 4: Dữ liệu JSON sai kiểu (Giá là chuỗi văn bản thay vì số)
  Future<Product> scenarioMalformedJson() async {
    logWarning('[Kịch bản 4] Giả lập JSON SAI KIỂU DỮ LIỆU (Price là String)');
    await Future.delayed(const Duration(milliseconds: 400));

    final badJson = {
      'id': 'PRD-ERR-03',
      'name': 'Webcam 4K Logitech Brio',
      'price': 'Năm triệu hai trăm ngàn', // Lỗi kiểu dữ liệu
      'category': 'Camera',
    };

    return Product.fromJson(badJson);
  }

  /// Kịch bản 5: Lỗi kết nối mạng (Giả lập HTTP 503 / Socket error)
  Future<Product> scenarioNetworkError() async {
    logError('[Kịch bản 5] Giả lập rớt mạng khi đang gọi máy chủ');
    await Future.delayed(const Duration(milliseconds: 600));

    throw NetworkException(
      'Không thể hoàn tất kết nối tới máy chủ (Mã trạng thái 503)',
      statusCode: 503,
    );
  }

  /// Kịch bản 6: Lỗi sập hệ thống bất ngờ (Lập trình viên gọi phần tử ngoài mảng RangeError)
  Future<Product> scenarioUnexpectedCrash() async {
    logError('[Kịch bản 6] Giả lập lỗi code sai sót nghiêm trọng (RangeError)');
    await Future.delayed(const Duration(milliseconds: 300));

    // Cố tình truy cập mảng rỗng gây RangeError (Bug code nghiêm trọng)
    final emptyList = <String>[];
    final _ = emptyList[99]; // Ném RangeError của Dart SDK

    return Product.draft(id: '99', name: 'Never reaches here');
  }
}
