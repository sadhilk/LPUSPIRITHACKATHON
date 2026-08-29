import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart' show AppColors;
import '../services/device_service.dart';

class ScheduleScreen extends StatefulWidget {
  final DeviceService deviceService;
  const ScheduleScreen({super.key, required this.deviceService});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;

  final _deviceMeta = {
    'fan': {'icon': Icons.air_rounded, 'label': 'Fan'},
    'light': {'icon': Icons.lightbulb_rounded, 'label': 'Light'},
    'motor': {'icon': Icons.water_drop_rounded, 'label': 'Motor'},
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await widget.deviceService.getSchedules();
    setState(() { _schedules = data; _loading = false; });
  }

  Future<void> _toggle(String id) async {
    HapticFeedback.selectionClick();
    await widget.deviceService.toggleSchedule(id);
    _load();
  }

  Future<void> _delete(String id) async {
    HapticFeedback.mediumImpact();
    await widget.deviceService.deleteSchedule(id);
    _load();
  }

  void _showAddSheet() {
    String device = 'fan';
    String action = 'on';
    TimeOfDay time = TimeOfDay.now();
    final labelCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              left: 20, right: 20, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                const Text('NEW SCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.outlineVariant, letterSpacing: 1.5)),
                const SizedBox(height: 20),

                // Device selector
                const Text('Device', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  children: _deviceMeta.entries.map((e) {
                    final sel = device == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => device = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.solarMuted.withOpacity(0.15) : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? AppColors.solarMuted.withOpacity(0.6) : AppColors.outlineVariant.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(e.value['icon'] as IconData, color: sel ? AppColors.solarMuted : AppColors.onSurfaceVariant, size: 22),
                              const SizedBox(height: 4),
                              Text(e.value['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: sel ? AppColors.solarMuted : AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Action
                const Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: ['on', 'off'].map((a) {
                      final sel = action == a;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setLocal(() => action = a),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? (a == 'on' ? AppColors.greenActive.withOpacity(0.2) : AppColors.crimsonMuted.withOpacity(0.2)) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                a == 'on' ? 'TURN ON' : 'TURN OFF',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Montserrat',
                                  color: sel ? (a == 'on' ? AppColors.greenActive : AppColors.crimsonMuted) : AppColors.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Time
                const Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: time);
                    if (picked != null) setLocal(() => time = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          time.format(context),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.solarMuted, letterSpacing: -0.5),
                        ),
                        const Icon(Icons.access_time_rounded, color: AppColors.outlineVariant, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Label
                const Text('Label (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat', color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'e.g. Morning Fan, Night Lights...',
                    hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.outlineVariant),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 24),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final h = time.hour.toString().padLeft(2, '0');
                      final m = time.minute.toString().padLeft(2, '0');
                      final res = await widget.deviceService.scheduleDevice(
                        name: device,
                        action: action,
                        time: '$h:$m',
                        days: ['daily'],
                        label: labelCtrl.text.trim().isEmpty
                            ? '${_deviceMeta[device]!['label']} $action at $h:$m'
                            : labelCtrl.text.trim(),
                      );
                      if (res['success'] == true && ctx.mounted) {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHighest,
                      foregroundColor: AppColors.solarMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.solarMuted.withOpacity(0.4)),
                      ),
                    ),
                    child: const Text('SAVE SCHEDULE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Automation', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Montserrat', color: AppColors.onSurface, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('${_schedules.length} timer${_schedules.length != 1 ? 's' : ''} configured', style: const TextStyle(fontSize: 12, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () { HapticFeedback.mediumImpact(); _showAddSheet(); },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.solarMuted.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.solarMuted.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppColors.solarMuted, size: 20),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.solarMuted, strokeWidth: 2))
                  : _schedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                                ),
                                child: const Icon(Icons.timer_off_rounded, color: AppColors.outlineVariant, size: 30),
                              ),
                              const SizedBox(height: 16),
                              const Text('No Timers Set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Montserrat', color: AppColors.onSurface)),
                              const SizedBox(height: 6),
                              const Text('Tap + to create automation', style: TextStyle(fontSize: 13, fontFamily: 'Montserrat', color: AppColors.outlineVariant)),
                            ],
                          ).animate().fadeIn(duration: 400.ms),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _schedules.length,
                          itemBuilder: (context, i) {
                            final s = _schedules[i];
                            final id = s['_id'] as String? ?? '';
                            final name = s['device'] as String? ?? 'fan';
                            final active = s['active'] as bool? ?? false;
                            final label = s['label'] as String? ?? '';
                            final time = s['time'] as String? ?? '00:00';
                            final action = s['action'] as String? ?? 'on';
                            final meta = _deviceMeta[name] ?? {'icon': Icons.power_rounded, 'label': name};

                            return Dismissible(
                              key: Key(id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.crimsonMuted.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.crimsonMuted.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.delete_sweep_rounded, color: AppColors.crimsonMuted, size: 24),
                              ),
                              onDismissed: (_) => _delete(id),
                              child: _ScheduleCard(
                                icon: meta['icon'] as IconData,
                                time: time,
                                label: label.isNotEmpty ? label : '${meta['label']} turning $action',
                                action: action,
                                active: active,
                                onToggle: () => _toggle(id),
                              ).animate().fadeIn(duration: 350.ms, delay: (60 * i).ms),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final IconData icon;
  final String time;
  final String label;
  final String action;
  final bool active;
  final VoidCallback onToggle;

  const _ScheduleCard({required this.icon, required this.time, required this.label, required this.action, required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AppColors.solarMuted.withOpacity(0.3) : AppColors.outlineVariant.withOpacity(0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [AppColors.solarMuted.withOpacity(0.05), AppColors.surfaceContainerHigh.withOpacity(0.4)]
              : [AppColors.surfaceContainerHigh.withOpacity(0.4), AppColors.slateGradientStop.withOpacity(0.2)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: Icon(icon, color: active ? AppColors.solarMuted : AppColors.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: active ? AppColors.onSurface : AppColors.outlineVariant,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Montserrat', color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: active ? AppColors.solarMuted.withOpacity(0.8) : AppColors.surfaceContainerHighest,
                border: Border.all(color: active ? AppColors.solarMuted : AppColors.outlineVariant, width: 1),
              ),
              padding: const EdgeInsets.all(3),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: active ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
