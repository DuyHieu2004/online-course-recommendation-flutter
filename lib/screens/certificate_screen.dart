import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateScreen extends StatelessWidget {
  final String userName;
  final String courseName;
  final String issuedDate;

  const CertificateScreen({
    super.key,
    required this.userName,
    required this.courseName,
    required this.issuedDate,
  });

  Future<void> _exportPdf(BuildContext context) async {
    // Hiển thị thông báo đang xử lý
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo và chuẩn bị in PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final pdf = pw.Document();

      // Tải font hỗ trợ tiếng Việt từ Google Fonts
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      final fontItalic = await PdfGoogleFonts.robotoItalic();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape, // Thiết kế chứng chỉ bản PDF là ngang (landscape) sẽ đẹp hơn
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber700, width: 15),
              ),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.amber700, width: 2),
                ),
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'GIẤY CHỨNG NHẬN', 
                      style: pw.TextStyle(
                        font: fontBold, 
                        fontSize: 32, 
                        color: PdfColors.amber800,
                      )
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'HOÀN THÀNH KHÓA HỌC XUẤT SẮC', 
                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.grey700)
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text('Trao tặng cho', style: pw.TextStyle(font: fontItalic, fontSize: 16)),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      userName.toUpperCase(), 
                      style: pw.TextStyle(font: fontBold, fontSize: 28)
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(width: 300, height: 1, color: PdfColors.grey),
                    pw.SizedBox(height: 15),
                    pw.Text('Đã hoàn thành xuất sắc khóa học', style: pw.TextStyle(font: fontRegular, fontSize: 16)),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: 500,
                      child: pw.Text(
                        courseName, 
                        style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.blue800),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: 600,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(issuedDate, style: pw.TextStyle(font: fontBold, fontSize: 14)),
                              pw.SizedBox(height: 5),
                              pw.Container(width: 100, height: 1, color: PdfColors.black),
                              pw.SizedBox(height: 5),
                              pw.Text('Ngày cấp', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                            ]
                          ),
                          pw.Spacer(),
                          pw.Container(
                            width: 55,
                            height: 55,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: PdfColors.amber, width: 3),
                            ),
                            child: pw.Center(
                              child: pw.Text('PASS', style: pw.TextStyle(font: fontBold, color: PdfColors.amber, fontSize: 14)),
                            ),
                          ),
                          pw.Spacer(),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('E-Learning', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.black)),
                              pw.SizedBox(height: 5),
                              pw.Container(width: 100, height: 1, color: PdfColors.black),
                              pw.SizedBox(height: 5),
                              pw.Text('Giám đốc đào tạo', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                            ]
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Gọi lệnh chia sẻ / lưu PDF của thiết bị
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'ChungChi_${userName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Chứng chỉ của bạn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'Lưu hoặc In PDF',
            onPressed: () => _exportPdf(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            // Không dùng RotatedBox nữa, mà dùng thiết kế Portrait để xem tự nhiên trên điện thoại
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37), width: 10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  )
                ]
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'GIẤY CHỨNG NHẬN',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HOÀN THÀNH KHÓA HỌC',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Trao tặng cho',
                      style: TextStyle(fontSize: 16, color: Colors.black87, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(width: 220, height: 1, color: Colors.grey.shade400),
                    const SizedBox(height: 24),
                    const Text(
                      'Đã hoàn thành xuất sắc khóa học',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      courseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                issuedDate,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Container(height: 1, color: Colors.black87),
                              const SizedBox(height: 4),
                              const Text('Ngày cấp', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'E-Learning',
                                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Container(height: 1, color: Colors.black87),
                              const SizedBox(height: 4),
                              const Text('Giám đốc đào tạo', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
