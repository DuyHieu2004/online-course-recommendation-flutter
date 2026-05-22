import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../services/auth_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // ── Palette (đồng bộ profile_screen) ─────────
  static const Color _blue = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF5F6FA);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFE53935);

  // ── State ─────────────────────────────────────
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _error = '';
  int _currentPage = 1;
  int _totalCount = 0;
  static const int _pageSize = 10;

  String _searchQuery = '';
  String _statusFilter = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _expandedOrders = {};

  // ── Lifecycle ─────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────
  Future<void> _loadOrders({int page = 1}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
        _currentPage = page;
      });
    }

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = 'Vui lòng đăng nhập.';
        });
      return;
    }

    try {
      String url =
          '${ApiConstants.baseUrl}/Orders?page=$page&pageSize=$_pageSize';
      if (_searchQuery.isNotEmpty)
        url += '&search=${Uri.encodeComponent(_searchQuery)}';
      if (_statusFilter.isNotEmpty)
        url += '&status=${Uri.encodeComponent(_statusFilter)}';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );

      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _orders = data['data'] ?? [];
            _totalCount = data['totalCount'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Không thể tải dữ liệu. Vui lòng thử lại.';
          });
        }
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = 'Lỗi kết nối máy chủ.';
        });
    }
  }

  int get _totalPages =>
      _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();

  void _toggleOrder(int orderId) {
    setState(() {
      _expandedOrders.contains(orderId)
          ? _expandedOrders.remove(orderId)
          : _expandedOrders.add(orderId);
    });
  }

  // ── Helpers ───────────────────────────────────
  String _formatDate(String raw, {bool withTime = false}) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      if (withTime) {
        final h = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        return '$d/$m/${dt.year} $h:$min';
      }
      return '$d/$m/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  /// Tính ngày hạn học tối đa (giống Angular calculateEndDate)
  String _calcEndDate(
    String purchaseDate,
    int? durationMonths,
    int? graceDays,
  ) {
    try {
      DateTime dt = DateTime.parse(purchaseDate).toLocal();
      final months = durationMonths ?? 12;
      final grace = graceDays ?? 7;
      dt = DateTime(dt.year, dt.month + months, dt.day);
      dt = dt.add(Duration(days: grace));
      return _formatDate(dt.toIso8601String());
    } catch (_) {
      return 'Không xác định';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final num val = amount is num
        ? amount
        : (num.tryParse(amount.toString()) ?? 0);
    final str = val.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${buf}đ';
  }

  // ── BUILD ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử mua hàng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => _loadOrders(page: _currentPage),
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_error.isNotEmpty) return _buildErrorState();
    if (_orders.isEmpty) return _buildEmptyState();
    return _buildOrdersList();
  }

  // ── Filter: search + status chips ─────────────
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              // Debounce đơn giản: load sau 600ms
              Future.delayed(const Duration(milliseconds: 600), () {
                if (_searchCtrl.text == v) _loadOrders();
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm mã hóa đơn hoặc tên khóa học...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Colors.black38,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black38,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadOrders();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Status filter chips (thay thế <select> của Angular, chuẩn mobile hơn)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('Tất cả', ''),
                _buildChip('Đã thanh toán', 'Đã thanh toán'),
                _buildChip('Chờ thanh toán', 'Chờ thanh toán'),
                _buildChip('Thất bại', 'Thất bại'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _statusFilter == value;
    Color chipColor;
    if (!isSelected) {
      chipColor = Colors.grey.shade100;
    } else if (value == 'Đã thanh toán') {
      chipColor = _green;
    } else if (value == 'Thất bại') {
      chipColor = _red;
    } else if (value == 'Chờ thanh toán') {
      chipColor = Colors.orange.shade600;
    } else {
      chipColor = _blue;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _statusFilter = value);
          _loadOrders();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty / Error States ──────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có hóa đơn nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy khám phá các khóa học hấp dẫn của chúng tôi.',
              style: TextStyle(fontSize: 14, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadOrders(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order list + pagination ───────────────────
  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _orders.length + (_totalPages > 1 ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _orders.length) return _buildPagination();
        return _buildOrderCard(_orders[i]);
      },
    );
  }

  // ── Order Card ────────────────────────────────
  Widget _buildOrderCard(dynamic order) {
    final orderId = (order['maHoaDon'] as num?)?.toInt() ?? 0;
    final dateStr = order['ngayTao']?.toString() ?? '';
    final status = order['tinhTrangThanhToan']?.toString() ?? '';
    final total = order['tongTien'];
    final paymentMethod = order['phuongThucThanhToan']?.toString() ?? '';
    final chiTiet = order['chiTiet'] as List<dynamic>? ?? [];
    final isExpanded = _expandedOrders.contains(orderId);
    final isPaid = status == 'Đã thanh toán';
    final isPending = status == 'Chờ thanh toán';

    Color statusColor = isPaid ? _green : (isPending ? Colors.orange : _red);
    IconData statusIcon = isPaid
        ? Icons.check_circle
        : (isPending ? Icons.access_time : Icons.cancel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header (tap để mở/đóng) ──
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: isExpanded ? Radius.zero : const Radius.circular(16),
              ),
              onTap: () => _toggleOrder(orderId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: isExpanded
                        ? Radius.zero
                        : const Radius.circular(16),
                  ),
                  border: isExpanded
                      ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$orderId',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${chiTiet.length} khóa học',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr.isNotEmpty
                                    ? _formatDate(dateStr, withTime: true)
                                    : 'Không rõ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mũi tên expand
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded ? _blue : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body: Danh sách khóa học (Expand / Collapse) ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: chiTiet.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Không có khóa học nào trong hóa đơn này.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: chiTiet
                        .map<Widget>((item) => _buildCourseItem(item, dateStr))
                        .toList(),
                  ),
            secondChild: const SizedBox.shrink(),
          ),

          // ── Footer: Phương thức + Tổng tiền ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.credit_card_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      paymentMethod.isNotEmpty ? paymentMethod : 'Không rõ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Course Item bên trong Order ───────────────
  Widget _buildCourseItem(dynamic item, String purchaseDate) {
    final khoaHoc = item['khoaHoc'] as Map<String, dynamic>? ?? {};
    final title = khoaHoc['tieuDe']?.toString() ?? 'Khóa học';
    final imageUrl = khoaHoc['anhUrl']?.toString() ?? '';
    final price = item['gia'];
    final durationMonths = (khoaHoc['thoiGianHocDuKien'] as num?)?.toInt();
    final graceDays = (khoaHoc['thoiGianChoPhepTre'] as num?)?.toInt();
    final endDate = _calcEndDate(purchaseDate, durationMonths, graceDays);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail + Tên + Giá
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 56,
                  child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thông tin thời hạn (giống Angular course-duration-details)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE3FF)),
            ),
            child: Column(
              children: [
                _durationRow(
                  Icons.access_time_outlined,
                  'Thời gian học',
                  '${durationMonths ?? 12} tháng',
                  isDeadline: false,
                ),
                const SizedBox(height: 6),
                _durationRow(
                  Icons.history,
                  'Thời gian trễ',
                  '${graceDays ?? 7} ngày',
                  isDeadline: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: Colors.indigo.shade100),
                ),
                _durationRow(
                  Icons.calendar_month_outlined,
                  'Hạn học tối đa',
                  'Đến $endDate',
                  isDeadline: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationRow(
    IconData icon,
    String label,
    String value, {
    required bool isDeadline,
  }) {
    final Color color = isDeadline ? _blue : Colors.black54;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDeadline ? _blue : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF0F4FF),
    child: const Icon(
      Icons.school_outlined,
      color: Color(0xFF1E88E5),
      size: 24,
    ),
  );

  // ── Pagination ────────────────────────────────
  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageBtn(
            icon: Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () => _loadOrders(page: _currentPage - 1),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Trang $_currentPage / $_totalPages',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          _pageBtn(
            icon: Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () => _loadOrders(page: _currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? _blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey,
          size: 22,
        ),
      ),
    );
  }
}
