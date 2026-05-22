import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';

// =======================================================
// MÀN HÌNH CHÍNH: GIỎ HÀNG (Giữ tên class để không lỗi Nav)
// =======================================================
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  bool _isCheckingOut = false;

  // Trạng thái Voucher
  String _voucherCode = '';
  double _discountPercent = 0;
  bool _isApplyingVoucher = false;
  String _voucherMessage = '';
  bool _isVoucherError = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    final items = await CourseService.getCart();
    if (mounted) {
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    }
  }

  // 1. CẬP NHẬT HÀM TÍNH TỔNG TIỀN AN TOÀN
  double get _subTotal {
    double total = 0;
    for (var item in _cartItems) {
      final Map<String, dynamic> c = item is Map
          ? Map<String, dynamic>.from(item)
          : {};
      // Tìm kiếm thông tin khóa học trong mọi trường bóc tách có thể có
      final khoaHoc =
          c['course'] ?? c['khoaHoc'] ?? c['maKhoaHocNavigation'] ?? c;
      double price = (khoaHoc['price'] ?? khoaHoc['giaGoc'] ?? 0).toDouble();
      total += price;
    }
    return total;
  }

  double get _discountAmount => (_subTotal * _discountPercent) / 100;
  double get _finalTotal =>
      (_subTotal - _discountAmount) > 0 ? (_subTotal - _discountAmount) : 0;

  // --- Actions ---
  void _applyVoucher() async {
    if (_voucherCode.trim().isEmpty) {
      setState(() {
        _voucherMessage = 'Vui lòng nhập mã giảm giá';
        _isVoucherError = true;
      });
      return;
    }

    setState(() {
      _isApplyingVoucher = true;
      _voucherMessage = '';
    });

    final res = await CourseService.applyVoucher(_voucherCode.trim());
    if (mounted) {
      setState(() {
        _isApplyingVoucher = false;
        if (res != null && res['error'] == null) {
          _discountPercent = (res['phanTramGiam'] ?? 0).toDouble();
          _voucherMessage = res['message'] ?? 'Áp dụng mã thành công!';
          _isVoucherError = false;
        } else {
          _discountPercent = 0;
          _voucherMessage = res?['error'] ?? 'Mã không hợp lệ';
          _isVoucherError = true;
        }
      });
    }
  }

  void _removeItem(int courseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khóa học?'),
        content: const Text('Bạn có chắc muốn xóa khóa học này khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await CourseService.removeFromCart(courseId);
              if (success) {
                _loadCart();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa khỏi giỏ hàng')),
                  );
                }
              }
            },
            child: const Text(
              'Xóa ngay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isCheckingOut = true);
    final res = await CourseService.checkoutCart(_voucherCode.trim());

    if (mounted) {
      setState(() => _isCheckingOut = false);
      if (res != null && res['error'] == null) {
        // Thành công
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('🎉 Thanh toán thành công!'),
            content: Text(
              res['soTienGiam'] != null && res['soTienGiam'] > 0
                  ? 'Bạn đã áp dụng mã và được giảm ${res['soTienGiam']}đ. Bắt đầu học ngay nhé!'
                  : 'Đơn hàng của bạn đã được xử lý. Bạn có thể bắt đầu học ngay.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadCart(); // Xóa sạch giỏ hàng
                },
                child: const Text('Tuyệt vời'),
              ),
            ],
          ),
        );
      } else {
        // Thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['error'] ?? 'Thanh toán thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesListScreen()),
              ).then((_) => _loadCart());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCart,
        color: const Color(0xFF1E88E5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cartItems.isEmpty
            ? ListView(
                // Sử dụng ListView kèm thuộc tính AlwaysScrollableScrollPhysics để cho phép kéo làm mới ngay cả khi giỏ hàng trống
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildEmptyCart(),
                  ),
                ],
              )
            : Column(
                children: [
                  // Danh sách item
                  Expanded(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) =>
                          _buildCartItem(_cartItems[index]),
                    ),
                  ),
                  // Khu vực Checkout dính ở đáy
                  _buildCheckoutBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Giỏ hàng trống',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tìm thêm các khóa học bổ ích nhé.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final Map<String, dynamic> c = item is Map
        ? Map<String, dynamic>.from(item)
        : {};
    // Quét chuỗi phức hợp từ cấu trúc Entity Framework (.NET)
    final khoaHoc =
        c['course'] ?? c['khoaHoc'] ?? c['maKhoaHocNavigation'] ?? c;

    int courseId = khoaHoc['id'] ?? khoaHoc['maKhoaHoc'] ?? c['courseId'] ?? 0;
    String title = khoaHoc['title'] ?? khoaHoc['tieuDe'] ?? 'Khóa học học tập';
    String instructor =
        khoaHoc['instructor'] ?? khoaHoc['giangVien'] ?? 'Đang cập nhật';
    String image = khoaHoc['image'] ?? khoaHoc['anhUrl'] ?? '';
    double price = (khoaHoc['price'] ?? khoaHoc['giaGoc'] ?? 0).toDouble();
    double originalPrice =
        (khoaHoc['originalPrice'] ?? khoaHoc['giaGoc'] ?? price).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail khóa học
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: courseId),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 90,
                  height: 70,
                  color: Colors.blue.shade50,
                  child: image.isNotEmpty && image.startsWith('http')
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.school, color: Colors.blue),
                        )
                      : const Icon(Icons.school, color: Colors.blue, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nội dung thông tin khóa học bên phải
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(courseId: courseId),
                      ),
                    ),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${price.toInt()}đ',
                            style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (originalPrice > price)
                            Text(
                              '${originalPrice.toInt()}đ',
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _removeItem(courseId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng nhập Voucher
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      onChanged: (v) => _voucherCode = v,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã giảm giá...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isApplyingVoucher ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isApplyingVoucher
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Áp dụng',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
            if (_voucherMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _voucherMessage,
                  style: TextStyle(
                    color: _isVoucherError ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Dòng tính toán tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính:', style: TextStyle(color: Colors.grey)),
                Text(
                  '${_subTotal.toInt()}đ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_discountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giảm giá (${_discountPercent.toInt()}%):',
                      style: const TextStyle(color: Colors.green),
                    ),
                    Text(
                      '-${_discountAmount.toInt()}đ',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_finalTotal.toInt()}đ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nút Checkout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCheckingOut ? null : _checkout,
                icon: _isCheckingOut
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                label: _isCheckingOut
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Thanh toán ngay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// MÀN HÌNH YÊU THÍCH (Được tách ra từ file cũ)
// =======================================================
class FavoritesListScreen extends StatefulWidget {
  const FavoritesListScreen({super.key});

  @override
  State<FavoritesListScreen> createState() => _FavoritesListScreenState();
}

class _FavoritesListScreenState extends State<FavoritesListScreen> {
  List<ApiCourse> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() async {
    final bookmarks = await CourseService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Khóa học yêu thích',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? const Center(
              child: Text(
                'Chưa có khóa học yêu thích nào.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final course = _bookmarks[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailsScreen(courseId: course.id),
                      ),
                    ).then((_) => _loadBookmarks());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              image: course.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(course.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: course.imageUrl == null
                                ? const Icon(
                                    Icons.school,
                                    color: Color(0xFF1E88E5),
                                    size: 36,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${course.price.toInt()}đ',
                                  style: const TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${course.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () async {
                              await CourseService.toggleBookmark(course.id);
                              _loadBookmarks();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
