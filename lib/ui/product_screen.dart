import 'package:flutter/material.dart';
import '../core/mixins/logger_mixin.dart';
import '../core/utils/result.dart';
import '../core/utils/safe_runner.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> with LoggerMixin {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Tải danh sách sản phẩm thông qua SafeRunner Wrapper
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final result = await SafeRunner.run<List<Product>>(
      () => _productService.getProducts(),
      taskName: 'Tải danh sách sản phẩm',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(data: final list):
        setState(() => _products = list);

      case Failure(userMessage: final msg):
        _showErrorDialog(msg);
    }
  }

  /// Xóa sản phẩm an toàn thông qua SafeRunner
  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await SafeRunner.run<void>(
      () => _productService.deleteProduct(product.id),
      taskName: 'Xóa sản phẩm ${product.id}',
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        await _loadProducts();
        _showSnackBar('Đã xóa sản phẩm "${product.name}"', isError: false);

      case Failure(userMessage: final msg):
        _showErrorDialog(msg);
    }
  }

  /// Mở Dialog Form để thêm sản phẩm thủ công (Bắt lỗi khi người dùng nhập sai)
  void _openAddProductDialog() {
    final idController = TextEditingController(
      text: 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
    );
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final discountController = TextEditingController(text: '0');
    final stockController = TextEditingController(text: '10');
    String selectedCategory = 'Phụ kiện';
    bool isDraft = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_box, color: Color(0xFF00004C)),
                SizedBox(width: 8),
                Text('Thêm sản phẩm mới'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      labelText: 'Mã sản phẩm (ID)*',
                      prefixIcon: Icon(Icons.tag, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm*',
                      hintText: 'Ví dụ: Tai nghe chống ồn',
                      prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá sản phẩm (VNĐ)*',
                      hintText: 'Ví dụ: 1500000',
                      prefixIcon: Icon(Icons.attach_money, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giảm giá (%)',
                            prefixIcon: Icon(Icons.discount_outlined, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tồn kho',
                            prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Danh mục: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedCategory,
                        items: ['Phụ kiện', 'Laptop', 'Màn hình', 'Âm thanh', 'Khác']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Lưu dưới dạng bản nháp (Draft)?'),
                    value: isDraft,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() => isDraft = val ?? false);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00004C)),
                onPressed: () async {
                  Navigator.pop(ctx);

                  // Bọc toàn bộ quá trình phân tích và lưu sản phẩm bằng SafeRunner
                  final result = await SafeRunner.run<Product>(
                    () async {
                      // Chuẩn bị dữ liệu thô nhập từ bàn phím
                      final rawPriceInput = priceController.text.trim();
                      final rawDiscountInput = discountController.text.trim();
                      final rawStockInput = stockController.text.trim();

                      final rawMap = {
                        'id': idController.text.trim(),
                        'name': nameController.text.trim(),
                        // Thử parse số, nếu người dùng nhập chữ/sai định dạng thì giữ nguyên String để Factory bắt lỗi
                        'price': rawPriceInput.isEmpty
                            ? null
                            : (double.tryParse(rawPriceInput) ?? rawPriceInput),
                        'discountPercent': rawDiscountInput.isEmpty
                            ? 0.0
                            : (double.tryParse(rawDiscountInput) ?? rawDiscountInput),
                        'stock': rawStockInput.isEmpty
                            ? 0
                            : (int.tryParse(rawStockInput) ?? rawStockInput),
                        'category': selectedCategory,
                        'isDraft': isDraft,
                      };

                      // Khởi tạo đối tượng qua Factory Constructor (áp dụng ValidationMixin)
                      final product = Product.fromJson(rawMap);
                      return await _productService.addProduct(product);
                    },
                    taskName: 'Thêm sản phẩm mới',
                  );

                  if (!mounted) return;

                  switch (result) {
                    case Success(data: final product):
                      await _loadProducts();
                      _showSnackBar('Đã thêm sản phẩm "${product.name}" thành công', isError: false);

                    case Failure(userMessage: final msg):
                      // Hiển thị thông báo lỗi đơn giản, ngắn gọn
                      _showErrorDialog(msg);
                  }
                },
                child: const Text('Lưu sản phẩm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hiển thị thông báo lỗi đơn giản, ngắn gọn cho người dùng
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'Thông báo lỗi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00004C)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00004C), // Deep Navy Blue
        foregroundColor: Colors.white,
        title: const Text(
          'PT product app',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tiêu đề danh sách và số lượng
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Kho sản phẩm (${_products.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00004C),
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Danh sách sản phẩm
          Expanded(
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Kho hàng hiện đang trống.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: _loadProducts,
                          child: const Text('Tải lại dữ liệu mẫu'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ProductCard(
                        product: product,
                        onDelete: () => _deleteProduct(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00004C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
        onPressed: _openAddProductDialog,
      ),
    );
  }
}
