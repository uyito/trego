import '../shared/api_client.dart';

class SocialService {
  final ApiClient _apiClient;

  /// [apiClient] is injectable for tests; defaults to the shared singleton.
  SocialService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  // Friends Management
  Future<bool> sendFriendRequest(String friendId, {String? message}) async {
    try {
      final response = await _apiClient.post('/api/social/friends/request', data: {
        'friendId': friendId,
        'message': message,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Friend request failed: $e');
      return false;
    }
  }

  Future<bool> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final response = await _apiClient.put('/api/social/friends/respond', data: {
        'requestId': requestId,
        'accept': accept,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Friend response failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final response = await _apiClient.get('/api/social/friends');
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['friends']);
      }
    } catch (e) {
      print('Get friends failed: $e');
    }
    
    return [];
  }

  Future<List<Map<String, dynamic>>> getFriendRequests() async {
    try {
      final response = await _apiClient.get('/api/social/friends/requests');
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['requests']);
      }
    } catch (e) {
      print('Get friend requests failed: $e');
    }
    
    return [];
  }

  // Challenge Management
  Future<Map<String, dynamic>?> createChallenge({
    required String title,
    required String description,
    required String type,
    required int target,
    required int duration,
    bool isPublic = true,
    int? maxParticipants,
  }) async {
    try {
      final response = await _apiClient.post('/api/social/challenges', data: {
        'title': title,
        'description': description,
        'type': type,
        'target': target,
        'duration': duration,
        'isPublic': isPublic,
        'maxParticipants': maxParticipants,
      });
      
      if (response.data['success'] == true) {
        return response.data['challenge'];
      }
    } catch (e) {
      print('Challenge creation failed: $e');
    }
    
    return null;
  }

  Future<List<Map<String, dynamic>>> getChallenges({bool? isPublic}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isPublic != null) queryParams['isPublic'] = isPublic.toString();
      
      final response = await _apiClient.get('/api/social/challenges', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['challenges']);
      }
    } catch (e) {
      print('Get challenges failed: $e');
    }
    
    return [];
  }

  Future<bool> joinChallenge(String challengeId) async {
    try {
      final response = await _apiClient.post('/api/social/challenges/$challengeId/join');
      
      return response.data['success'] == true;
    } catch (e) {
      print('Join challenge failed: $e');
      return false;
    }
  }

  Future<bool> leaveChallenge(String challengeId) async {
    try {
      final response = await _apiClient.post('/api/social/challenges/$challengeId/leave');
      
      return response.data['success'] == true;
    } catch (e) {
      print('Leave challenge failed: $e');
      return false;
    }
  }

  // Posts Management
  Future<Map<String, dynamic>?> createPost({
    required String content,
    required String type,
    List<String>? attachments,
    String visibility = 'friends',
  }) async {
    try {
      final response = await _apiClient.post('/api/social/posts', data: {
        'content': content,
        'type': type,
        'attachments': attachments ?? [],
        'visibility': visibility,
      });
      
      if (response.data['success'] == true) {
        return response.data['post'];
      }
    } catch (e) {
      print('Post creation failed: $e');
    }
    
    return null;
  }

  Future<List<Map<String, dynamic>>> getFeed({int limit = 20, int? offset}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
      };
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final response = await _apiClient.get('/api/social/posts/feed', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['posts']);
      }
    } catch (e) {
      print('Get feed failed: $e');
    }
    
    return [];
  }

  Future<bool> likePost(String postId) async {
    try {
      final response = await _apiClient.post('/api/social/posts/$postId/like');
      
      return response.data['success'] == true;
    } catch (e) {
      print('Like post failed: $e');
      return false;
    }
  }

  Future<bool> commentOnPost(String postId, String content) async {
    try {
      final response = await _apiClient.post('/api/social/posts/$postId/comment', data: {
        'content': content,
      });

      return response.data['success'] == true;
    } catch (e) {
      print('Comment on post failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _apiClient.get('/api/social/posts/$postId/comments');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['comments']);
      }
    } catch (e) {
      print('Get comments failed: $e');
    }

    return [];
  }

  Future<bool> reportPost(String postId, String reason) async {
    try {
      final response = await _apiClient.post('/api/social/posts/$postId/report', data: {
        'reason': reason,
      });

      return response.data['success'] == true;
    } catch (e) {
      print('Report post failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updatePost(String postId, String content) async {
    try {
      final response = await _apiClient.patch('/api/social/posts/$postId', data: {
        'content': content,
      });

      if (response.data['success'] == true) {
        return response.data['post'];
      }
    } catch (e) {
      print('Update post failed: $e');
    }

    return null;
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _apiClient.delete('/api/social/posts/$postId');

      return response.data['success'] == true;
    } catch (e) {
      print('Delete post failed: $e');
      return false;
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications({bool markAsRead = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (markAsRead) queryParams['markAsRead'] = 'true';
      
      final response = await _apiClient.get('/api/social/notifications', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['notifications']);
      }
    } catch (e) {
      print('Get notifications failed: $e');
    }
    
    return [];
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _apiClient.put('/api/social/notifications/$notificationId/read');
      
      return response.data['success'] == true;
    } catch (e) {
      print('Mark notification as read failed: $e');
      return false;
    }
  }
}