import 'package:flutter/material.dart';

/// Widget that provides controls for song playback settings in quiz mode.
///
/// Includes a full song toggle, snippet duration slider, and random start
/// toggle.
class SnippetDurationSlider extends StatelessWidget {
  final int value;
  final bool isFullSong;
  final bool useRandomStart;
  final ValueChanged<int> onChanged;
  final VoidCallback onToggleFullSong;
  final VoidCallback onToggleRandomStart;

  const SnippetDurationSlider({
    super.key,
    required this.value,
    required this.isFullSong,
    required this.useRandomStart,
    required this.onChanged,
    required this.onToggleFullSong,
    required this.onToggleRandomStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Full Song Toggle
            SwitchListTile(
              title: const Text('Full Song'),
              subtitle: const Text('Play the entire song instead of a snippet'),
              value: isFullSong,
              onChanged: (_) => onToggleFullSong(),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (!isFullSong) ...[
              const Divider(),
              // Snippet Duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Snippet Duration',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${value}s',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor:
                      Theme.of(context).colorScheme.primary.withAlpha(51),
                  thumbColor: Theme.of(context).colorScheme.primary,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '${value}s',
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5s', style: Theme.of(context).textTheme.bodySmall),
                  Text('60s', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Divider(),
              // Random Start Toggle
              SwitchListTile(
                title: const Text('Random Start'),
                subtitle: const Text('Start at a random position (max 1:30)'),
                value: useRandomStart,
                onChanged: (_) => onToggleRandomStart(),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
