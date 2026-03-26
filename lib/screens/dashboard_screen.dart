import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/widgets.dart';

/// The main dashboard screen of the TubeQuiz app.
///
/// Displays quiz status, controls for enabling/disabling quiz mode,
/// snippet duration slider, playlist management, and service status.
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
            Icon(Icons.quiz),
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

                // Quiz Mode Toggle
                _buildQuizToggle(context, provider),

                const SizedBox(height: 16),

                // Status Card
                StatusCard(state: provider.state),

                const SizedBox(height: 16),

                // Snippet Duration Slider
                SnippetDurationSlider(
                  value: provider.snippetDuration,
                  onChanged: (value) => provider.setSnippetDuration(value),
                ),

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

  Widget _buildQuizToggle(BuildContext context, QuizProvider provider) {
    final isActive = provider.isQuizActive;

    return Card(
      elevation: 2,
      color: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: provider.isNotificationListenerEnabled
            ? () => provider.toggleQuizMode()
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.stop_circle : Icons.play_circle,
                size: 48,
                color: isActive
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
                      isActive ? 'Quiz Mode Active' : 'Start Quiz Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Monitoring YouTube Music...'
                          : provider.isNotificationListenerEnabled
                              ? 'Tap to start the music quiz'
                              : 'Grant notification access first',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: provider.isNotificationListenerEnabled
                    ? (_) => provider.toggleQuizMode()
                    : null,
              ),
            ],
          ),
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
