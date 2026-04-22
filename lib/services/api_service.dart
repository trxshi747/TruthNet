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

  static Future<Map<String, dynamic>> register(String email, String password, String name, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        body: jsonEncode({'email': email, 'password': password, 'name': name, 'role': role}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) { return {'success': false}; }
  }

  static Future<Map<String, dynamic>> createPost({
    required String userId,
    required String content,
    required bool isPublic,
    XFile? mediaFile,
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

      if (mediaFile != null) {
        if (kIsWeb) {
          final bytes = await mediaFile.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('media', bytes, filename: mediaFile.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path));
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

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/profile'));
      return jsonDecode(response.body);
    } catch (e) { return {}; }
  }

  static Future<bool> updateProfile(String userId, String name, String bio, XFile? avatar) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/users/$userId/profile'));
      request.fields['name'] = name;
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

  static Future<List<dynamic>> getSavedPosts(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/saved'));
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

  static Future<bool> addComment(String userId, String postId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/comment'),
        body: jsonEncode({'userId': userId, 'postId': postId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
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

  static Future<bool> replyToComment(String userId, String commentId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/reply'),
        body: jsonEncode({'userId': userId, 'content': content}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getReplies(String commentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/comments/$commentId/replies'));
      return jsonDecode(response.body);
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/search?query=$query'));
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

  static Future<bool> banUser(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/ban'),
      );
      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) { return false; }
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

  static Future<bool> addModerator(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/moderators'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateModerator(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/moderators/$id'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body)['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteModerator(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/moderators/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
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
    } catch (e) {
      return [];
    }
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
    } catch (e) {
      return false;
    }
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
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteRole(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/roles/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final res = jsonDecode(response.body);
      return res['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

}
