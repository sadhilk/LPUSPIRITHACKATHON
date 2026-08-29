import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../main.dart' show AppColors;
import '../services/device_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final DeviceService deviceService;
  const AnalyticsScreen({super.key, required this.deviceService});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  final List<_ChatMsg> _messages = [
    _ChatMsg(role: 'assistant', text: "👋 Hi! I'm your AI energy advisor.\nAsk me anything about your usage, or tap a quick question!"),
  ];
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _chatLoading = false;

  final _quickQs = [
    '💡 How to save electricity?',
    '🌀 Is my fan usage normal?',
    '💧 Best time to run motor?',
    '📊 Which device costs most?',
  ];

  final _deviceMeta = {
    'fan':   {'icon': Icons.air_rounded,        'label': 'Ceiling Fan'},
    'light': {'icon': Icons.lightbulb_rounded,  'label': 'Smart Light'},
    'motor': {'icon': Icons.water_drop_rounded, 'label': 'Water Pump'},
  };

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _chatCtrl.dispose(); _chatScroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await widget.deviceService.getAnalytics();
    setState(() { _data = data; _loading = false; });
  }

  String _formatTime(String iso) {
    try { return DateFormat('h:mm a').format(DateTime.parse(iso).toLocal()); }
    catch (_) { return ''; }
  }

  Future<void> _sendChat(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;
    _chatCtrl.clear();
    setState(() { _messages.add(_ChatMsg(role: 'user', text: q)); _chatLoading = true; });
    _scrollDown();
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/api/analytics/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': q}),
      ).timeout(const Duration(seconds: 30));
      final json = jsonDecode(res.body);
      setState(() {
        _messages.add(_ChatMsg(
          role: 'assistant',
          text: json['success'] == true ? (json['answer'] ?? 'No answer received.') : '⚠️ ${json['error'] ?? 'AI unavailable.'}',
        ));
        _chatLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg(role: 'assistant', text: '⚠️ Could not reach AI. Is Ollama running?'));
        _chatLoading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayCost  = (_data?['todayTotalCost'] ?? 0.0) as num;
    final totalCost  = (_data?['totalCostINR']   ?? 0.0) as num;
    final rate       = (_data?['costPerKwh']      ?? 7.5) as num;
    final deviceStats    = (_data?['deviceStats']    ?? []) as List;
    final recentCommands = (_data?['recentCommands'] ?? []) as List;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.solarMuted,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Analytics', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.onSurface, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('₹${rate.toStringAsFixed(1)}/kWh  •  7-day view', style: const TextStyle(fontSize: 12, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                    ]),
                    GestureDetector(
                      onTap: _load,
                      child: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5))),
                        child: const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant, size: 18)),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                if (_loading) ...[
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 80), child: CircularProgressIndicator(color: AppColors.solarMuted, strokeWidth: 2))),
                ] else ...[
                  Row(children: [
                    Expanded(child: _CostCard(value: '₹${todayCost.toStringAsFixed(1)}', label: "TODAY'S COST", valueColor: AppColors.solarMuted)),
                    const SizedBox(width: 12),
                    Expanded(child: _CostCard(value: '₹${totalCost.toStringAsFixed(1)}', label: 'TOTAL USAGE', valueColor: AppColors.greenActive)),
                  ]).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                  const SizedBox(height: 28),
                  const Text('ENERGY BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 14),
                  ...deviceStats.mapIndexed((index, stat) {
                    final name = (stat['name'] ?? '') as String;
                    final meta = _deviceMeta[name] ?? {'icon': Icons.power_rounded, 'label': name};
                    final hours = (stat['totalOnHours'] ?? 0.0) as num;
                    final cost  = (stat['totalCostINR'] ?? 0.0) as num;
                    final kwh   = (stat['totalKwh']     ?? 0.0) as num;
                    final pct   = totalCost > 0 ? (cost / totalCost).clamp(0.0, 1.0).toDouble() : 0.0;
                    return _DeviceRow(icon: meta['icon'] as IconData, label: meta['label'] as String, hours: hours.toStringAsFixed(1), cost: '₹${cost.toStringAsFixed(1)}', kwh: '${kwh.toStringAsFixed(2)} kWh', pct: pct)
                        .animate().fadeIn(duration: 350.ms, delay: (100 * index).ms);
                  }),
                  const SizedBox(height: 28),
                  const Text('RECENT COMMANDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 14),
                  if (recentCommands.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('No recent commands', style: TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.outlineVariant))))
                  else
                    ...recentCommands.mapIndexed((i, cmd) {
                      final meta = _deviceMeta[cmd['device']] ?? {'icon': Icons.power_rounded, 'label': cmd['device'] ?? ''};
                      return _LogItem(icon: meta['icon'] as IconData, command: cmd['command'] ?? '', device: meta['label'] as String, action: (cmd['action'] ?? '').toUpperCase(), time: _formatTime(cmd['time'] ?? ''), isOn: (cmd['action'] ?? '') == 'on')
                          .animate().fadeIn(duration: 300.ms, delay: (60 * i).ms);
                    }),
                  const SizedBox(height: 28),
                  const Text('AI ENERGY ADVISOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 14),
                  _buildChatBox(),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9f7aea).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), gradient: const LinearGradient(colors: [Color(0xFF9f7aea), Color(0xFF63b3ed)])),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 17)))),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Energy Advisor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.onSurface)),
              Text('Powered by Ollama', style: TextStyle(fontSize: 10, fontFamily: 'Montserrat', color: Color(0xFF9f7aea))),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(
            height: 260,
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2))),
            child: ListView.builder(
              controller: _chatScroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_chatLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_chatLoading && i == _messages.length) return const _TypingBubble();
                return _BubbleRow(msg: _messages[i]);
              },
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _quickQs.map((q) => GestureDetector(
              onTap: _chatLoading ? null : () => _sendChat(q),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35))),
                child: Text(q, style: const TextStyle(fontSize: 11, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant))),
            )).toList()),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35))),
              child: TextField(
                controller: _chatCtrl,
                enabled: !_chatLoading,
                style: const TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.onSurface),
                decoration: const InputDecoration(hintText: 'Ask about your energy usage…', hintStyle: TextStyle(fontSize: 12, color: AppColors.outlineVariant, fontFamily: 'Montserrat'), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: InputBorder.none),
                onSubmitted: _chatLoading ? null : _sendChat,
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _chatLoading ? null : () => _sendChat(_chatCtrl.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _chatLoading ? null : const LinearGradient(colors: [Color(0xFF9f7aea), Color(0xFF63b3ed)]), color: _chatLoading ? AppColors.outlineVariant.withOpacity(0.3) : null),
                child: _chatLoading ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onSurfaceVariant))) : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _ChatMsg { final String role, text; const _ChatMsg({required this.role, required this.text}); }

