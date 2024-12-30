class Post {
  final String id;
  final String adminName;
  final String timeAgo;
  final String content;
  final List<String>? imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isSaved;
  final bool isLiked;
  final Function()? onLike;

  Post({
    required this.adminName,
    required this.timeAgo,
    required this.content,
    this.imageUrls,
    required this.id,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSaved = false,
    this.onLike,
    this.isLiked = false,
  });
} 