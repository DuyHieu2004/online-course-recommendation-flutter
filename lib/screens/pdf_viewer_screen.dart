import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  int totalPages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_document.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Không thể tải tài liệu: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          if (isReady)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text('${currentPage + 1} / $totalPages')),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (localPath != null)
            PDFView(
              filePath: localPath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  totalPages = pages!;
                  isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  errorMessage = error.toString();
                });
              },
              onViewCreated: (PDFViewController pdfViewController) {
                // You can use the controller if needed
              },
              onLinkHandler: (String? uri) {
                // Handle links
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page!;
                });
              },
            ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          if (errorMessage.isNotEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            )),
        ],
      ),
    );
  }
}
