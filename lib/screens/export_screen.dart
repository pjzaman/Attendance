import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../shared/app_theme.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _busy = false;
  String? _lastFile;

  Future<void> _exportXlsx(AppState state) async {
    final now = DateTime.now();
    final suggested = state.exportService.suggestedFilename(now, 'xlsx');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save monthly report',
      fileName: suggested,
      type: FileType.custom,
      allowedExtensions: <String>['xlsx'],
    );
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final punches = await state.fetchPunchesForMonth(now);
      final daily = AppState.deriveDailyFromPunches(punches);
      final file = await state.exportService.writeMonthlyXlsx(
        path,
        now,
        daily: daily,
        punches: punches,
      );
      setState(() => _lastFile = file.path);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _exportPunchesCsv(AppState state) async {
    final now = DateTime.now();
    final suggested = state.exportService.suggestedFilename(now, 'csv');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save punches CSV',
      fileName: 'punches_${suggested.split(".").first.split("_").last}.csv',
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
    );
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final punches = await state.fetchPunchesForMonth(now);
      final file = await state.exportService.writePunchesCsv(path, punches);
      setState(() => _lastFile = file.path);
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Export current month',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _busy ? null : () => _exportXlsx(state),
                icon: const Icon(Icons.grid_on),
                label: const Text('Save monthly XLSX (Daily + Punches)'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : () => _exportPunchesCsv(state),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Save punches CSV'),
              ),
            ],
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (_lastFile != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text('Saved: $_lastFile',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
