import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Contact Box ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC33).withOpacity(0.15), // Vàng nhạt trong suốt
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCC33), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 40, color: Color(0xFFCC9900)), // Vàng đậm
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Cần hỗ trợ trực tiếp?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Hotline: 1900 1234\nEmail: support@courseapp.com', style: TextStyle(fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // --- FAQ Section ---
            const Text('Câu hỏi thường gặp (FAQ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            
            _buildFaqItem(
              question: 'Làm sao để nhận chứng chỉ sau khi học?',
              answer: 'Sau khi hoàn thành 100% video bài giảng và vượt qua bài kiểm tra cuối khóa với điểm số trên 80%, hệ thống sẽ tự động cấp chứng chỉ điện tử cho bạn vào mục "Hồ sơ".',
            ),
            _buildFaqItem(
              question: 'Khóa học đã mua có thời hạn bao lâu?',
              answer: 'Hầu hết các khóa học trên hệ thống đều có giá trị trọn đời. Bạn chỉ cần thanh toán một lần và có thể học lại bất cứ lúc nào.',
            ),
            _buildFaqItem(
              question: 'Lỗi không thể tải được video bài giảng?',
              answer: 'Vui lòng kiểm tra lại kết nối mạng. Nếu vẫn bị lỗi, hãy thử vào Cài đặt -> Tắt bộ nhớ đệm hoặc đăng xuất ra vào lại.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Xóa dòng kẻ ngang mặc định
        child: ExpansionTile(
          iconColor: const Color(0xFFFFCC33),
          collapsedIconColor: Colors.grey,
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}