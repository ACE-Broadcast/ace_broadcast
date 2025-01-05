import 'package:flutter/material.dart';
import '../widgets/post_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:post_ace/services/auth_service.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Comment {
  final String id;
  final String username;
  final String content;
  final String timestamp;

  Comment({
    required this.id,
    required this.username, 
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      username: json['username'],
      content: json['comment'], 
      timestamp: json['timestamp'],
    );
  }
}

class CommentsScreen extends StatefulWidget {
  final Post post;

  const CommentsScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final AuthService _auth = AuthService();

  Future<void> _postComment() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final username = user.displayName ?? 'Anonymous';

    if (_commentController.text.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.2.106:5000/api/comment/post/${widget.post.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username, 
          'content': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          setState(() {
            fetchComments();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted successfully!')),
          );
          _commentController.clear();
          // TODO: Refresh comments list
        }
      } else {
        throw Exception('Failed to post comment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    }
  }

  Future<List<Comment>> fetchComments() async {
    final response = await http.get(
      Uri.parse('http://192.168.2.106:5000/api/comment/${widget.post.id}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> comments = responseData['comments'] ?? [];
      return comments.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          PostWidget(
            adminName: widget.post.adminName,
            timeAgo: widget.post.timeAgo,
            content: widget.post.content,
            imageUrls: widget.post.imageUrls,
            likesCount: widget.post.likesCount,
            commentsCount: widget.post.commentsCount,
            isSaved: widget.post.isSaved,
            onLike: widget.post.onLike,
          ),
          Expanded(
            child: FutureBuilder<List<Comment>>(
              future: fetchComments(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];
                
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(comment.username[0].toUpperCase()),
                      ),
                      title: Text(comment.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.content),
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Type your reply here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}