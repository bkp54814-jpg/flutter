import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MiniArenaApp());
}

class MiniArenaApp extends StatelessWidget {
  const MiniArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Arena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101A2A),
      ),
      home: const ArenaGamePage(),
    );
  }
}

class ArenaGamePage extends StatefulWidget {
  const ArenaGamePage({super.key});

  @override
  State<ArenaGamePage> createState() => _ArenaGamePageState();
}

class _ArenaGamePageState extends State<ArenaGamePage> {
  late final WebViewController _controller;
  bool _loaded = false;
  String? _loadError;
  double _progress = 0.12;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted || _loaded) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + 0.018).clamp(0.12, 0.92).toDouble();
      });
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101A2A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loadError = null);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            _progressTimer?.cancel();
            setState(() {
              _loaded = true;
              _progress = 1;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() => _loadError =
                'Game gagal dimuat (${error.errorCode}). Coba tutup lalu buka aplikasi lagi.');
          },
        ),
      )
      ..loadFlutterAsset('assets/game/mini_arena_full_rebuild.html');
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() {
      _loaded = false;
      _loadError = null;
      _progress = 0.12;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101A2A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          if (!_loaded || _loadError != null)
            ColoredBox(
              color: const Color(0xFF081426),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_esports_rounded,
                            size: 54, color: Color(0xFF7DD3FC)),
                        const SizedBox(height: 14),
                        const Text(
                          'MINI ARENA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loadError ?? 'Menyiapkan arena...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB8C7D9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_loadError == null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 7,
                              backgroundColor: const Color(0xFF26364B),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF38BDF8)),
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('COBA LAGI'),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'MODE LANDSCAPE • OFFLINE • MINI ARENA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.3,
                            color: Color(0xFF71839B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
