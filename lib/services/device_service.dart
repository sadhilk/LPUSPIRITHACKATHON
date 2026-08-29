import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

const String backendUrl = 'http://192.168.6.131:5000'; // Update with your IP

class DeviceState {
  final String name;
  bool status;
  DeviceState({required this.name, required this.status});
}

class DeviceService {
  IO.Socket? _socket;
  final Map<String, bool> devices = {
    'fan': false,
    'light': false,
    'motor': false,
  };
  bool connected = false;
  final List<Function()> _listeners = [];

  void addListener(Function() listener) => _listeners.add(listener);
  void removeListener(Function() listener) => _listeners.remove(listener);
  void _notify() { for (var l in _listeners) l(); }

  void connect() {
    _socket = IO.io(backendUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      connected = true;
      _notify();
    });

    _socket!.onDisconnect((_) {
      connected = false;
      _notify();
    });

    _socket!.on('deviceStates', (data) {
      if (data is List) {
        for (var d in data) {
          if (devices.containsKey(d['name'])) {
            devices[d['name']] = d['status'] == true;
          }
        }
        _notify();
      }
    });

    _socket!.on('deviceUpdate', (data) {
      if (data is Map && devices.containsKey(data['device'])) {
        devices[data['device']] = data['status'] == true;
        _notify();
      }
    });

    _fetchDevices();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/api/devices'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          for (var d in data['devices']) {
            if (devices.containsKey(d['name'])) {
              devices[d['name']] = d['status'] == true;
            }
          }
          _notify();
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> sendCommand(String text) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/api/command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': text}),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendAudio(String base64Audio, {String mimeType = 'audio/m4a'}) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/api/command/audio'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audioBase64': base64Audio,
          'mimeType': mimeType,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> toggleDevice(String name) async {
    final newStatus = !(devices[name] ?? false);
    devices[name] = newStatus;
    _notify();
    try {
      await http.put(
        Uri.parse('$backendUrl/api/devices/$name'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus, 'source': 'manual'}),
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/api/analytics'));
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/api/schedule'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return List<Map<String, dynamic>>.from(data['schedules'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> scheduleDevice({
    required String name,
    required String action,
    required String time,
    required List<String> days,
    required String label,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/api/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'device': name,
          'action': action,
          'time': time,
          'days': days,
          'label': label,
        }),
      );
      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      final res = await http.delete(Uri.parse('$backendUrl/api/schedule/$id'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> toggleSchedule(String id) async {
    try {
      final res = await http.patch(
        Uri.parse('$backendUrl/api/schedule/$id/toggle'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (_) {}
    return null;
  }
}
