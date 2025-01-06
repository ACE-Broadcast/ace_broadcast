import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:post_ace/widgets/like_button.dart';

class PostWidget extends StatefulWidget {
  final String adminName;
  final String timeAgo;
  final String content;
  final List<String>? imageUrls;
  final int likesCount;
  final int commentsCount;
  final bool isSaved;
  final bool isLiked;
  final List<String>? likes; //list of email ids/userid who have liked the post
  final Function()? onLike;
  final Function()? onComment;
  final Function()? onShare;
  final Function()? onSave;

  const PostWidget({
    super.key,
    required this.adminName,
    required this.timeAgo,
    required this.content,
    this.likes,
    this.imageUrls,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isSaved = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
    this.isLiked = false,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  void initState() {
    super.initState();
    //isLiked = widget.likes.contains(currentUserId);
  }

  // TODO Update the firebase for likes
  // void toggleLike(){
  //   setState(() {
  //     widget.isLiked = !widget.isLiked;
  //   });
  // }

  // TODO Access all the email/user id in the likes list and display the count in the variable likesCount

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceDim,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin info and save button
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                widget.adminName[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            title: Text(
              widget.adminName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              widget.timeAgo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                widget.isSaved ? Icons.star : Icons.star_border,
                color: widget.isSaved ? Colors.amber : Colors.grey,
              ),
              onPressed: widget.onSave,
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.content,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Images if any
          if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (widget.imageUrls!.length == 1)
              Image.network(
                widget.imageUrls![0],
                fit: BoxFit.cover,
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imageUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == widget.imageUrls!.length - 1 ? 16 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.imageUrls![index],
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],

          // Interaction buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                ),

                //Like Button
                LikeButton(
                  isLiked: widget.isLiked,
                  onTap: widget.onLike,
                ),
                // TODO Implement the dynamic like button
                // LikeButton(isLiked: widget.isLiked, onTap: toggleLike),

                //Like Counter
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    widget.likesCount.toString(),
                    key: ValueKey<int>(widget.likesCount),
                    style: TextStyle(
                      color: widget.isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                TextButton.icon(
                  onPressed: widget.onComment,
                  icon: SvgPicture.asset(
                    'assets/icons/comment.svg',
                    height: 20,
                    width: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text('${widget.commentsCount}'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
