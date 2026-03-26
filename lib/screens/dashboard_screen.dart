import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/widgets.dart';

/// The main dashboard screen of the TubeQuiz app.
///
/// Displays service controls, announcement settings, quiz mode settings,
/// and playlist management.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check notification listener status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().checkNotificationListener();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when app is resumed
      context.read<QuizProvider>().checkNotificationListener();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.music_note),
            SizedBox(width: 8),
            Text('TubeQuiz'),
          ],
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Permission warning banner
                if (!provider.isNotificationListenerEnabled)
                  _buildPermissionBanner(context, provider),

                // Service Toggle (Passive Tracking)
                _buildServiceToggle(context, provider),

                const SizedBox(height: 16),

                // Status Card
                StatusCard(state: provider.state),

                const SizedBox(height: 16),

                // Announcement Settings
                AnnounceSettingsCard(
                  timing: provider.announceTiming,
                  intervalSeconds: provider.announceInterval,
                  duckMode: provider.duckMode,
                  onTimingChanged: (t) => provider.setAnnounceTiming(t),
                  onIntervalChanged: (s) => provider.setAnnounceInterval(s),
                  onDuckModeChanged: (m) => provider.setDuckMode(m),
                ),

                const SizedBox(height: 16),

                // Quiz Mode Section
                _buildQuizModeCard(context, provider),

                // Playback settings (shown when quiz mode is on)
                if (provider.isQuizMode) ...[
                  const SizedBox(height: 16),
                  SnippetDurationSlider(
                    value: provider.snippetDuration,
                    isFullSong: provider.isFullSong,
                    useRandomStart: provider.useRandomStart,
                    onChanged: (value) => provider.setSnippetDuration(value),
                    onToggleFullSong: () => provider.toggleFullSong(),
                    onToggleRandomStart: () => provider.toggleRandomStart(),
                  ),
                ],

                const SizedBox(height: 16),

                // Playlist Card
                PlaylistCard(
                  playlist: provider.playlist,
                  onImport: () => _importPlaylist(context, provider),
                  onClear: () => provider.clearPlaylist(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, QuizProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: MaterialBanner(
        content: const Text(
          'Notification listener permission is required to read YouTube Music playback.',
        ),
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        actions: [
          TextButton(
            onPressed: () => provider.openNotificationSettings(),
            child: const Text('GRANT ACCESS'),
          ),
        ],
        backgroundColor: Colors.orange.shade50,
      ),
    );
  }

  Widget _buildServiceToggle(BuildContext context, QuizProvider provider) {
    final isRunning = provider.isServiceRunning;

    return Card(
      elevation: 2,
      color: isRunning
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: provider.isNotificationListenerEnabled
            ? () => provider.toggleService()
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                isRunning ? Icons.hearing : Icons.hearing_disabled,
                size: 48,
                color: isRunning
                    ? Theme.of(context).colorScheme.primary
                    : provider.isNotificationListenerEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunning ? 'Tracking Active' : 'Start Tracking',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRunning
                          ? 'Monitoring YouTube Music...'
                          : provider.isNotificationListenerEnabled
                              ? 'Tap to start tracking songs'
                              : 'Grant notification access first',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isRunning,
                onChanged: provider.isNotificationListenerEnabled
                    ? (_) => provider.toggleService()
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizModeCard(BuildContext context, QuizProvider provider) {
    final isQuiz = provider.isQuizMode;

    return Card(
      elevation: 2,
      color: isQuiz
          ? Theme.of(context).colorScheme.tertiaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.quiz,
              size: 32,
              color: isQuiz
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isQuiz
                        ? 'Controls playback with snippets & playlist'
                        : 'Enable to control playback',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: isQuiz,
              onChanged: (_) => provider.toggleQuizMode(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importPlaylist(
    BuildContext context,
    QuizProvider provider,
  ) async {
    final success = await provider.importPlaylist();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Playlist imported: ${provider.playlist.name} (${provider.playlist.length} tracks)'
                : 'Import cancelled or failed',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
