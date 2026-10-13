import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/models/device_models.dart';
import '../../core/services.dart';
import '../complaints/complaints_tab.dart';
import '../icons/claro_icons.dart';
import '../profile/profile_tab.dart';
import 'placeholder_screens.dart';

enum HomeTab { home, devices, complaints, profile }

/// Full-screen overlays that replace the tabs entirely. Each has exactly one
/// way out, so a plain value is enough; no navigation library needed.
sealed class HomeRoute {
  const HomeRoute();
}

class TabsRoute extends HomeRoute {
  const TabsRoute();
}

class QrScanRoute extends HomeRoute {
  const QrScanRoute();
}

class ManualEntryRoute extends HomeRoute {
  const ManualEntryRoute();
}

class ClaimConfirmRoute extends HomeRoute {
  const ClaimConfirmRoute({required this.scannedValue, required this.enteredManually});

  final String scannedValue;
  final bool enteredManually;
}

class DeviceDetailRoute extends HomeRoute {
  const DeviceDetailRoute(this.device);

  final MyDevice device;
}

/// The signed-in shell, ported from the Kotlin `HomeScreen`: a site header, a
/// four-tab bar (Home, Devices, Complaints, Profile), and full-screen overlays
/// for QR scan, manual entry, claim confirmation and device detail.
///
/// This screen owns every network call the tabs need (the device list, pending
/// claims, and each device's live status, fetched the first time it is swiped
/// to), so the tab widgets just render the state they are given. Loading and
/// errors are explicit at every step: a slow or failed request must never look
/// the same as an account with no devices.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services, required this.onLogout});

  final AppServices services;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeTab _tab = HomeTab.home;
  HomeRoute _route = const TabsRoute();

  List<MyDevice>? _devices;
  String? _devicesError;
  List<DeviceClaim>? _claims;

  /// Per device: each one's status is fetched the first time it is shown, then
  /// cached for the life of this screen.
  final Map<String, DeviceStatus> _statusById = {};
  final Map<String, String> _statusErrorById = {};

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadStatusFor(String deviceId) async {
    setState(() => _statusErrorById.remove(deviceId));
    try {
      final status = await widget.services.api.getDeviceStatus(deviceId);
      if (!mounted) return;
      setState(() => _statusById[deviceId] = status);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _statusErrorById[deviceId] = e.message);
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _devicesError = null);
    try {
      final devices = await widget.services.api.listMyDevices();
      if (!mounted) return;
      setState(() => _devices = devices);
      if (devices.isNotEmpty) {
        await _loadStatusFor(devices.first.deviceId);
      } else {
        // Only worth knowing WHY it's empty (a pending claim, or never tried)
        // when it actually is empty. A failure here just hides the
        // pending-claim banner; the plain empty state is still correct.
        try {
          final page = await widget.services.api.listMyDeviceClaims();
          if (mounted) setState(() => _claims = page.items);
        } on ApiException {
          // Deliberately ignored, see above.
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _devicesError = e.message);
    }
  }

  /// Called when a device's page settles under the farmer's thumb. A device
  /// already loaded (or already failed) is not fetched again here.
  void _onDevicePageSettled(int index) {
    final devices = _devices;
    if (devices == null || index < 0 || index >= devices.length) return;
    final id = devices[index].deviceId;
    if (_statusById.containsKey(id) || _statusErrorById.containsKey(id)) return;
    _loadStatusFor(id);
  }

  void _retryStatus(String deviceId) => _loadStatusFor(deviceId);

  void _setRoute(HomeRoute route) => setState(() => _route = route);

  /// Android's back button: closes an overlay instead of leaving the app.
  void _back() {
    switch (_route) {
      case ManualEntryRoute():
        _setRoute(const QrScanRoute());
      case TabsRoute():
        break;
      default:
        _setRoute(const TabsRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _route is TabsRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: switch (_route) {
        QrScanRoute() => QrScanPlaceholder(
            onEnterManually: () => _setRoute(const ManualEntryRoute()),
            onClose: () => _setRoute(const TabsRoute()),
          ),
        ManualEntryRoute() => OverlayPlaceholder(
            title: 'Enter device ID',
            message: 'Manual device entry arrives in phase 6.',
            onBack: () => _setRoute(const QrScanRoute()),
          ),
        ClaimConfirmRoute(:final scannedValue) => OverlayPlaceholder(
            title: 'Confirm device',
            message: 'Claiming "$scannedValue" arrives in phase 6.',
            onBack: () => _setRoute(const TabsRoute()),
          ),
        DeviceDetailRoute(:final device) => OverlayPlaceholder(
            title: device.deviceUid,
            message: 'The device detail screen arrives in phase 4.',
            onBack: () => _setRoute(const TabsRoute()),
          ),
        TabsRoute() => _tabsScaffold(),
      },
    );
  }

  Widget _tabsScaffold() {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: Column(
        children: [
          if (_tab == HomeTab.home)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, 0),
                child: _HomeHeader(isMock: widget.services.isMock),
              ),
            ),
          Expanded(child: _tabBody()),
          _BottomNavBar(selected: _tab, onSelect: (tab) => setState(() => _tab = tab)),
        ],
      ),
    );
  }

  Widget _tabBody() {
    switch (_tab) {
      case HomeTab.home:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: ClaroSpacing.lg),
              HomeTabPlaceholder(
                devices: _devices,
                devicesError: _devicesError,
                claims: _claims,
                statusById: _statusById,
                statusErrorById: _statusErrorById,
                onRetryDevices: _loadDevices,
                onPageSettled: _onDevicePageSettled,
                onRetryStatus: _retryStatus,
                onAddDevice: () => _setRoute(const QrScanRoute()),
              ),
              const SizedBox(height: ClaroSpacing.xl),
            ],
          ),
        );
      case HomeTab.devices:
        return SafeArea(
          bottom: false,
          child: DevicesTabPlaceholder(
            devices: _devices,
            isLoading: _devices == null && _devicesError == null,
            error: _devicesError,
            onRetry: _loadDevices,
            onDeviceTap: (device) => _setRoute(DeviceDetailRoute(device)),
            onAddDevice: () => _setRoute(const QrScanRoute()),
          ),
        );
      case HomeTab.complaints:
        return const SafeArea(bottom: false, child: ComplaintsTab());
      case HomeTab.profile:
        return SafeArea(
          bottom: false,
          child: ProfileTab(phone: widget.services.tokenStore.phone, onLogout: widget.onLogout),
        );
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isMock});

  final bool isMock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('My Site', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
                  // Not in the Kotlin app: a reminder that mock data is showing.
                  if (isMock) ...[
                    const SizedBox(width: ClaroSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: ClaroColors.warn.withValues(alpha: 0.15),
                        borderRadius: ClaroRadius.pill,
                      ),
                      child: Text('MOCK', style: ClaroType.caption.copyWith(color: ClaroColors.warn)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text('Claro Pulse', style: ClaroType.subtitle.copyWith(color: ClaroColors.mint)),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ClaroColors.inkPanel,
            border: Border.all(color: ClaroColors.borderDark),
          ),
          alignment: Alignment.center,
          child: const NavProfileIcon(size: 20, color: ClaroColors.onInkMuted),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selected, required this.onSelect});

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClaroColors.inkPanel,
        border: Border.all(color: ClaroColors.borderDark),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                label: 'Home',
                selected: selected == HomeTab.home,
                onTap: () => onSelect(HomeTab.home),
                icon: (c) => NavHomeIcon(size: 22, color: c),
              ),
              _NavItem(
                label: 'Devices',
                selected: selected == HomeTab.devices,
                onTap: () => onSelect(HomeTab.devices),
                icon: (c) => NavGridIcon(size: 22, color: c),
              ),
              _NavItem(
                label: 'Complaints',
                selected: selected == HomeTab.complaints,
                onTap: () => onSelect(HomeTab.complaints),
                icon: (c) => Icon(Icons.warning, color: c, size: 22),
              ),
              _NavItem(
                label: 'Profile',
                selected: selected == HomeTab.profile,
                onTap: () => onSelect(HomeTab.profile),
                icon: (c) => NavProfileIcon(size: 22, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.selected, required this.onTap, required this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget Function(Color color) icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ClaroColors.mint : ClaroColors.onInkMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.xs, horizontal: ClaroSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon(color),
              const SizedBox(height: 4),
              Text(label, style: ClaroType.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
