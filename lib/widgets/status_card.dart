import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../shared/app_theme.dart';

/// Compact device-status card for the dashboard. Reads from
/// `state.bridges` (the live `bridges/{id}` heartbeat docs that the
/// Python bridge publishes). The "Sync now" button queues a
/// manual_sync command for the primary bridge.
class StatusCard extends StatefulWidget {
  const StatusCard({super.key});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  bool _busy = false;

  Future<void> _syncNow(String bridgeId) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await state.queueBridgeCommand(
        bridgeId: bridgeId,
        action: 'manual_sync',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sync queued for $bridgeId.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusDanger,
          content: Text('Could not queue sync: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final bridge = state.primaryBridge;

    final bridgeId = (bridge?['bridgeId'] as String?) ?? '—';
    final deviceConnected = (bridge?['deviceConnected'] as bool?) ?? false;
    final status = (bridge?['status'] as String?) ?? 'unknown';
    final lastError = bridge?['lastError'] as String?;
    final updatedAt = _ts(bridge?['updatedAt']);
    final lastSync = _ts(bridge?['lastSyncAt']);

    final stale = updatedAt != null &&
        DateTime.now().difference(updatedAt).inMinutes > 2;
    final dotColor = bridge == null
        ? Colors.grey
        : stale
            ? AppColors.warning
            : status == 'online' && deviceConnected
                ? AppColors.success
                : status == 'degraded'
                    ? AppColors.warning
                    : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  bridge == null
                      ? 'No bridge connected'
                      : stale
                          ? 'Bridge $bridgeId — stale'
                          : 'Bridge $bridgeId — ${_label(status)}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (bridge == null)
              Text(
                'Install apon-bridge.exe on the PC wired to the device. '
                'It will report its status here within 30s of starting.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              )
            else ...<Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    deviceConnected ? Icons.link : Icons.link_off,
                    size: 14,
                    color: deviceConnected
                        ? AppColors.statusSuccess
                        : AppColors.statusDanger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    deviceConnected ? 'Device linked' : 'Device dropped',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (lastSync != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Last sync: ${DateFormat('MMM d · HH:mm:ss').format(lastSync)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ),
              if (lastError != null && lastError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lastError,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.statusDanger),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _syncNow(bridgeId),
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 16),
                  label: Text(_busy ? 'Queuing…' : 'Sync now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static DateTime? _ts(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  static String _label(String s) =>
      s.isEmpty ? 'Unknown' : (s[0].toUpperCase() + s.substring(1));
}