class _BubbleRow extends StatelessWidget {
  final _ChatMsg msg;
  const _BubbleRow({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), gradient: const LinearGradient(colors: [Color(0xFF9f7aea), Color(0xFF63b3ed)])), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 13)))),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF9f7aea).withOpacity(0.18) : AppColors.surfaceContainerHigh.withOpacity(0.8),
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 4), bottomRight: Radius.circular(isUser ? 4 : 16)),
              border: Border.all(color: isUser ? const Color(0xFF9f7aea).withOpacity(0.3) : AppColors.outlineVariant.withOpacity(0.2)),
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.onSurface, height: 1.55)),
          )),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}
class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), gradient: const LinearGradient(colors: [Color(0xFF9f7aea), Color(0xFF63b3ed)])), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 13)))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.surfaceContainerHigh.withOpacity(0.8), borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16)), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final phase = ((_ctrl.value - i * 0.22) % 1.0).abs();
              final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
              return Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 7, height: 7, transform: Matrix4.translationValues(0, -t * 6, 0), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF9f7aea).withOpacity(0.4 + t * 0.6)));
            },
          ))),
        ),
      ]),
    );
  }
}

class _CostCard extends StatelessWidget {
  final String value, label; final Color valueColor;
  const _CostCard({required this.value, required this.label, required this.valueColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surfaceContainerHigh.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: valueColor.withOpacity(0.2)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [valueColor.withOpacity(0.06), AppColors.surfaceContainerHigh.withOpacity(0.4)])),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: valueColor, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
    ]),
  );
}

class _DeviceRow extends StatelessWidget {
  final IconData icon; final String label, hours, cost, kwh; final double pct;
  const _DeviceRow({required this.icon, required this.label, required this.hours, required this.cost, required this.kwh, required this.pct});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceContainerHigh.withOpacity(0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3))),
    child: Column(children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4))), child: Icon(icon, color: AppColors.onSurfaceVariant, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurface)),
          Text('$hours hrs  •  $kwh', style: const TextStyle(fontSize: 11, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
        ])),
        Text(cost, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.solarMuted)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: Stack(children: [
        Container(height: 4, color: AppColors.surfaceContainerLowest),
        FractionallySizedBox(widthFactor: pct, child: Container(height: 4, decoration: BoxDecoration(color: AppColors.solarMuted, borderRadius: BorderRadius.circular(4)))),
      ])),
    ]),
  );
}

class _LogItem extends StatelessWidget {
  final IconData icon; final String command, device, action, time; final bool isOn;
  const _LogItem({required this.icon, required this.command, required this.device, required this.action, required this.time, required this.isOn});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25))),
    child: Row(children: [
      Icon(icon, color: AppColors.onSurfaceVariant, size: 18), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(command, style: const TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.onSurface, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$device • $action', style: const TextStyle(fontSize: 11, fontFamily: 'Montserrat', color: AppColors.outlineVariant)),
      ])),
      Text(time, style: const TextStyle(fontSize: 11, fontFamily: 'Montserrat', color: AppColors.outlineVariant)),
    ]),
  );
}

extension IndexedIterable<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E e) f) { var i = 0; return map((e) => f(i++, e)).toList(); }
}
