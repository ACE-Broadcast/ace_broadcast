import 'package:flutter/material.dart';
import 'package:post_ace/screens/profile_page.dart';
import '../widgets/post_widget.dart';
import '../data/posts_data.dart';
import '../screens/comments_screen.dart';
import '../screens/notification_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/scroll_behavior.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:post_ace/widgets/bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  final String userName;
  final String profileUrl;

  const HomeScreen({
    super.key,
    required this.isAdmin,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  TextEditingController _messageController = TextEditingController();
  double _titleSize = 30;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _fetchMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    const maxSize = 40.0;
    const minSize = 24.0;

    setState(() {
      _titleSize = (maxSize - (offset / 30)).clamp(minSize, maxSize);
    });
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.2.106:5000/api/post/getMsg'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('API Response: $data');
        final List<dynamic> messagesData = data['data'] ?? [];
        debugPrint('Messages Data: $messagesData');
        setState(() {
          messages = messagesData
              .map((json) => Message.fromJson(json))
              .toList()
              .reversed
              .toList();
        });
      } else {
        debugPrint('Error Status Code: ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<int> _fetchLikesCount(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.2.106:5000/api/like/posts/$postId/likes'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['likesCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching likes count: $e');
    }
    return 0;
  }

  Future<void> _postLike(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.2.106:5000/api/like/postLike'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": widget.userName, 
          "postId": postId,
        }),
      );

      if (response.statusCode == 201) {
        // Refresh likes count after successful like
        final newCount = await _fetchLikesCount(postId);
        setState(() {
          final post = messages.firstWhere((post) => post.id == postId);
          post.likesCount = newCount;
          post.isLiked = true; 
        });
      }
    } catch (e) {
      debugPrint('Error posting like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          Scaffold(
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: _titleSize,
                  fontWeight: FontWeight.bold,
                ),
                child:
                   Text('Home', style: TextStyle(color: theme.colorScheme.inversePrimary)),
              ),
            ),
            body: Column(
              children: [
                ScrollToHideWidget(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search posts...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.inversePrimary.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.search, color: theme.colorScheme.inversePrimary),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceDim,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(color: theme.colorScheme.inversePrimary.withValues(alpha: .2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide:  BorderSide(color: theme.colorScheme.inversePrimary.withValues(alpha: .2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: .5)),
                          ),
                          isDense: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                        onChanged: (value) {
                          // TODO: Implement Firestore search query
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final post = messages[index];
                      
                      _fetchLikesCount(post.id).then((count) {
                        if (mounted) {
                          setState(() {
                            post.likesCount = count;
                          });
                        }
                      });

                      return InkWell(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => CommentsScreen(post: post),
                          //   ),
                          // );
                        },
                        child: PostWidget(
                          adminName: post.username,
                          timeAgo: post.getFormattedTimestamp(),
                          content: post.message,
                          imageUrls: const [],
                          likesCount: post.likesCount, 
                          likes: const [],
                          commentsCount: 21,
                          isSaved: post.username == widget.userName,
                          onLike: () async {
                            await _postLike(post.id);
                          },
                          // onComment: () {
                          //   Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) =>
                          //           CommentsScreen(post: post),
                          //     ),
                          //   );
                          // },
                          onShare: () {
                            // TODO: Implement share functionality
                          },
                          onSave: () {
                            // TODO: Implement Firebase save functionality
                          },
                          isLiked: post.isLiked,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notification Page
          NotificationScreen(
            isAdmin: widget.isAdmin,
            onNavigationChanged: _onNavigationChanged,
            selectedIndex: _selectedIndex,
            pageController: _pageController,
          ),

          ProfilePage(
            isAdmin: widget.isAdmin,
            onNavigationChanged: _onNavigationChanged,
            selectedIndex: _selectedIndex,
            pageController: _pageController,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 && widget.isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showCreatePostDialog(context);
              },
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTabChange: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        pageController: _pageController,
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    Future<void> postMessage() async {
      try {
        final response = await http.post(
          Uri.parse(
              'http://192.168.2.106:5000/api/post/postMsg'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "Username": widget.userName,
            'Message': _messageController.text,
          }),
        );

        if (response.statusCode == 201) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message posted successfully!')),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to post message');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create New Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'What would you like to announce?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker
              },
              icon: const Icon(Icons.image),
              label: const Text('Add Images'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: postMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Post'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String username;
  final String message;
  final DateTime timestamp;
  final String id;
  int likesCount;
  bool isLiked;

  Message({
    required this.username, 
    required this.message,
    required this.timestamp,
    required this.id,
    this.likesCount = 0,
    this.isLiked = false, 

  });

  factory Message.fromJson(Map<String, dynamic> json) {
    print('Raw JSON: $json');
    return Message(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? 'Just Now',
      ),
      likesCount: 0,
    );
  }

  String getFormattedTimestamp() {
    final formatter = DateFormat('MMM dd, yyyy hh:mm a');
    return formatter.format(timestamp);
  }
}

// class LikeButton extends StatefulWidget {
//   final bool isLiked;
//   final VoidCallback onTap;

//   const LikeButton({
//     Key? key,
//     required this.isLiked,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   _LikeButtonState createState() => _LikeButtonState();
// }

// class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _onTap() async {
//     _controller.forward().then((_) => _controller.reverse());
//     widget.onTap();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _scaleAnimation,
//       child: IconButton(
//         icon: Icon(
//           widget.isLiked ? Icons.favorite : Icons.favorite_border,
//           color: widget.isLiked ? Colors.red : Colors.grey,
//         ),
//         onPressed: _onTap,
//       ),
//     );
//   }
// }
