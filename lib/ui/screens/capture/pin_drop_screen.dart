import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../../services/map/tile_cache.dart';
import '../../theme/app_colors.dart';

class PinDropScreen extends ConsumerStatefulWidget {
  const PinDropScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  ConsumerState<PinDropScreen> createState() => _PinDropScreenState();
}

class _PinDropScreenState extends ConsumerState<PinDropScreen> {
  late LatLng _pin;
  final _controller = MapController();

  @override
  void initState() {
    super.initState();
    _pin = widget.initial ?? const LatLng(14.5995, 120.9842);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(tileCacheProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Drop a pin')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'GPS did not resolve. Drag the map so the pin sits on the breeding site, then save. This still stores locally with no internet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    backgroundColor: AppColors.mapBackground,
                    initialCenter: _pin,
                    initialZoom: 16,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        setState(() => _pin = position.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: TileCacheService.urlTemplate,
                      userAgentPackageName: 'ph.arid.arid',
                      tileProvider: FileCachedTileProvider(cache),
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Icon(Icons.location_pin, size: 44, color: AppColors.primary),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    GpsFix(
                      latitude: _pin.latitude,
                      longitude: _pin.longitude,
                      accuracy: 25,
                      manual: true,
                    ),
                  );
                },
                child: const Text('Use this location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
