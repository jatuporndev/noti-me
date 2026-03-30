import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:noti_me/core/theme/app_theme.dart';

/// Full-screen QR scanner. Pops with the scanned tag-ID string on success.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _scanned = false;
  bool _torchOn = false;

  // Scan-line animation
  late final AnimationController _lineAnim;
  late final Animation<double> _linePos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _linePos = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _ctrl.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _ctrl.stop();
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _lineAnim.dispose();
    await _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;
    _scanned = true;
    _lineAnim.stop();
    _ctrl.stop();
    Navigator.of(context).pop(raw.trim());
  }

  @override
  Widget build(BuildContext context) {
    const windowSize = 264.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,

      // ── App bar — matches app style ───────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR code',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        actions: [
          // Torch toggle — styled as a pill button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                _ctrl.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _torchOn
                      ? kNotiMePrimary.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _torchOn
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      size: 15,
                      color: _torchOn ? Colors.black87 : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _torchOn ? 'On' : 'Off',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _torchOn ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // ── Camera feed ────────────────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Dark vignette overlay with square cut-out ──────────────────────
          CustomPaint(
            painter: _OverlayPainter(windowSize: windowSize),
            child: SizedBox.expand(),
          ),

          // ── Scan window: corner brackets + animated scan line ──────────────
          Center(
            child: SizedBox(
              width: windowSize,
              height: windowSize,
              child: Stack(
                children: [
                  // Corner brackets
                  CustomPaint(
                    size: Size(windowSize, windowSize),
                    painter: _CornerPainter(),
                  ),

                  // Animated scan line
                  AnimatedBuilder(
                    animation: _linePos,
                    builder: (_, __) {
                      return Positioned(
                        left: 12,
                        right: 12,
                        top: 12 +
                            (_linePos.value * (windowSize - 24 - 2)),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kNotiMePrimary.withValues(alpha: 0.0),
                                kNotiMePrimary.withValues(alpha: 0.90),
                                kNotiMePrimary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom hint card ───────────────────────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 52,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Catcos mascot — tiny inline, tinted for dark bg
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/catcos.jpg',
                        height: 28,
                        fit: BoxFit.contain,
                        color: kNotiMePrimary,
                        colorBlendMode: BlendMode.modulate,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Point at a friend\'s QR code',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Profile  →  My QR Code',
                    style: TextStyle(
                      fontFamily: kMonoFontFamily,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: kNotiMePrimary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark overlay with transparent cut-out ─────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({required this.windowSize});
  final double windowSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 14.0;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: windowSize, height: windowSize),
        const Radius.circular(r),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => false;
}

// ── Branded corner brackets ────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kNotiMePrimary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 26.0;
    const r = 14.0;

    // Top-left
    canvas.drawPath(
        Path()
          ..moveTo(0, r + arm)
          ..lineTo(0, r)
          ..arcToPoint(const Offset(r, 0),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(r + arm, 0),
        paint);

    // Top-right
    canvas.drawPath(
        Path()
          ..moveTo(size.width - r - arm, 0)
          ..lineTo(size.width - r, 0)
          ..arcToPoint(Offset(size.width, r),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(size.width, r + arm),
        paint);

    // Bottom-right
    canvas.drawPath(
        Path()
          ..moveTo(size.width, size.height - r - arm)
          ..lineTo(size.width, size.height - r)
          ..arcToPoint(Offset(size.width - r, size.height),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(size.width - r - arm, size.height),
        paint);

    // Bottom-left
    canvas.drawPath(
        Path()
          ..moveTo(r + arm, size.height)
          ..lineTo(r, size.height)
          ..arcToPoint(Offset(0, size.height - r),
              radius: const Radius.circular(r), clockwise: true)
          ..lineTo(0, size.height - r - arm),
        paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
