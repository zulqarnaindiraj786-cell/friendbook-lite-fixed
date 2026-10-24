import 'package:flutter/material.dart';

class ReactionPicker extends StatefulWidget {
  final Function(String) onReactionSelected;

  const ReactionPicker({super.key, required this.onReactionSelected});

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  int _hoveredIndex = -1;

  static const List<Map<String, String>> _reactions = [
    {'emoji': '👍', 'label': 'Like', 'color': '#0866FF'},
    {'emoji': '❤️', 'label': 'Love', 'color': '#F33E58'},
    {'emoji': '😂', 'label': 'Haha', 'color': '#F7B125'},
    {'emoji': '😮', 'label': 'Wow', 'color': '#F7B125'},
    {'emoji': '😢', 'label': 'Sad', 'color': '#F7B125'},
    {'emoji': '😡', 'label': 'Angry', 'color': '#E97310'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_reactions.length, (index) {
          final r = _reactions[index];
          final isHovered = _hoveredIndex == index;
          return GestureDetector(
            onTap: () {
              widget.onReactionSelected(r['label']!.toLowerCase());
              Navigator.pop(context);
            },
            onLongPressStart: (_) => setState(() => _hoveredIndex = index),
            onLongPressEnd: (_) => setState(() => _hoveredIndex = -1),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = index),
              onExit: (_) => setState(() => _hoveredIndex = -1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: isHovered
                    ? (Matrix4.identity()..translate(0.0, -8.0)..scale(1.4))
                    : Matrix4.identity(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    r['emoji']!,
                    style: TextStyle(
                      fontSize: isHovered ? 36 : 28,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ReactionDisplay extends StatelessWidget {
  final List<String> reactionTypes;

  const ReactionDisplay({super.key, required this.reactionTypes});

  static const Map<String, String> _emojiMap = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  @override
  Widget build(BuildContext context) {
    final uniqueTypes = reactionTypes.toSet().toList();
    return Row(
      children: uniqueTypes.take(3).map((type) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Text(
              _emojiMap[type] ?? '👍',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
