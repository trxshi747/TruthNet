import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:model2/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  IO.Socket? _socket;
  List<dynamic> _notifications = [];
  bool _isConnected = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;
  bool get isConnected => _isConnected;

  void initSocket(String userId) {
    if (_socket != null) return;

    // Connect to WebSocket server
    String socketUrl = ApiService.baseUrl.replaceFirst('/api', '');
    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
      _socket!.emit('register', userId);
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('new_notification', (data) {
      print('New notification received: $data');
      _notifications.insert(0, data);
      notifyListeners();
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _notifications = [];
    notifyListeners();
  }

  Future<void> fetchNotifications(String userId) async {
    try {
      final response = await ApiService.getNotifications(userId);
      _notifications = response;
      notifyListeners();
    } catch (e) {
      print('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAsRead(String notifId) async {
    try {
      final success = await ApiService.markNotificationRead(notifId);
      if (success) {
        final index = _notifications.indexWhere((n) => n['id'] == notifId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      if (n['isRead'] == false) {
        await markAsRead(n['id']);
      }
    }
  }
}