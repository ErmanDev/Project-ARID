import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/enums.dart';
import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../capture/pin_drop_screen.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  const EditReportScreen({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
  }

  Future<void> _openEditor() async {
    final repo = ref.read(reportRepositoryProvider);
    final report = await repo.getById(widget.reportId);
    if (!mounted) return;
    if (report == null || report.syncStatus == SyncStatus.synced) {
      Navigator.pop(context);
      return;
    }
    final fix = await Navigator.of(context).push<GpsFix>(
      MaterialPageRoute(
        builder: (_) => PinDropScreen(
          initial: LatLng(report.latitude, report.longitude),
        ),
      ),
    );
    if (fix != null) {
      report
        ..latitude = fix.latitude
        ..longitude = fix.longitude
        ..gpsAccuracy = fix.accuracy
        ..gpsManual = true;
      await repo.update(report);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
