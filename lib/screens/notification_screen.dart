import 'package:flutter/material.dart';
import '../widgets/notification_item.dart';
//import 'comments_screen.dart';

class NotificationScreen extends StatefulWidget {
  final bool isAdmin;
  final Function(int) onNavigationChanged;
  final int selectedIndex;
  final PageController pageController;

  const NotificationScreen({
    super.key,
    required this.isAdmin,
    required this.onNavigationChanged,
    required this.selectedIndex,
    required this.pageController,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final double titleSize = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: theme.colorScheme.surface,
        backgroundColor: theme.colorScheme.surface,
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
          child: Text('Notifications',
              style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ),
      // TODO: Implement StreamBuilder for real-time notifications
      // StreamBuilder<QuerySnapshot>(
      //   stream: widget.isAdmin
      //     ? FirebaseFirestore.instance
      //         .collection('notifications')
      //         .where('adminId', isEqualTo: currentUserId)
      //         .orderBy('timestamp', descending: true)
      //         .snapshots()
      //     : FirebaseFirestore.instance
      //         .collection('notifications')
      //         .where('type', isEqualTo: 'new_post')
      //         .orderBy('timestamp', descending: true)
      //         .snapshots(),
      body: ListView(
        children: [
          // Temporary static notifications for UI testing
          if (widget.isAdmin) ...[
            NotificationItem(
              profileUrl: 'student1.jpg',
              name: 'John Doe',
              timeAgo: '2m ago',
              message: 'liked your post about campus event',
              onTap: () {
                // TODO: Navigate to specific post
                // final postId = notification.postId;
                // final post = await FirebaseFirestore.instance
                //     .collection('posts')
                //     .doc(postId)
                //     .get();
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => CommentsScreen(post: post.data()),
                //   ),
                // );
              },
            ),
            NotificationItem(
              profileUrl: 'student2.jpg',
              name: 'Jane Smith',
              timeAgo: '5m ago',
              message: 'commented on your post about library hours',
              onTap: () {
                // TODO: Navigate to specific comment
                // final commentId = notification.commentId;
                // final postId = notification.postId;
                // Navigator.push(...)
              },
            ),
          ] else ...[
            NotificationItem(
              profileUrl: 'admin1.jpg',
              name: 'Admin',
              timeAgo: '1h ago',
              message: 'made a post about upcoming events',
              onTap: () {
                // TODO: Navigate to post
                // final postId = notification.postId;
                // Navigator.push(...)
              },
            ),
          ],
        ],
      ),
    );
  }
}
