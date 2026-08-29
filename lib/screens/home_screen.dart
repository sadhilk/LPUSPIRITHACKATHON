import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart' show AppColors;
import '../services/device_service.dart';

class HomeScreen extends StatefulWidget {
  final DeviceService deviceService;
  const HomeScreen({super.key, required this.deviceService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _textController = TextEditingController();

  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusLabel = '';
  String _transcription = '';
  String _aiResponse = '';

  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnim;

  final deviceConfig = {
    'light': {'icon': Icons.lightbulb_rounded, 'label': 'Smart Light Bulb', 'sub': 'Living Room • Live Demo'},
  };

  @override
  void initState() {
    super.initState();
    widget.deviceService.addListener(_onDeviceUpdate);
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _glowAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    widget.deviceService.removeListener(_onDeviceUpdate);
    _glowController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    if (_isProcessing) return;
    HapticFeedback.mediumImpact();
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/cmd_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, bitRate: 64000),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _statusLabel = 'Listening...';
          _transcription = '';
          _aiResponse = '';
        });
        _pulseController.repeat(reverse: true);
      } else {
        await Permission.microphone.request();
      }
    } catch (e) {
      debugPrint('Recording error: $e');
    }
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    final path = await _audioRecorder.stop();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusLabel = 'Processing with AI...';
    });

    try {
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final b64 = base64Encode(bytes);
          final result = await widget.deviceService.sendAudio(b64, mimeType: 'audio/m4a');
          if (mounted) {
            setState(() {
              _isProcessing = false;
              if (result['success'] == true) {
                final parsed = result['parsed'] ?? {};
                _transcription = parsed['transcription'] ?? '';
                _aiResponse = parsed['response'] ?? 'Done!';
                _statusLabel = '';
              } else {
                _aiResponse = result['error'] ?? 'Error processing audio.';
                _statusLabel = '';
              }
            });
          }
          await file.delete();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _statusLabel = ''; });
    }
  }

  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;
    final cmd = text.trim();
    _textController.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
      _transcription = '"$cmd"';
      _aiResponse = '';
      _statusLabel = 'Thinking...';
    });
    final result = await widget.deviceService.sendCommand(cmd);
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusLabel = '';
        if (result['success'] == true) {
          final parsed = result['parsed'] ?? {};
          _aiResponse = parsed['response'] ?? 'Done!';
        } else {
          _aiResponse = result['error'] ?? 'Error.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = widget.deviceService;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Gemini Glow (bottom) ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Opacity(
                opacity: _isRecording ? 1.0 : _glowAnim.value * 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 1.2),
                      radius: 1.0,
                      colors: _isRecording
                          ? [
                              const Color(0xFFDC2626).withOpacity(0.35),
                              const Color(0xFFEA580C).withOpacity(0.2),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF38BDF8).withOpacity(0.3),
                              const Color(0xFFA855F7).withOpacity(0.25),
                              const Color(0xFFFB923C).withOpacity(0.2),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Smart Light AI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.outlineVariant, width: 1.5),
                          color: AppColors.surfaceContainerHigh,
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.onSurfaceVariant, size: 20),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),

                        // ── Live AI Status Banner (only shown during voice/text actions) ─────────────────────
                        if (_isRecording || _isProcessing || _statusLabel.isNotEmpty && _statusLabel != 'What can I help with?') ...[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isRecording ? 'Listening...' : (_isProcessing ? 'Processing...' : _statusLabel),
                              key: ValueKey(_isRecording ? 'l' : (_isProcessing ? 'p' : _statusLabel)),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montserrat',
                                color: AppColors.onSurface,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 12),
                        ] else ...[
                          const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 28),

                        // ── Device Cards ─────────────────────────────────────
                        ...deviceConfig.entries.mapIndexed((index, entry) {
                          final name = entry.key;
                          final cfg = entry.value;
                          final isOn = ds.devices[name] ?? false;
                          return _DeviceCard(
                            icon: cfg['icon'] as IconData,
                            label: cfg['label'] as String,
                            sub: cfg['sub'] as String,
                            isOn: isOn,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ds.toggleDevice(name);
                            },
                          ).animate().fadeIn(duration: 350.ms, delay: (80 * index).ms).slideY(begin: 0.1);
                        }).toList(),

                        const SizedBox(height: 16),

                        // ── AI Response Block ─────────────────────────────────
                        if (_transcription.isNotEmpty || _aiResponse.isNotEmpty)
                          _ResponseCard(transcription: _transcription, response: _aiResponse)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        // ── Text Input ───────────────────────────────────────
                        _TextInputBar(
                          controller: _textController,
                          enabled: !_isProcessing && !_isRecording,
                          onSend: _sendText,
                        ).animate().fadeIn(duration: 350.ms, delay: 300.ms),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // ── Gemini label + Mic button ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      // Connection status
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ds.connected ? AppColors.greenActive : AppColors.crimsonMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ds.connected ? 'Connected to Local AI' : 'Offline',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gemini label
                      const Text(
                        'AI ENGINE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Mic button
                      GestureDetector(
                        onTapDown: (_) => _startRecording(),
                        onTapUp: (_) => _stopAndSend(),
                        onTapCancel: () => _stopAndSend(),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = _isRecording
                                ? 1.0 + (_pulseController.value * 0.12)
                                : 1.0;
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? AppColors.crimsonMuted
                                  : AppColors.surfaceContainerHigh,
                              border: Border.all(
                                color: _isRecording
                                    ? const Color(0xFFDC2626).withOpacity(0.5)
                                    : AppColors.outlineVariant,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (_isRecording)
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(AppColors.solarMuted),
                                      ),
                                    )
                                  : Icon(
                                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                      color: _isRecording ? Colors.white : AppColors.primary,
                                      size: 30,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isRecording
                            ? 'Release to send'
                            : _isProcessing
                                ? 'Processing...'
                                : 'Hold to speak',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Device Card
// ──────────────────────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool isOn;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOn
                ? AppColors.solarMuted.withOpacity(0.4)
                : AppColors.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOn
                ? [
                    AppColors.solarMuted.withOpacity(0.08),
                    AppColors.slateGradientStop.withOpacity(0.6),
                  ]
                : [
                    AppColors.surfaceContainerHigh.withOpacity(0.6),
                    AppColors.slateGradientStop.withOpacity(0.3),
                  ],
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
              ),
              child: Icon(icon, color: isOn ? AppColors.solarMuted : AppColors.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOn ? 'On ($sub)' : sub,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      color: isOn ? AppColors.solarMuted.withOpacity(0.9) : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: isOn ? AppColors.greenActive.withOpacity(0.8) : AppColors.surfaceContainerHighest,
                border: Border.all(
                  color: isOn ? AppColors.greenActive : AppColors.outlineVariant,
                  width: 1,
                ),
                boxShadow: isOn
                    ? [BoxShadow(color: AppColors.greenActive.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                    : [],
              ),
              padding: const EdgeInsets.all(3),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AI Response card
// ──────────────────────────────────────────────────────────────────────────────
class _ResponseCard extends StatelessWidget {
  final String transcription;
  final String response;
  const _ResponseCard({required this.transcription, required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.solarMuted.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.solarMuted.withOpacity(0.06),
            AppColors.surfaceContainerLow,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transcription.isNotEmpty) ...[
            const Text('YOU SAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(transcription, style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: AppColors.onSurface, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
          ],
          if (response.isNotEmpty) ...[
            const Text('AI ENGINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.solarMuted, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(response, style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: AppColors.onSurface, fontWeight: FontWeight.w400)),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Text input bar
// ──────────────────────────────────────────────────────────────────────────────
class _TextInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;
  const _TextInputBar({required this.controller, required this.enabled, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onSubmitted: onSend,
              style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Or type a command...',
                hintStyle: TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: AppColors.outlineVariant),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: enabled ? AppColors.surfaceContainerHighest : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.arrow_upward_rounded,
                  color: enabled ? AppColors.primary : AppColors.outlineVariant, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to get index in map iteration
extension IndexedIterable<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E e) f) {
    var i = 0;
    return map((e) => f(i++, e)).toList();
  }
}
