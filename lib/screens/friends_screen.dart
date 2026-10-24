import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendService = context.read<FriendService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder(
        stream: friendService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('Could not load users', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          final friends = snapshot.data ?? [];
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No users yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'When others join, they\'ll appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: friend.photoUrl != null
                        ? NetworkImage(friend.photoUrl!)
                        : null,
                    child: friend.photoUrl == null
                        ? Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(color: theme.colorScheme.onPrimary),
                          )
                        : null,
                  ),
                  title: Text(friend.displayName),
                  subtitle: Text(
                    friend.bio.isNotEmpty ? friend.bio : 'No bio yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      friendService.sendFriendRequest(friend.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Friend request sent to ${friend.displayName}')),
                      );
                    },
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
