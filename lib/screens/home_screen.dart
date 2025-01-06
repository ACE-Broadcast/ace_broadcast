import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:post_ace/models/post.dart';
import 'package:post_ace/screens/profile_page.dart';
import '../widgets/post_widget.dart';
//import '../data/posts_data.dart';
import '../screens/comments_screen.dart';
import '../screens/notification_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/scroll_behavior.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:post_ace/widgets/bottom_navbar.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/keep_alive_wrapper.dart';

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

class Message {
  final String username;
  final String message;
  final DateTime timestamp;
  final String id;
  final List<String> imageUrls;
  int likesCount;
  int commentsCount;
  bool isLiked;
  List<String> userLikes;

  Message({
    required this.username,
    required this.message,
    required this.timestamp,
    required this.id,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.userLikes = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    debugPrint('Raw JSON: $json');

    List<String> extractImageUrls(dynamic imagesData) {
      if (imagesData is List) {
        return imagesData
            .map((image) => image['url'] as String? ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> extractUserLikes(dynamic likesData) {
      if (likesData is List) {
        return likesData.map((like) => like.toString()).toList();
      }
      return [];
    }

    return Message(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      message: json['message'] ?? '',
      imageUrls: extractImageUrls(json['images']),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      likesCount: json['likesCount'] ?? 0,
      userLikes: extractUserLikes(json['_id'] ?? []),
      isLiked: false, // Will be updated after fetching user likes
    );
  }

  String getFormattedTimestamp() {
    final formatter = DateFormat('MMM dd, yyyy hh:mm a');
    return formatter.format(timestamp);
  }
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  TextEditingController _messageController = TextEditingController();
  double _titleSize = 30;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  List<PlatformFile>? _selectedFiles;
  Set<String> userLikedPosts = {};

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController.addListener(_onScroll);

    _fetchMessages().then((_) async {
      await _fetchUserLikes();
      // Fetch initial like counts for all posts
      for (var message in messages) {
        final count = await _fetchLikesCount(message.id);
        if (mounted) {
          setState(() {
            message.likesCount = count;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
      _selectedIndex = index;
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.159:5000/api/post/getMsg'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<dynamic> messagesData = data['data'] ?? [];
        setState(() {
          messages =
              messagesData.map((json) => Message.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) {
        showToast('Failed to load messages: $e');
      }
    }
  }

  Future<void> _fetchUserLikes() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.0.159:5000/api/like/user-likes/${widget.userName}'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);

        // Check if email matches current user
        if (data['email'] == widget.userName) {
          // Extract liked post IDs
          final likedPosts = (data['likedPosts'] as List)
              .map((post) => post['_id'] as String)
              .toSet();

          setState(() {
            userLikedPosts = likedPosts;

            for (var message in messages) {
              message.isLiked = userLikedPosts.contains(message.id);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user likes: $e');
    }
  }

  Future<int> _fetchLikesCount(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.159:5000/api/like/posts/$postId/likes'),
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

  Future<int> _fetchCommentCount(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.159:5000/api/comment/$postId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching likes count: $e');
    }
    return 0;
  }

  Future<void> _postLike(String postId) async {
    try {
      final postIndex = messages.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return;

      // Store the previous state in case we need to revert
      final previousLikeState = messages[postIndex].isLiked;
      final previousCount = messages[postIndex].likesCount;

      // Optimistically update UI immediately
      setState(() {
        messages[postIndex].isLiked = !previousLikeState;
        messages[postIndex].likesCount += messages[postIndex].isLiked ? 1 : -1;
      });

      // Make API call in background
      final response = await http.post(
        Uri.parse('http://192.168.0.159:5000/api/like/postLike'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": widget.userName,
          "postId": postId,
        }),
      );

      // If the API call fails, revert to previous state
      if (response.statusCode != 200 && mounted) {
        setState(() {
          messages[postIndex].isLiked = previousLikeState;
          messages[postIndex].likesCount = previousCount;
        });
        showToast('Failed to update like. Please try again.'
        );
      }
    } catch (e) {
      debugPrint('Error in _postLike: $e');

      // Revert optimistic update on error
      if (mounted) {
        final postIndex = messages.indexWhere((post) => post.id == postId);
        if (postIndex != -1) {
          setState(() {
            messages[postIndex].isLiked = !messages[postIndex].isLiked;
            messages[postIndex].likesCount +=
                messages[postIndex].isLiked ? 1 : -1;
          });
        }

        showToast('Failed to update like: $e');
      }
    }
  }

  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  Future<void> postMessage() async {
    if (!mounted || _messageController.text.trim().isEmpty) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.159:5000/api/post/postMsg'),
      );

      request.fields['Username'] = widget.userName;
      request.fields['Message'] = _messageController.text;

      if (_selectedFiles != null && _selectedFiles!.isNotEmpty) {
        for (var file in _selectedFiles!) {
          if (file.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'images',
                file.path!,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && mounted) {
        _messageController.clear();
        setState(() {
          _selectedFiles = null;
        });
        if (mounted) {
          await _fetchMessages();
          showToast('Post created successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast('Error: $e');
      }
    }
  }  

    void showToast(String message) {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          textColor: Theme.of(context).colorScheme.onSurface,
          fontSize: 16.0);
    }
    
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(),
        children: [
          KeepAliveWrapper(
            child: Scaffold(
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
                  child: Text(
                    'Home',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                          boxShadow:
                              Theme.of(context).brightness == Brightness.light
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                        ),
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search posts...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.inversePrimary
                                  .withValues(alpha: 0.8),
                              fontSize: 16,
                            ),
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(Icons.search,
                                  color: theme.colorScheme.inversePrimary),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceDim,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.inversePrimary
                                      .withValues(alpha: .5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.inversePrimary
                                      .withValues(alpha: .5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: .5)),
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

                        _fetchCommentCount(post.id).then((count) {
                          if (mounted) {
                            setState(() {
                              post.commentsCount = count;
                            });
                          }
                        });

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentsScreen(
                                  post: Post(
                                      id: post.id,
                                      adminName: post.username,
                                      timeAgo: _formatTimestamp(
                                          post.timestamp.toString()),
                                      content: post.message,
                                      imageUrls: post.imageUrls.isEmpty
                                          ? []
                                          : post.imageUrls,
                                      likesCount: post.likesCount,
                                      commentsCount: post.commentsCount,
                                      isSaved:
                                          post.username == widget.userName),
                                ),
                              ),
                            );
                          },
                          child: PostWidget(
                            adminName: post.username,
                            timeAgo:
                                _formatTimestamp(post.timestamp.toString()),
                            content: post.message,
                            imageUrls:
                                post.imageUrls.isEmpty ? [] : post.imageUrls,
                            likesCount: post.likesCount,
                            likes: const [],
                            commentsCount: post.commentsCount,
                            isLiked: post.isLiked,
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
                            // isLiked: post.isLiked,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Notification Page
          KeepAliveWrapper(
            child: NotificationScreen(
              isAdmin: widget.isAdmin,
              onNavigationChanged: _onNavigationChanged,
              selectedIndex: _selectedIndex,
              pageController: _pageController,
            ),
          ),

          KeepAliveWrapper(
            child: ProfilePage(
              isAdmin: widget.isAdmin,
              onNavigationChanged: _onNavigationChanged,
              selectedIndex: _selectedIndex,
              pageController: _pageController,
            ),
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

  void _showCreatePostDialog(BuildContext context) {
    final theme = Theme.of(context);
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
              onPressed: pickFiles,
              icon: const Icon(Icons.image),
              label: Text((_selectedFiles?.length ?? 0) > 0
                  ? '${_selectedFiles!.length} files selected'
                  : 'Add Images'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: postMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.inversePrimary,
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
