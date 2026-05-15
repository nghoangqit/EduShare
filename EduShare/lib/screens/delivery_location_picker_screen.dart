import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/delivery_location.dart';
import '../utils/constants.dart';

class DeliveryLocationPickerScreen extends StatefulWidget {
  final DeliveryLocation? initialLocation;

  const DeliveryLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<DeliveryLocationPickerScreen> createState() =>
      _DeliveryLocationPickerScreenState();
}

class _DeliveryLocationPickerScreenState
    extends State<DeliveryLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);

  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  late LatLng _selectedPoint;
  String? _selectedLabel;
  bool _locating = false;
  bool _searching = false;
  String? _locationError;
  List<_PlaceSearchResult> _searchResults = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    _selectedPoint = initial != null && initial.isValid
        ? LatLng(initial.latitude, initial.longitude)
        : _defaultCenter;
    _selectedLabel = initial?.label;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Chon vi tri giao hang'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: widget.initialLocation == null ? 13 : 16,
              minZoom: 5,
              maxZoom: 18,
              onTap: (_, point) => setState(() {
                _selectedPoint = point;
                _locationError = null;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.edu_share',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 64,
                    height: 64,
                    child: const _DeliveryMarker(),
                  ),
                ],
              ),
            ],
          ),
          Positioned(left: 16, right: 16, top: 16, child: _instructionCard()),
          Positioned(left: 16, right: 16, top: 92, child: _searchPanel()),
          Positioned(right: 16, bottom: 178, child: _locationButton()),
          Positioned(left: 16, right: 16, bottom: 16, child: _confirmPanel()),
        ],
      ),
    );
  }

  Widget _instructionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pin_drop_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cham vao ban do hoac dung nut dinh vi de dat diem giao hang.',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchPlaces(),
                  decoration: const InputDecoration(
                    hintText: 'Tim truong, duong, quan, dia diem...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searching ? null : _searchPlaces,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tim',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 230),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    result.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(result.coordinateText),
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _locationButton() {
    return FloatingActionButton.small(
      heroTag: 'delivery-location-button',
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primary,
      onPressed: _locating ? null : _useCurrentLocation,
      child: _locating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(Icons.my_location_rounded),
    );
  }

  Widget _confirmPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vi tri da chon',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_selectedPoint.latitude.toStringAsFixed(6)}, ${_selectedPoint.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(
                DeliveryLocation(
                  latitude: _selectedPoint.latitude,
                  longitude: _selectedPoint.longitude,
                  label: _selectedLabel,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Dung vi tri nay'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Hay bat dich vu dinh vi tren thiet bi.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Ban can cap quyen vi tri de dung nut dinh vi.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Quyen vi tri dang bi khoa. Hay mo quyen trong cai dat he thong.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedPoint = point;
        _selectedLabel = 'Vi tri hien tai cua toi';
        _searchResults = const [];
      });
      _mapController.move(point, 16);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Khong lay duoc vi tri hien tai. Vui long thu lai.';
      });
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _searchPlaces() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) {
      setState(() {
        _locationError = 'Nhap it nhat 2 ky tu de tim kiem vi tri.';
        _searchResults = const [];
      });
      return;
    }

    setState(() {
      _searching = true;
      _locationError = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '6',
        'countrycodes': 'vn',
        'addressdetails': '1',
      });
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'EduShare/1.0 delivery-location-picker',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw StateError('search_failed');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw StateError('invalid_response');
      }
      final results = decoded
          .whereType<Map<String, dynamic>>()
          .map(_PlaceSearchResult.fromJson)
          .where((result) => result != null)
          .cast<_PlaceSearchResult>()
          .toList();

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _locationError = 'Khong tim thay vi tri phu hop.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Khong tim kiem duoc vi tri. Vui long thu lai.';
        _searchResults = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _selectSearchResult(_PlaceSearchResult result) {
    setState(() {
      _selectedPoint = result.point;
      _selectedLabel = result.name;
      _searchCtrl.text = result.name;
      _searchResults = const [];
      _locationError = null;
    });
    _mapController.move(result.point, 16);
  }
}

class _PlaceSearchResult {
  final String name;
  final LatLng point;

  const _PlaceSearchResult({required this.name, required this.point});

  String get coordinateText =>
      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

  static _PlaceSearchResult? fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    final displayName = json['display_name']?.toString().trim();
    if (lat == null ||
        lon == null ||
        displayName == null ||
        displayName.isEmpty) {
      return null;
    }
    return _PlaceSearchResult(name: displayName, point: LatLng(lat, lon));
  }
}

class _DeliveryMarker extends StatelessWidget {
  const _DeliveryMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.26),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
