import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';
import '../../services/ollama_connection_manager.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  

  @override
  void initState() {
    super.initState();
  Future.microtask(() async {
  await ref.read(settingsProvider.notifier).ensureLoaded();
});
  }



  

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile info
                  if (user != null) ...[
                    GlassCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    (user.displayName ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Unnamed User',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? '',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // API Credentials Settings Card
                  const Text(
                    'API Keys Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        const Text(
                          'Deepgram API Key (Real-time stream)',
                          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        if (settings.deepgramKeyFromEnv)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Loaded automatically from .env (${settings.deepgramKey.length} chars)',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          TextFormField(
                            initialValue: settings.deepgramKey.isEmpty ? null : '••••••••••••••••',
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: settings.deepgramKey.isEmpty
                                  ? 'Set DEEPGRAM_API_KEY in .env'
                                  : 'Configured (${settings.deepgramKey.length} chars)',
                              prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textMuted),
                            ),
                          ),
                        const SizedBox(height: 24),

                      
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ollama Settings Card
                  const Text(
                    'Ollama Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ollama Server URL',
                          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: settings.ollamaUrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. http://10.0.2.2:11434',
                            prefixIcon: Icon(Icons.dns_outlined, color: AppColors.textMuted),
                          ),
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).saveOllamaUrl(val.trim());
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Active Model',
                          style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: settings.ollamaModel,
                          decoration: const InputDecoration(
                            hintText: 'e.g. qwen2.5:7b',
                            prefixIcon: Icon(Icons.smart_toy_outlined, color: AppColors.textMuted),
                          ),
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).saveOllamaModel(val.trim());
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),
                        (() {
                          final ollamaState = ref.watch(ollamaConnectionManagerProvider);
                          
                          Color statusColor;
                          String statusTitle;
                          IconData statusIcon;
                          
                          switch (ollamaState.status) {
                            case OllamaConnectionStatus.connected:
                              statusColor = AppColors.success;
                              statusTitle = 'Connected';
                              statusIcon = Icons.check_circle_rounded;
                              break;
                            case OllamaConnectionStatus.reconnecting:
                              statusColor = AppColors.warning;
                              statusTitle = 'Reconnecting...';
                              statusIcon = Icons.sync_rounded;
                              break;
                            case OllamaConnectionStatus.waitingForOllama:
                              statusColor = AppColors.warning;
                              statusTitle = 'Waiting for Ollama...';
                              statusIcon = Icons.hourglass_empty_rounded;
                              break;
                            case OllamaConnectionStatus.offline:
                              statusColor = AppColors.error;
                              statusTitle = 'Offline';
                              statusIcon = Icons.cancel_rounded;
                              break;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ollama Status: $statusTitle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.secondary),
                                    onPressed: () => ref.read(ollamaConnectionManagerProvider.notifier).verifyHealth(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              if (ollamaState.activeUrl.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0),
                                  child: Text(
                                    'URL: ${ollamaState.activeUrl}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                              if (ollamaState.status == OllamaConnectionStatus.connected && ollamaState.activeModel != null) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0),
                                  child: Text(
                                    'Model: ${ollamaState.activeModel} (Latency: ${ollamaState.responseTimeMs}ms)',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                              if (ollamaState.errorMessage != null && ollamaState.status != OllamaConnectionStatus.connected) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0),
                                  child: Text(
                                    ollamaState.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.error,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        })(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Settings Card
                  const Text(
                    'Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Background Recording'),
                          subtitle: const Text('Continue recording when screen is locked'),
                          activeThumbColor: AppColors.secondary,
                          value: settings.isBackgroundRecordingEnabled,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            ref.read(settingsProvider.notifier).toggleBackgroundRecording(val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Out
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
