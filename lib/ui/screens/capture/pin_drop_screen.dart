import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../services/location/location_service.dart';
import '../../../services/map/tile_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass.dart';

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
    final p = context.arid;
    final cache = ref.watch(tileCacheProvider);
    final inset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.mapBackground,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                backgroundColor: AppColors.mapBackground,
                initialCenter: _pin,
                initialZoom: 18,
                onPositionChanged: (position, _) {
                  final center = position.center;
                  if (_pin.latitude == center.latitude &&
                      _pin.longitude == center.longitude) {
                    return;
                  }
                  setState(() => _pin = center);
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
          ),
          // The pin's tip sits on the map center.
          const IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: Icon(
                Icons.location_on_rounded,
                size: 52,
                color: AppColors.primary,
                shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassSurface(
                        floating: true,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Place the pin',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GPS isn’t available. Drag the map until the '
                                'pin marks the site. This works offline.',
                                style: TextStyle(
                                  color: p.secondaryInk,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: (inset > 0 ? inset : 16) + 8,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.check_rounded),
              label: const Text('Use this location'),
            ),
          ),
        ],
      ),
    );
  }
}
