import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const String kAppTitle = 'Sinar Kencana Elektronik';
const String kAppUrl = 'https://ske.wuaze.com/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF161524),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SkeApp());
}

class SkeApp extends StatelessWidget {
  const SkeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5842EB),
          surface: const Color(0xFFF7F8FC),
        ),
        useMaterial3: true,
      ),
      home: const SkeWebViewPage(),
    );
  }
}

class SkeWebViewPage extends StatefulWidget {
  const SkeWebViewPage({super.key});

  @override
  State<SkeWebViewPage> createState() => _SkeWebViewPageState();
}

class _SkeWebViewPageState extends State<SkeWebViewPage> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF7F8FC))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = 0;
              _hasError = false;
            });
          },
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() {
              _loadingProgress = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(kAppUrl));

    _initAndroidFileSelector();
  }

  Future<void> _initAndroidFileSelector() async {
    if (Platform.isAndroid &&
        _controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      await androidController.setOnShowFileSelector(_handleAndroidFilePicker);
    }
  }

  Future<List<String>> _handleAndroidFilePicker(
    FileSelectorParams params,
  ) async {
    try {
      final picker = ImagePicker();
      if (params.mode == FileSelectorMode.openMultiple) {
        final images = await picker.pickMultiImage();
        return images.map((img) => File(img.path).uri.toString()).toList();
      }
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return [];
      return [File(image.path).uri.toString()];
    } catch (e) {
      debugPrint('Android file selector error: $e');
      return [];
    }
  }

  Future<void> _reloadPage() async {
    setState(() {
      _hasError = false;
      _loadingProgress = 0;
    });
    await _controller.loadRequest(Uri.parse(kAppUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        body: SafeArea(
          child: Stack(
            children: [
              if (_hasError)
                _buildErrorState()
              else
                WebViewWidget(controller: _controller),
              if (!_hasError && _loadingProgress < 100)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF5842EB),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/ske_logo.webp', width: 72, height: 72),
            const SizedBox(height: 16),
            const Text(
              'Koneksi Bermasalah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF161524),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Pastikan HP terhubung ke internet lalu coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _reloadPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8F542),
                foregroundColor: const Color(0xFF161524),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
