import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_app/core/exceptions/app_exception.dart';
import 'package:product_app/core/utils/file_logger.dart';
import 'package:product_app/core/utils/result.dart';
import 'package:product_app/core/utils/safe_runner.dart';
import 'package:product_app/main.dart';
import 'package:product_app/models/product.dart';

void main() {
  group('1. OOP Nâng Cao Tests (Named, Factory Constructor, Mixins, Generics)', () {
    test('Named Constructor: Product.draft tạo đúng giá trị mặc định', () {
      final draft = Product.draft(id: 'DR-01', name: 'Sản phẩm nháp');
      expect(draft.id, 'DR-01');
      expect(draft.name, 'Sản phẩm nháp');
      expect(draft.price, 0.0);
      expect(draft.isDraft, true);
    });

    test('Factory Constructor: Product.fromJson parse dữ liệu hợp lệ', () {
      final json = {
        'id': 'PRD-01',
        'name': 'Bàn phím cơ',
        'price': 1500000.0,
        'discountPercent': 10.0,
        'stock': 5,
        'category': 'Phụ kiện',
      };

      final product = Product.fromJson(json);
      expect(product.id, 'PRD-01');
      expect(product.name, 'Bàn phím cơ');
      expect(product.price, 1500000.0);
      expect(product.finalPrice, 1350000.0); // 10% discount
    });

    test('ValidationMixin: Ném ValidationException khi giá âm hoặc tên rỗng', () {
      // Thử giá âm
      final jsonBadPrice = {
        'id': 'PRD-02',
        'name': 'Chuột gaming',
        'price': -1000.0,
      };
      expect(
        () => Product.fromJson(jsonBadPrice),
        throwsA(isA<ValidationException>()),
      );

      // Thử tên rỗng
      final jsonBadName = {
        'id': 'PRD-03',
        'name': '   ',
        'price': 200000.0,
      };
      expect(
        () => Product.fromJson(jsonBadName),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Factory Constructor: Ném DataParsingException khi sai kiểu dữ liệu', () {
      final jsonBadType = {
        'id': 'PRD-04',
        'name': 'Màn hình 4K',
        'price': 'Năm triệu', // Sai kiểu String thay vì num
      };
      expect(
        () => Product.fromJson(jsonBadType),
        throwsA(isA<DataParsingException>()),
      );
    });
  });

  group('2. Safe Wrapper & Result Pattern Tests (Zero Crash)', () {
    test('SafeRunner trả về Success<T> khi tác vụ hợp lệ', () async {
      final result = await SafeRunner.run<String>(() async => 'Hello Dart');
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'Hello Dart');
    });

    test('SafeRunner bắt ValidationException và trả về Failure<T> an toàn', () async {
      final result = await SafeRunner.run<Product>(() async {
        return Product.fromJson({'id': 'E1', 'name': '', 'price': 100});
      });

      expect(result, isA<Failure<Product>>());
      final failure = result as Failure<Product>;
      expect(failure.errorCode, 'VALIDATION_ERROR');
      expect(failure.technicalError, isA<ValidationException>());
    });

    test('SafeRunner bắt cả lỗi nghiêm trọng (RangeError) mà KHÔNG CRASH', () async {
      final result = await SafeRunner.run<int>(() async {
        final list = <int>[];
        return list[10]; // Ném RangeError
      });

      expect(result, isA<Failure<int>>());
      final failure = result as Failure<int>;
      expect(failure.technicalError, isA<RangeError>());
    });
  });

  group('3. File Logging Tests (Ghi log thông báo lỗi ra file ngoài)', () {
    test('FileLogger tự động ghi log lỗi ra tập tin app_error.log khi có lỗi', () async {
      // Đảm bảo làm sạch file cũ trước khi test
      await FileLogger.clearLogFile();

      // Kích hoạt lỗi qua SafeRunner
      await SafeRunner.run<Product>(() async {
        return Product.fromJson({'id': 'TEST-ERR', 'name': '', 'price': -500});
      });

      // Chờ I/O hoàn tất
      await Future.delayed(const Duration(milliseconds: 50));

      // Kiểm tra file log đã tồn tại và có nội dung
      final logFile = FileLogger.logFile;
      expect(await logFile.exists(), isTrue);

      final content = await FileLogger.readLogContent();
      expect(content, contains('[ERROR]'));
      expect(content, contains('ValidationException'));
    });
  });

  group('4. UI Smoke Tests (Giao diện PT product app)', () {
    testWidgets('Màn hình chính hiển thị đúng tiêu đề PT product app và nút reload', (tester) async {
      await tester.pumpWidget(const ProductApp());
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('PT product app'), findsOneWidget);

      // Kiểm tra nút reload và nút thêm sản phẩm
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Thêm sản phẩm'), findsOneWidget);

      // Kiểm tra các phần kịch bản cũ đã bị loại bỏ
      expect(find.byIcon(Icons.terminal), findsNothing);
      expect(find.text('KIỂM THỬ CÁC KỊCH BẢN XỬ LÝ LỖI:'), findsNothing);
      expect(find.text('Chế độ bảo vệ Zero-Crash: Mọi thao tác đều bọc qua SafeRunner.run<T>()'), findsNothing);
    });

    testWidgets('Bắt lỗi khi người dùng nhập sai trong form thêm sản phẩm', (tester) async {
      await tester.pumpWidget(const ProductApp());
      await tester.pumpAndSettle();

      // Nhấn nút Thêm sản phẩm
      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pumpAndSettle();

      // Nhập tên rỗng và giá không hợp lệ
      final nameFinder = find.widgetWithText(TextField, 'Tên sản phẩm*');
      await tester.enterText(nameFinder, ''); // Tên rỗng

      // Nhấn Lưu sản phẩm
      await tester.tap(find.text('Lưu sản phẩm'));
      await tester.pumpAndSettle();

      // Kiểm tra thông báo lỗi đơn giản hiển thị
      expect(find.text('Thông báo lỗi'), findsOneWidget);
      expect(find.textContaining('không được phép để trống'), findsOneWidget);

      // Nhấn nút Đóng trên dialog
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      // Dialog đã đóng
      expect(find.text('Thông báo lỗi'), findsNothing);
    });
  });
}
