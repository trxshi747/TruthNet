// lib/services/mock_service.dart

class MockService {
  // Générer des statistiques aléatoires mais réalistes
  static Map<String, dynamic> getDashboardStats() {
    return {
      'totalUsers': _randomInt(850, 2500),
      'activeUsers': _randomInt(400, 1800),
      'inactiveUsers': _randomInt(50, 300),
      'totalPosts': _randomInt(3000, 15000),
      'totalComments': _randomInt(8000, 35000),
      'pendingReports': _randomInt(3, 45),
      'resolvedReports': _randomInt(50, 300),
      'totalModerators': _randomInt(2, 12),
      'totalAdmins': _randomInt(1, 5),
      'dailyActiveUsers': _randomInt(200, 900),
      'weeklyGrowth': '${_randomDouble(2.5, 15.0).toStringAsFixed(1)}%',
      'engagementRate': '${_randomDouble(45, 85).toStringAsFixed(0)}%',
    };
  }

  static List<Map<String, dynamic>> getRecentActivities({int limit = 10}) {
    final List<String> users = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Williams', 'David Brown', 'Emma Davis'];
    final List<String> actions = [
      'published a new post',
      'commented on a post',
      'reported a suspicious content',
      'joined the platform',
      'liked a post',
      'shared a post',
    ];
    final List<String> types = ['post', 'comment', 'report', 'join', 'like', 'share'];

    final List<Map<String, dynamic>> activities = [];

    for (int i = 0; i < limit; i++) {
      activities.add({
        'user': users[i % users.length],
        'action': actions[i % actions.length],
        'time': _randomTimeAgo(),
        'type': types[i % types.length],
      });
    }

    return activities;
  }

  static int _randomInt(int min, int max) {
    return min + DateTime.now().millisecondsSinceEpoch % (max - min + 1);
  }

  static double _randomDouble(double min, double max) {
    return min + (DateTime.now().millisecondsSinceEpoch % 1000) / 1000 * (max - min);
  }

  static String _randomTimeAgo() {
    final List<String> times = [
      'just now',
      '2 minutes ago',
      '15 minutes ago',
      '1 hour ago',
      '3 hours ago',
      '5 hours ago',
      'yesterday',
      '2 days ago',
    ];
    return times[DateTime.now().millisecond % times.length];
  }
}