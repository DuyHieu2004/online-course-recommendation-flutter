import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';
import 'learn_screen.dart';

class CourseListScreen extends StatefulWidget {
  final String? initialSearch;
  final int? initialCategoryId;

  const CourseListScreen({
    super.key,
    this.initialSearch,
    this.initialCategoryId,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  bool _isLoading = true;
  List<ApiCourse> _allCourses = [];
  List<ApiCourse> _filteredCourses = [];
  List<dynamic> _categories = [];

  // DỮ LIỆU ĐỂ CROSS-CHECK TRẠNG THÁI KHÓA HỌC BÊN NGOÀI GIAO DIỆN
  List<dynamic> _myCourses = [];
  List<dynamic> _cartItems = [];

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Tất cả';
  int? _selectedCategoryId;
  String _selectedLevel = 'Tất cả';
  double _selectedRating = 0;
  String _selectedPrice = 'all';
  String _selectedSort = '';

  final List<String> _levels = ['Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'];
  final List<Map<String, dynamic>> _ratingOptions = [
    {'label': 'Tất cả', 'value': 0.0},
    {'label': '4.5 trở lên', 'value': 4.5},
    {'label': '4.0 trở lên', 'value': 4.0},
    {'label': '3.5 trở lên', 'value': 3.5},
  ];
  final List<Map<String, String>> _priceOptions = [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Miễn phí', 'value': 'free'},
    {'label': 'Có phí', 'value': 'paid'},
    {'label': 'Dưới 200.000đ', 'value': 'under200k'},
    {'label': '200.000đ - 500.000đ', 'value': '200k-500k'},
    {'label': 'Trên 500.000đ', 'value': 'above500k'},
  ];
  final Map<String, String> _sortMap = {
    '': 'Phù hợp nhất',
    'price_asc': 'Giá: Thấp → Cao',
    'price_desc': 'Giá: Cao → Thấp',
    'rating_desc': 'Đánh giá cao nhất',
    'newest': 'Mới nhất',
    'popular': 'Phổ biến nhất',
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _selectedCategoryId = widget.initialCategoryId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // GỌI API LẤY CATEGORY, KHÓA HỌC CỦA TÔI VÀ GIỎ HÀNG SONG SONG
    final results = await Future.wait([
      CourseService.getCategories(),
      CourseService.getMyCourses(),
      CourseService.getCart(),
    ]);

    if (mounted) {
      setState(() {
        _categories = results[0] as List<dynamic>;
        _myCourses = results[1] as List<dynamic>;
        _cartItems = results[2] as List<dynamic>;

        if (_selectedCategoryId != null) {
          final cat = _categories.firstWhere(
            (c) =>
                c['maTheLoai'] == _selectedCategoryId ||
                c['MaTheLoai'] == _selectedCategoryId,
            orElse: () => null,
          );
          if (cat != null) {
            _selectedCategory = cat['ten'] ?? cat['Ten'] ?? cat['TenTheLoai'];
          }
        }
      });
    }

    await _fetchCoursesFromApi();
  }

  Future<void> _fetchCoursesFromApi() async {
    setState(() => _isLoading = true);

    String? apiSortOption;
    if (_selectedSort == 'price_asc') apiSortOption = 'price';
    if (_selectedSort == 'price_desc') apiSortOption = 'price_desc';
    if (_selectedSort == 'rating_desc') apiSortOption = 'rating';
    if (_selectedSort == 'newest') apiSortOption = 'newest';
    if (_selectedSort == 'popular') apiSortOption = 'popular';

    final courses = await CourseService.getCourses(
      search: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      sortBy: apiSortOption,
    );

    if (mounted) {
      setState(() {
        _allCourses = courses;
        _applyClientFilters();
        _isLoading = false;
      });
    }
  }

  // Helper hàm dùng chung bóc tách ID an toàn
  int _extractId(dynamic item) {
    if (item == null) return 0;
    if (item is Map) {
      final c =
          item['course'] ??
          item['khoaHoc'] ??
          item['maKhoaHocNavigation'] ??
          item;
      return c['id'] ?? c['maKhoaHoc'] ?? c['courseId'] ?? 0;
    }
    try {
      return item.id ?? item.maKhoaHoc ?? item.courseId ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isEnrolled(int courseId) =>
      _myCourses.any((c) => _extractId(c) == courseId);
  bool _isInCart(int courseId) =>
      _cartItems.any((c) => _extractId(c) == courseId);

  void _applyClientFilters() {
    List<ApiCourse> result = List.from(_allCourses);
    if (_selectedPrice != 'all') {
      result = result.where((c) {
        final price = c.price ?? 0;
        switch (_selectedPrice) {
          case 'free':
            return price == 0;
          case 'paid':
            return price > 0;
          case 'under200k':
            return price > 0 && price < 200000;
          case '200k-500k':
            return price >= 200000 && price <= 500000;
          case 'above500k':
            return price > 500000;
          default:
            return true;
        }
      }).toList();
    }
    if (_selectedSort == 'price_asc')
      result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    else if (_selectedSort == 'price_desc')
      result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));

    setState(() => _filteredCourses = result);
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    _fetchCoursesFromApi();
  }

  Future<void> _handleAddToCart(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua khóa học!')),
      );
      return;
    }

    final res = await CourseService.addToCart(courseId);
    if (mounted) {
      if (res['success'] == true) {
        // Render UI thành nút "Đã trong giỏ" ngay lập tức
        final newCart = await CourseService.getCart();
        setState(() => _cartItems = newCart);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCategory = 'Tất cả';
                                _selectedCategoryId = null;
                                _selectedLevel = 'Tất cả';
                                _selectedRating = 0;
                                _selectedPrice = 'all';
                                _selectedSort = '';
                              });
                            },
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const Text(
                            'Bộ Lọc Khóa Học',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildFilterSectionTitle('Sắp xếp theo'),
                          _buildDropdownFilter(
                            value: _selectedSort,
                            items: _sortMap.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setModalState(
                              () => _selectedSort = val.toString(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('Danh mục'),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: _selectedCategory == 'Tất cả',
                                onSelected: (val) {
                                  if (val)
                                    setModalState(() {
                                      _selectedCategory = 'Tất cả';
                                      _selectedCategoryId = null;
                                    });
                                },
                              ),
                              ..._categories.map((cat) {
                                final name =
                                    cat['ten'] ??
                                    cat['Ten'] ??
                                    cat['TenTheLoai'];
                                final id = cat['maTheLoai'] ?? cat['MaTheLoai'];
                                return ChoiceChip(
                                  label: Text(name),
                                  selected: _selectedCategory == name,
                                  onSelected: (val) {
                                    if (val)
                                      setModalState(() {
                                        _selectedCategory = name;
                                        _selectedCategoryId = id;
                                      });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('Mức giá'),
                          Wrap(
                            spacing: 8,
                            children: _priceOptions.map((p) {
                              return ChoiceChip(
                                label: Text(p['label']!),
                                selected: _selectedPrice == p['value'],
                                onSelected: (val) {
                                  if (val)
                                    setModalState(
                                      () => _selectedPrice = p['value']!,
                                    );
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          _buildFilterSectionTitle('Đánh giá tối thiểu'),
                          Column(
                            children: _ratingOptions.map((r) {
                              return RadioListTile(
                                title: Row(
                                  children: [
                                    if (r['value'] > 0)
                                      ...List.generate(
                                        (r['value'] as double).floor(),
                                        (index) => const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(r['label']),
                                  ],
                                ),
                                value: r['value'],
                                groupValue: _selectedRating,
                                onChanged: (val) => setModalState(
                                  () => _selectedRating = val as double,
                                ),
                                contentPadding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchCoursesFromApi();
                          },
                          child: const Text(
                            'Áp Dụng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );
  Widget _buildDropdownFilter({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Khám phá',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học, kỹ năng...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _onSearch,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Hiển thị ${_filteredCourses.length} khóa học',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy khóa học nào.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      final String priceText =
                          course.price == null || course.price == 0
                          ? 'Miễn phí'
                          : '${course.price}đ';

                      // KIỂM TRA TRẠNG THÁI KHÓA HỌC
                      final bool isOwned = _isEnrolled(course.id);
                      final bool isInCart = _isInCart(course.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseDetailsScreen(courseId: course.id),
                              ),
                            ).then(
                              (_) => _loadInitialData(),
                            ); // Khi pop về thì reload để cập nhật trạng thái
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  color: Colors.blue.shade50,
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
                                        color: Colors.blue,
                                        size: 50,
                                      )
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${course.rating ?? "Chưa có đánh giá"}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          priceText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: course.price == 0
                                                ? Colors.green
                                                : Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // UI BUTTON DỰA THEO TRẠNG THÁI
                                    SizedBox(
                                      width: double.infinity,
                                      child: isOwned
                                          ? OutlinedButton.icon(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => LearnScreen(
                                                    courseId: course.id,
                                                  ),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.play_circle_outline,
                                                size: 18,
                                              ),
                                              label: const Text('Vào học ngay'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                side: const BorderSide(
                                                  color: Colors.green,
                                                ),
                                              ),
                                            )
                                          : isInCart
                                          ? OutlinedButton.icon(
                                              onPressed:
                                                  null, // Vô hiệu hóa nút
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Đã có trong giỏ hàng',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                disabledForegroundColor:
                                                    Colors.grey,
                                                side: const BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : OutlinedButton.icon(
                                              onPressed: () =>
                                                  _handleAddToCart(course.id),
                                              icon: const Icon(
                                                Icons.shopping_cart_checkout,
                                                size: 18,
                                              ),
                                              label: const Text('Thêm vào giỏ'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF1E88E5,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFF1E88E5),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
