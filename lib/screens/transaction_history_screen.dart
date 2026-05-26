import 'package:flutter/material.dart';
import '../services/course_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    // Assuming there's a service method for this. If not, we'll mock it for now.
    // Based on the context, we'll try to get it from CourseService or similar.
    try {
      // Placeholder: in a real app, this would be an API call
      // For now, we'll show a "No transactions" state if not found
      setState(() {
        _transactions = []; 
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFCC33),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC33)))
          : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Chưa có lịch sử giao dịch',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final DateTime date = DateTime.parse(tx['ngayGiaoDich'] ?? DateTime.now().toString());
        final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['tenKhoaHoc'] ?? 'Thanh toán khóa học',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tx['soTien'] ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }
}
