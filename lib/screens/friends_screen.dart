import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendService = context.read<FriendService>();
    final auth = context.read<AuthService>();
    final currentUid = auth.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Friends', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              TabBar(
                tabs: const [
                  Tab(text: 'Friends'),
                  Tab(text: 'Suggestions'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _FriendsList(friendService: friendService, currentUid: currentUid),
                    _SuggestionsList(friendService: friendService, currentUid: currentUid),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final FriendService friendService;
  final String currentUid;

  const _FriendsList({required this.friendService, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<String>>(
      stream: friendService.getFriendIds(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friendIds = snapshot.data ?? [];
        if (friendIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('No friends yet', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Find people to connect with', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            final friendId = friendIds[index];
            return StreamBuilder<UserModel>(
              stream: context.read<AuthService>().userStream(friendId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final user = userSnapshot.data!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: user.uid),
                    )),
                    leading: UserAvatar(
                      photoUrl: user.photoUrl,
                      name: user.displayName,
                      radius: 26,
                      isOnline: user.isOnline,
                    ),
                    title: Text(user.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.bio.isNotEmpty ? user.bio : 'Tap to view profile', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'unfriend') {
                          _confirmUnfriend(context, user);
                        } else if (value == 'block') {
                          _confirmBlock(context, user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
                        const PopupMenuItem(value: 'block', child: Text('Block')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmUnfriend(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unfriend'),
        content: Text('Are you sure you want to unfriend ${user.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              friendService.unfriend(user.uid);
              Navigator.pop(ctx);
            },
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Block ${user.displayName}? They won\'t be able to see your profile or contact you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<AuthService>().blockUser(user.uid);
              await friendService.unfriend(user.uid);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final FriendService friendService;
  final String currentUid;

  const _SuggestionsList({required this.friendService, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: friendService.getFriendRequests(currentUid),
      builder: (context, requestsSnapshot) {
        final requests = requestsSnapshot.data?.docs ?? [];
        return CustomScrollView(
          slivers: [
            if (requests.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Friend Requests', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final req = requests[index];
                    final data = req.data() as Map<String, dynamic>;
                    final fromUid = data['fromUid'] as String;
                    final reqId = req.id;
                    return _FriendRequestTile(
                      fromUid: fromUid,
                      requestId: reqId,
                      onAccept: () => friendService.acceptFriendRequest(reqId, fromUid),
                      onReject: () => friendService.rejectFriendRequest(reqId),
                    );
                  },
                  childCount: requests.length,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('People You May Know', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            _AllUsersList(friendService: friendService, currentUid: currentUid),
          ],
        );
      },
    );
  }
}

class _AllUsersList extends StatelessWidget {
  final FriendService friendService;
  final String currentUid;

  const _AllUsersList({required this.friendService, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: context.read<AuthService>().userCollectionStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        final docs = snapshot.data?.docs ?? [];
        final users = docs.where((doc) => doc.id != currentUid).toList();
        if (users.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No other users yet', style: theme.textTheme.bodyMedium),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;
              final name = data['displayName'] ?? 'User';
              final photoUrl = data['photoUrl'] as String?;
              final bio = data['bio'] ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: uid),
                  )),
                  leading: UserAvatar(photoUrl: photoUrl, name: name, radius: 26),
                  title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(bio.isNotEmpty ? bio : 'Tap to view profile', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: FutureBuilder<bool>(
                    future: friendService.areFriends(currentUid, uid),
                    builder: (context, friendsSnapshot) {
                      if (friendsSnapshot.data == true) {
                        return const Chip(label: Text('Friends'));
                      }
                      return FutureBuilder<bool>(
                        future: friendService.hasPendingRequest(uid),
                        builder: (context, pendingSnapshot) {
                          if (pendingSnapshot.data == true) {
                            return const Chip(label: Text('Requested'));
                          }
                          return FilledButton.tonal(
                            onPressed: () {
                              friendService.sendFriendRequest(uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Friend request sent to $name')),
                              );
                            },
                            child: const Text('Add Friend'),
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
            childCount: users.length,
          ),
        );
      },
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  final String fromUid;
  final String requestId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FriendRequestTile({
    required this.fromUid,
    required this.requestId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<UserModel>(
      stream: context.read<AuthService>().userStream(fromUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final user = snapshot.data!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                UserAvatar(photoUrl: user.photoUrl, name: user.displayName, radius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('wants to be your friend', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: onAccept,
                              child: const Text('Confirm'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onReject,
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
