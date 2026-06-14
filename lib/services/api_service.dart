import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false}; }
  }

  static Future<Map<String, dynamic>> register(String email, String password, String firstName, String lastName, String username, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'role': role
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false, 'message': e.toString()}; }
  }

  static Future<Map<String, dynamic>?> getPost(String postId, String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$postId?userId=$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>> createPost({
    required String userId,
    required String content,
    required bool isPublic,
    List<XFile>? mediaFiles,
    bool isVideo = false,
    String? location,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));
      request.fields['userId'] = userId;
      request.fields['content'] = content;
      request.fields['isPublic'] = isPublic.toString();
      request.fields['isVideo'] = isVideo.toString();
      if (location != null) request.fields['location'] = location;

      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var file in mediaFiles) {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes('media', bytes, filename: file.name));
          } else {
            request.files.add(await http.MultipartFile.fromPath('media', file.path));
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) { return {'success': false}; }
  }

  static Future<List<dynamic>> getFeed(String? userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feed?userId=${userId ?? ""}'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> updatePost(String postId, String userId, String content) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$postId'),
        body: jsonEncode({'userId': userId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> deletePost(String postId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/archive'),
        body: jsonEncode({'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> deletePostPermanent(String postId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId/permanent'),
        body: jsonEncode({'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  // --- PROFILE ---

  static Future<Map<String, dynamic>> getProfile(String userId, String currentUserId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/profile?currentUserId=$currentUserId'));
      return jsonDecode(response.body);
    } catch (e) { return {}; }
  }

  static Future<Map<String, dynamic>> followUser(String userId, String targetId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/follow'),
        body: jsonEncode({'userId': userId, 'targetId': targetId}),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) { 
      return {'success': false, 'message': 'Network error'}; 
    }
  }

  static Future<bool> updateProfile(String userId, String firstName, String lastName, String bio, XFile? avatar) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/$userId/profile'));
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['bio'] = bio;

      if (avatar != null) {
        if (kIsWeb) {
          final bytes = await avatar.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: avatar.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getUserPosts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/posts'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getArchivePosts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/archive'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  // --- SETTINGS ---

  static Future<bool> updatePassword(String userId, String oldPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-password'),
        body: jsonEncode({'userId': userId, 'oldPassword': oldPassword, 'newPassword': newPassword}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> updateEmail(String userId, String newEmail) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-email'),
        body: jsonEncode({'userId': userId, 'newEmail': newEmail}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  // --- SOCIAL INTERACTIONS ---

  static Future<bool> likePost(String userId, String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/like'),
        body: jsonEncode({'userId': userId, 'postId': postId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> sharePost(String userId, String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/share'),
        body: jsonEncode({'userId': userId, 'postId': postId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> savePost(String userId, String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/save'),
        body: jsonEncode({'userId': userId, 'postId': postId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> addComment(String userId, String postId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/comment'),
        body: jsonEncode({'userId': userId, 'postId': postId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false}; }
  }

  static Future<List<dynamic>> getComments(String postId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$postId/comments'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> likeComment(String userId, String commentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/like'),
        body: jsonEncode({'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> replyToComment(String userId, String commentId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/reply'),
        body: jsonEncode({'userId': userId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false}; }
  }

  static Future<List<dynamic>> getReplies(String commentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/comments/$commentId/replies'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> updateComment(String commentId, String userId, String content) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/comments/$commentId'),
        body: jsonEncode({'userId': userId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> deleteComment(String commentId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        body: jsonEncode({'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> searchUsers(String query, [String excludeId = ""]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/search?query=$query&excludeId=$excludeId'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> searchPosts(String query, [String excludeId = ""]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/search?query=$query&excludeId=$excludeId'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  // --- MESSAGES ---

  static Future<bool> sendMessage(String senderId, String receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getChatHistory(String userId, String otherId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messages/history/$userId/$otherId'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getConversations(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/messages/conversations/$userId'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  // --- ADMIN USERS ---

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> deactivateUser(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/deactivate'),
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  // ---ADMIN MODERATORS ---

  static Future<List<dynamic>> getModerators() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/moderators'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<Map<String, dynamic>> addModerator(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/moderators'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> updateModerator(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/moderators/$id'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> deleteModerator(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/moderators/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_ERROR'};
    }
  }

  // --- ADMIN ROLES ---

  static Future<List<dynamic>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/roles'),
      );
      final data = jsonDecode(response.body);
      return data is List ? data : data['data'] ?? [];
    } catch (e) { return []; }
  }

  static Future<bool> addRole(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/roles'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      final res = jsonDecode(response.body);
      return res['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> updateRole(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/roles/$id'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      final res = jsonDecode(response.body);
      return res['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> deleteRole(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/roles/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_ERROR'};
    }
  }

  static Future<bool> registerAdmin(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/admin/register'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
      final body = jsonDecode(res.body);
      return body['success'] ?? false;
    } catch (e) { return false; }
  }

  // --- SANCTIONS ---

  static Future<bool> suspendUser({
    required String userId,
    required String reason,
    int? durationDays,
    String? endDate,
    required String adminId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/suspend'),
        body: jsonEncode({
          'reason': reason,
          'durationDays': durationDays,
          'endDate': endDate,
          'adminId': adminId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> banUser({
    required String userId,
    required String reason,
    required String adminId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/ban'),
        body: jsonEncode({
          'reason': reason,
          'adminId': adminId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> revokeSanction({
    required String sanctionId,
    required String adminId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/sanctions/$sanctionId/revoke'),
        body: jsonEncode({'adminId': adminId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<bool> activateUser({required String userId, required String adminId}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/activate'),
        body: jsonEncode({'adminId': adminId}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getActiveSanctions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/sanctions/active'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  // --- NOTIFICATIONS ---

  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications/$userId'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> markNotificationRead(String notifId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/notifications/$notifId/read'));
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  // --- REPORTS ---

  static Future<bool> reportItem({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        body: jsonEncode({
          'reporterId': reporterId,
          'targetId': targetId,
          'targetType': targetType,
          'reason': reason,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/reports'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<bool> resolveReport(String reportId, String action, String adminId, [String? customReason]) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/reports/$reportId/resolve'),
        body: jsonEncode({
          'action': action,
          'adminId': adminId,
          'customReason': customReason
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>> analyzeReportTargetFullResponse(String reportId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/reports/$reportId/analyze'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'CONNECTION_ERROR'};
    }
  }

  static Future<Map<String, dynamic>> verifyClaim(String text, {String? imageUrl, bool isVideo = false, String? postId, String? commentId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/verify'),
        body: jsonEncode({
          'text': text,
          'imageUrl': imageUrl,
          'isVideo': isVideo,
          'postId': postId,
          'commentId': commentId
        }),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'VERIFICATION_FAILED'};
    }
  }
}
