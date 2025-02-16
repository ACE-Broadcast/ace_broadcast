import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:post_ace/models/post.dart';
import 'package:post_ace/screens/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../widgets/connectivity_wrapper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'imageUrls': imageUrls,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isLiked': isLiked,
      'userLikes': userLikes,
    };
  }
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  TextEditingController _messageController = TextEditingController();
  double _titleSize = 40.0;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  List<PlatformFile>? _selectedFiles;
  Set<String> userLikedPosts = {};

  List<Message> messages = [];

  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _postsPerPage = 10;
  bool _hasMorePosts = true;
  bool _isRefreshing = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _mainScrollController.addListener(_handleScroll);
    _focusNode.addListener(() {
      setState(() {});
    });

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
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_mainScrollController.hasClients) return;

    final offset = _mainScrollController.offset;
    const maxSize = 40.0;
    const minSize = 24.0;
    const scrollThreshold = 100.0;

    setState(() {
      _titleSize = maxSize - ((offset / scrollThreshold) * (maxSize - minSize));
      _titleSize = _titleSize.clamp(minSize, maxSize);
    });

    if (_mainScrollController.position.pixels >=
        _mainScrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMorePosts) {
        _currentPage++;
        _fetchMessages();
      }
    }
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted || _isLoadingMore || !_hasMorePosts) return;

    setState(() {
      if (_currentPage == 1) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.0.159:5000/api/post/getMsg?page=$_currentPage&limit=$_postsPerPage'),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<dynamic> messagesData = data['data'] ?? [];
        final newMessages =
            messagesData.map((json) => Message.fromJson(json)).toList();

        setState(() {
          if (_currentPage == 1) {
            messages = newMessages;
            // Cache only on first page load and ensure we have data
            if (newMessages.isNotEmpty) {
              _cachePosts(newMessages).then((_) {
                debugPrint('Posts cached successfully');
              });
            }
          } else {
            messages.addAll(newMessages);
          }
          _hasMorePosts = newMessages.length >= _postsPerPage;
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      if (mounted) {
        showToast('Failed to load messages');
        showToastDebug('Failed to load messages: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
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
        showToast('Failed to update like. Please try again.');
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
        showToast('An Error Occurred!');
        showToastDebug('Failed to update like: $e');
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
          if (_selectedFiles != null) {
            _selectedFiles = [..._selectedFiles!, ...result.files];
          } else {
            _selectedFiles = result.files;
          }
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
        showToast('An Error Occurred!');
        showToastDebug('Error: $e');
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

  void showToastDebug(String message) {
    if (kDebugMode == true) {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  Future<void> _cachePosts(List<Message> posts) async {
    try {
      if (posts.isEmpty) {
        debugPrint('No posts to cache');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final postsJson = posts.map((post) => jsonEncode(post.toJson())).toList();
      await prefs.setStringList('cached_posts', postsJson);
      debugPrint('Successfully cached ${posts.length} posts');
    } catch (e) {
      debugPrint('Error caching posts: $e');
    }
  }

  Future<List<Message>> _loadCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getStringList('cached_posts') ?? [];
      return postsJson.map((postJson) {
        final Map<String, dynamic> decoded = jsonDecode(postJson);
        return Message.fromJson(decoded);
      }).toList();
    } catch (e) {
      debugPrint('Error loading cached posts: $e');
      return [];
    }
  }

  Future<bool> _checkForCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPosts = prefs.getStringList('cached_posts');
      debugPrint('Cached posts found: ${cachedPosts?.isNotEmpty}');
      return cachedPosts?.isNotEmpty ?? false;
    } catch (e) {
      debugPrint('Error checking cached posts: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return ConnectivityWrapper(
      checkForCachedData: _checkForCachedPosts,
      loadCachedData: () async {
        final cachedPosts = await _loadCachedPosts();
        if (mounted && cachedPosts.isNotEmpty) {
          setState(() {
            messages = cachedPosts;
            _isLoading = false;
          });
        }
      },
      onConnectionRestored: () async {
        await _fetchMessages();
        // ... rest of your connection restored logic
      },
      child: Scaffold(
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                  ),
                )
              : PageView(
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
                          surfaceTintColor: theme.colorScheme.surface,
                          backgroundColor: theme.colorScheme.surface,
                          elevation: 0,
                          title: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: _titleSize,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            child: const Text(
                              'Home',
                            ),
                          ),
                        ),
                        body: Column(
                          children: [
                            ScrollToHideWidget(
                              controller: _mainScrollController,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: Theme.of(context).brightness ==
                                            Brightness.light
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Icon(Icons.search,
                                            color: theme
                                                .colorScheme.inversePrimary),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surfaceDim,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        borderSide: BorderSide(
                                            color: theme
                                                .colorScheme.inversePrimary
                                                .withValues(alpha: .5)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        borderSide: BorderSide(
                                            color: theme
                                                .colorScheme.inversePrimary
                                                .withValues(alpha: .5)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        borderSide: BorderSide(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: .5)),
                                      ),
                                      isDense: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                    ),
                                    onChanged: (value) {
                                      if (_debounce?.isActive ?? false)
                                        _debounce!.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 500),
                                          () {
                                        // Implement search logic here
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              //Refresh Indicator
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  var connectivityResult =
                                      await Connectivity().checkConnectivity();
                                  if (connectivityResult
                                      .contains(ConnectivityResult.none)) {
                                    if (mounted) {
                                      showToast('No internet connection');
                                    }
                                    return;
                                  }
                                  if (_isRefreshing) return;
                                  try {
                                    setState(() => _isRefreshing = true);
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _currentPage = 1;
                                      _hasMorePosts = true;
                                    });
                                    await _fetchMessages();
                                  } catch (e) {
                                    if (mounted) {
                                      showToast(
                                          'Failed to refresh: Please try again');
                                    }
                                    rethrow;
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isRefreshing = false);
                                    }
                                  }
                                },
                                child: ListView.builder(
                                  physics: BouncingScrollPhysics(),
                                  controller: _mainScrollController,
                                  itemCount:
                                      messages.length + (_hasMorePosts ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == messages.length) {
                                      // Show loading indicator at the bottom
                                      return _hasMorePosts
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    }

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
                                            builder: (context) =>
                                                CommentsScreen(
                                              post: Post(
                                                  id: post.id,
                                                  adminName: post.username,
                                                  timeAgo: _formatTimestamp(post
                                                      .timestamp
                                                      .toString()),
                                                  content: post.message,
                                                  imageUrls:
                                                      post.imageUrls.isEmpty
                                                          ? []
                                                          : post.imageUrls,
                                                  likesCount: post.likesCount,
                                                  commentsCount:
                                                      post.commentsCount,
                                                  isSaved: post.username ==
                                                      widget.userName),
                                            ),
                                          ),
                                        );
                                      },
                                      child: PostWidget(
                                        adminName: post.username,
                                        timeAgo: _formatTimestamp(
                                            post.timestamp.toString()),
                                        content: post.message,
                                        imageUrls: post.imageUrls.isEmpty
                                            ? []
                                            : post.imageUrls,
                                        likesCount: post.likesCount,
                                        likes: const [],
                                        commentsCount: post.commentsCount,
                                        isLiked: post.isLiked,
                                        isSaved:
                                            post.username == widget.userName,
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
          floatingActionButton:
              !_isLoading && _selectedIndex == 0 && widget.isAdmin
                  ? FloatingActionButton(
                      onPressed: () {
                        _showCreatePostDialog(context);
                      },
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  : null,
          bottomNavigationBar: !_isLoading
              ? CustomBottomNav(
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
                )
              : null),
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
      useSafeArea: true,
      backgroundColor: theme.colorScheme.inversePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Create New Post',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: TextField(
                              focusNode: _focusNode,
                              maxLines: null,
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'What would you like to announce?',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_selectedFiles?.isNotEmpty ?? false) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Selected Images',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    await pickFiles();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.add_photo_alternate,
                                      size: 20),
                                  label: const Text('Add More'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListView.builder(
                                physics: BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedFiles?.length ?? 0,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: theme.colorScheme.outline),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text('Image ${index + 1}'),
                                        ),
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: 0,
                                        child: IconButton(
                                          icon: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: theme.colorScheme.onError,
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedFiles?.removeAt(index);
                                              if (_selectedFiles?.isEmpty ??
                                                  false) {
                                                _selectedFiles = null;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Fixed bottom buttons
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: MediaQuery.of(context).viewInsets.bottom == 0
                      ? Container(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 16,
                            top: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: .2),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await pickFiles();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.image, size: 24),
                                    label: Text(
                                      (_selectedFiles?.length ?? 0) > 0
                                          ? '${_selectedFiles!.length} files selected'
                                          : 'Add Images',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      postMessage();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                    ),
                                    child: const Text(
                                      'Post',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
