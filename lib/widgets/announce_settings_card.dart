import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget that provides controls for announcement timing and duck mode settings.
class AnnounceSettingsCard extends StatefulWidget {
  final AnnounceTiming timing;
  final int intervalSeconds;
  final DuckMode duckMode;
  final ValueChanged<AnnounceTiming> onTimingChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<DuckMode> onDuckModeChanged;

  const AnnounceSettingsCard({
    super.key,
    required this.timing,
    required this.intervalSeconds,
    required this.duckMode,
    required this.onTimingChanged,
    required this.onIntervalChanged,
    required this.onDuckModeChanged,
  });

  @override
  State<AnnounceSettingsCard> createState() => _AnnounceSettingsCardState();
}

class _AnnounceSettingsCardState extends State<AnnounceSettingsCard> {
  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _intervalController =
        TextEditingController(text: '${widget.intervalSeconds}');
  }

  @override
  void didUpdateWidget(AnnounceSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intervalSeconds != widget.intervalSeconds) {
      _intervalController.text = '${widget.intervalSeconds}';
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

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
              'Announcement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AnnounceTiming>(
              segments: const [
                ButtonSegment(
                  value: AnnounceTiming.beginning,
                  label: Text('Start'),
                  icon: Icon(Icons.start, size: 18),
                ),
                ButtonSegment(
                  value: AnnounceTiming.end,
                  label: Text('End'),
                  icon: Icon(Icons.last_page, size: 18),
                ),
                ButtonSegment(
                  value: AnnounceTiming.both,
                  label: Text('Both'),
                  icon: Icon(Icons.swap_horiz, size: 18),
                ),
                ButtonSegment(
                  value: AnnounceTiming.interval,
                  label: Text('Repeat'),
                  icon: Icon(Icons.repeat, size: 18),
                ),
              ],
              selected: {widget.timing},
              onSelectionChanged: (set) => widget.onTimingChanged(set.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (widget.timing == AnnounceTiming.interval) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Every',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed >= 1 && parsed <= 60) {
                          widget.onIntervalChanged(parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'seconds',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Audio Ducking',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lower music volume during announcements',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<DuckMode>(
              segments: const [
                ButtonSegment(
                  value: DuckMode.off,
                  label: Text('Off'),
                  icon: Icon(Icons.volume_up, size: 18),
                ),
                ButtonSegment(
                  value: DuckMode.firstLast,
                  label: Text('First/Last'),
                  icon: Icon(Icons.volume_down, size: 18),
                ),
                ButtonSegment(
                  value: DuckMode.all,
                  label: Text('All'),
                  icon: Icon(Icons.volume_mute, size: 18),
                ),
              ],
              selected: {widget.duckMode},
              onSelectionChanged: (set) => widget.onDuckModeChanged(set.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
