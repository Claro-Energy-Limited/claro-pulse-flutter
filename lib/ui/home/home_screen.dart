import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../../core/services.dart';
import '../complaints/complaints_tab.dart';
import '../complaints/new_complaint_screen.dart';
import '../devices/device_kind.dart';
import '../devices/pump_details_screen.dart';
import '../notifications/notifications_screen.dart';
import '../onboarding/device_claim_screen.dart';
import '../onboarding/manual_device_entry_screen.dart';
import '../onboarding/qr_scanner_screen.dart';
import '../profile/profile_tab.dart';
import '../usage/usage_tab.dart';
import 'home_dashboard.dart';
import 'pump_control.dart';
import 'pump_state.dart';

enum HomeNavTab { home, usage, complaints, profile }

/// Full-screen pages that replace the tabs. Each has one way back.
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

class PumpDetailsRoute extends HomeRoute {
  const PumpDetailsRoute(this.device);

  final MyDevice device;
}

class AlertsRoute extends HomeRoute {
  const AlertsRoute();
}

class NewComplaintRoute extends HomeRoute {
  const NewComplaintRoute(this.device);

  final MyDevice device;
}

/// The signed-in app: four tabs (Home, Usage, Complaints, Profile) and the
/// full-screen pages they open.
///
/// This screen owns the shared data (devices, their live status, alerts,
/// complaints) and the pump commands, so tabs only display what they're given.
/// Loading, errors and empty states are always distinct: a slow network must
/// never look like "no pumps".
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.services,
    required this.onLogout,
    this.refreshInterval = const Duration(seconds: 30),
    this.confirmPollInterval = const Duration(seconds: 2),
    this.confirmTimeout = const Duration(seconds: 30),
  });

  final AppServices services;
  final VoidCallback onLogout;

  /// How often Home refreshes the pump's status in the background.
  final Duration refreshInterval;

  /// After a start/stop, how often to check whether the pump has confirmed it,
  /// and how long to wait before giving up.
  final Duration confirmPollInterval;
  final Duration confirmTimeout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeNavTab _tab = HomeNavTab.home;
  HomeRoute _route = const TabsRoute();

  List<MyDevice>? _devices;
  String? _devicesError;
  List<DeviceClaim>? _claims;
  int _selected = 0;

  final Map<String, DeviceStatus> _statusById = {};
  final Map<String, String> _statusErrorById = {};
  final Map<String, PumpCommand> _pendingById = {};

  List<AppNotification>? _alerts;
  int _unreadAlerts = 0;

  List<Complaint>? _complaints;
  String? _complaintsError;

  final ValueNotifier<BluetoothLink> _bluetooth = ValueNotifier(BluetoothLink.off);

  Timer? _refreshTimer;
  Timer? _confirmTimer;
  bool _confirmPolling = false;

  ClaroPulseApi get _api => widget.services.api;

  MyDevice? get _device {
    final devices = _devices;
    if (devices == null || devices.isEmpty) return null;
    return devices[_selected.clamp(0, devices.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadAlerts();
    _loadComplaints();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      final device = _device;
      if (!mounted || device == null || _pendingById.containsKey(device.deviceId)) return;
      if (_route is TabsRoute && _tab == HomeNavTab.home) _loadStatusFor(device.deviceId, quiet: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _confirmTimer?.cancel();
    _bluetooth.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  /// [quiet] background refreshes don't replace good data with an error.
  Future<void> _loadStatusFor(String deviceId, {bool quiet = false}) async {
    if (!quiet) setState(() => _statusErrorById.remove(deviceId));
    try {
      final status = await _api.getDeviceStatus(deviceId);
      if (!mounted) return;
      setState(() {
        _statusById[deviceId] = status;
        _statusErrorById.remove(deviceId);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (!quiet || !_statusById.containsKey(deviceId)) {
        setState(() => _statusErrorById[deviceId] = e.message);
      }
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _devicesError = null);
    try {
      final devices = await _api.listMyDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _selected = devices.isEmpty ? 0 : _selected.clamp(0, devices.length - 1);
      });
      final device = _device;
      if (device != null) {
        await _loadStatusFor(device.deviceId);
      } else {
        try {
          final page = await _api.listMyDeviceClaims();
          if (mounted) setState(() => _claims = page.items);
        } on ApiException {
          // Only hides the "pending review" card; the empty state is still right.
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _devicesError = e.message);
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _api.listNotifications();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _unreadAlerts = alerts.where((a) => !a.read).length;
      });
    } on ApiException {
      if (mounted) setState(() => _alerts = const []);
    }
  }

  Future<void> _loadComplaints() async {
    setState(() => _complaintsError = null);
    try {
      final complaints = await _api.listComplaints();
      if (mounted) setState(() => _complaints = complaints);
    } on ApiException catch (e) {
      if (mounted) setState(() => _complaintsError = e.message);
    }
  }

  Future<void> _refreshHome() async {
    final device = _device;
    if (device == null) {
      await _loadDevices();
    } else {
      await _loadStatusFor(device.deviceId);
    }
  }

  void _selectDevice(int index) {
    final devices = _devices;
    if (devices == null || index < 0 || index >= devices.length) return;
    setState(() => _selected = index);
    _bluetooth.value = BluetoothLink.off;
    final id = devices[index].deviceId;
    if (!_statusById.containsKey(id)) _loadStatusFor(id);
  }

  // ── Pump control ─────────────────────────────────────────────────────────

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestCommand(PumpCommand command) async {
    final device = _device;
    if (device == null) return;
    final confirmed = await confirmPumpCommand(
      context,
      command: command,
      deviceName: device.deviceUid,
      status: _statusById[device.deviceId],
      isDemo: widget.services.isMock,
    );
    if (!confirmed || !mounted) return;
    await _sendCommand(device.deviceId, command);
  }

  Future<void> _sendCommand(String deviceId, PumpCommand command) async {
    setState(() => _pendingById[deviceId] = command);
    try {
      await _api.sendPumpCommand(deviceId, command);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _pendingById.remove(deviceId));
      _snack(e.message);
      return;
    }
    if (!mounted) return;

    // The pump is only "running" once it says so itself. Check until it
    // confirms, or give up and say so plainly.
    final expected = command == PumpCommand.start ? 'RUNNING' : 'STOPPED';
    final startedAt = DateTime.now();
    _confirmTimer?.cancel();
    _confirmTimer = Timer.periodic(widget.confirmPollInterval, (timer) async {
      if (_confirmPolling) return;
      _confirmPolling = true;
      try {
        final status = await _api.getDeviceStatus(deviceId);
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _statusById[deviceId] = status);
        if (status.runStatus == expected) {
          timer.cancel();
          setState(() => _pendingById.remove(deviceId));
          _snack(command == PumpCommand.start ? 'Pump started' : 'Pump stopped');
          return;
        }
      } on ApiException {
        // Keep trying until the timeout.
      } finally {
        _confirmPolling = false;
      }
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (DateTime.now().difference(startedAt) >= widget.confirmTimeout) {
        timer.cancel();
        setState(() => _pendingById.remove(deviceId));
        _snack("The pump didn't confirm. Check it has power, then try again.");
      }
    });
  }

  // ── Bluetooth (simulated) ────────────────────────────────────────────────

  Future<void> _connectBluetooth() async {
    _bluetooth.value = BluetoothLink.searching;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted && _bluetooth.value == BluetoothLink.searching) {
      _bluetooth.value = BluetoothLink.connected;
    }
  }

  void _openBluetooth() {
    final device = _device;
    if (device == null) return;
    showBluetoothSheet(
      context,
      link: _bluetooth,
      deviceName: device.deviceUid,
      onConnect: _connectBluetooth,
      onDisconnect: () => _bluetooth.value = BluetoothLink.off,
      isDemo: widget.services.isMock,
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _setRoute(HomeRoute route) => setState(() => _route = route);

  void _goToTab(HomeNavTab tab) => setState(() {
        _route = const TabsRoute();
        _tab = tab;
      });

  void _openAlerts() {
    _setRoute(const AlertsRoute());
    setState(() => _unreadAlerts = 0);
  }

  void _openNewComplaint() {
    final device = _device;
    if (device == null) {
      _snack('Add a pump first, then you can raise a complaint about it.');
      return;
    }
    _setRoute(NewComplaintRoute(device));
  }

  void _openDeviceSwitcher() {
    final devices = _devices ?? const <MyDevice>[];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ClaroColors.inkPanel,
      shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.sheet),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.lg, ClaroSpacing.lg, ClaroSpacing.lg, ClaroSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm),
                child: Text('Your devices', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
              ),
              const SizedBox(height: ClaroSpacing.md),
              for (var i = 0; i < devices.length; i++)
                ListTile(
                  shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.md),
                  leading: Icon(
                    DeviceKind.from(devices[i].kind) == DeviceKind.inverter
                        ? Icons.solar_power_rounded
                        : Icons.water_drop_rounded,
                    color: ClaroColors.mint,
                  ),
                  title: Text(deviceTitle(devices[i]), style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
                  subtitle: Text(
                    devices[i].deviceUid,
                    style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                  ),
                  trailing: i == _selected ? const Icon(Icons.check_circle_rounded, color: ClaroColors.mint) : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _selectDevice(i);
                  },
                ),
              const Divider(color: ClaroColors.borderDark),
              ListTile(
                shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.md),
                leading: const Icon(Icons.add_circle_outline_rounded, color: ClaroColors.mint),
                title: Text('Add a device', style: ClaroType.subtitle.copyWith(color: ClaroColors.mint)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _setRoute(const QrScanRoute());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Android's back button closes a page instead of leaving the app.
  void _back() {
    switch (_route) {
      case ManualEntryRoute():
        _setRoute(const QrScanRoute());
      case TabsRoute():
        if (_tab != HomeNavTab.home) _goToTab(HomeNavTab.home);
      default:
        _setRoute(const TabsRoute());
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _route is TabsRoute && _tab == HomeNavTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: switch (_route) {
        QrScanRoute() => QrScannerScreen(
            onScanned: (value) => _setRoute(ClaimConfirmRoute(scannedValue: value, enteredManually: false)),
            onEnterManually: () => _setRoute(const ManualEntryRoute()),
            onClose: () => _setRoute(const TabsRoute()),
          ),
        ManualEntryRoute() => ManualDeviceEntryScreen(
            onSubmit: (value) => _setRoute(ClaimConfirmRoute(scannedValue: value, enteredManually: true)),
            onBack: () => _setRoute(const QrScanRoute()),
          ),
        ClaimConfirmRoute(:final scannedValue, :final enteredManually) => DeviceClaimScreen(
            scannedValue: scannedValue,
            enteredManually: enteredManually,
            api: _api,
            onSubmitted: () {
              _goToTab(HomeNavTab.home);
              _loadDevices();
            },
            onBack: () => _setRoute(const TabsRoute()),
          ),
        PumpDetailsRoute(:final device) => PumpDetailsScreen(
            device: device,
            api: _api,
            onBack: () => _setRoute(const TabsRoute()),
          ),
        AlertsRoute() => NotificationsScreen(
            notifications: _alerts,
            onBack: () => _setRoute(const TabsRoute()),
          ),
        NewComplaintRoute(:final device) => NewComplaintScreen(
            device: device,
            api: _api,
            onSubmitted: () {
              _goToTab(HomeNavTab.complaints);
              _loadComplaints();
            },
            onBack: () => _setRoute(const TabsRoute()),
          ),
        TabsRoute() => _tabs(),
      },
    );
  }

  Widget _tabs() {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: _tabBody(),
      bottomNavigationBar: _BottomNav(selected: _tab, onSelect: (tab) => setState(() => _tab = tab)),
    );
  }

  Widget _tabBody() {
    final device = _device;
    switch (_tab) {
      case HomeNavTab.home:
        final status = device == null ? null : _statusById[device.deviceId];
        final pending = device == null ? null : _pendingById[device.deviceId];
        return HomeDashboard(
          devices: _devices,
          devicesError: _devicesError,
          claims: _claims,
          device: device,
          status: status,
          statusError: device == null ? null : _statusErrorById[device.deviceId],
          visual: device == null
              ? PumpVisual.checking
              : pumpVisualFor(kind: DeviceKind.from(device.kind), status: status, pending: pending),
          unreadAlerts: _unreadAlerts,
          bluetooth: _bluetooth,
          onRefresh: _refreshHome,
          onRetryDevices: _loadDevices,
          onRetryStatus: () {
            if (device != null) _loadStatusFor(device.deviceId);
          },
          onAddDevice: () => _setRoute(const QrScanRoute()),
          onSwitchDevice: _openDeviceSwitcher,
          onOpenDetails: () {
            if (device != null) _setRoute(PumpDetailsRoute(device));
          },
          onOpenAlerts: _openAlerts,
          onOpenBluetooth: _openBluetooth,
          onStart: () => _requestCommand(PumpCommand.start),
          onStop: () => _requestCommand(PumpCommand.stop),
        );
      case HomeNavTab.usage:
        return UsageTab(
          key: ValueKey(device?.deviceId),
          device: device,
          api: _api,
          onAddDevice: () => _setRoute(const QrScanRoute()),
        );
      case HomeNavTab.complaints:
        return ComplaintsTab(
          complaints: _complaints,
          error: _complaintsError,
          onRetry: _loadComplaints,
          onRaise: _openNewComplaint,
          onRefresh: _loadComplaints,
        );
      case HomeNavTab.profile:
        return ProfileTab(
          phone: widget.services.tokenStore.phone,
          deviceCount: _devices?.length ?? 0,
          isDemo: widget.services.isMock,
          onOpenDevices: () {
            _goToTab(HomeNavTab.home);
            if ((_devices ?? const []).isNotEmpty) _openDeviceSwitcher();
          },
          onOpenComplaints: () => _goToTab(HomeNavTab.complaints),
          onLogout: widget.onLogout,
        );
    }
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, required this.onSelect});

  final HomeNavTab selected;
  final ValueChanged<HomeNavTab> onSelect;

  static const _items = [
    (HomeNavTab.home, Icons.home_rounded, 'Home'),
    (HomeNavTab.usage, Icons.insights_rounded, 'Usage'),
    (HomeNavTab.complaints, Icons.support_agent_rounded, 'Complaints'),
    (HomeNavTab.profile, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClaroColors.inkPanel,
        border: const Border(top: BorderSide(color: ClaroColors.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: ClaroSpacing.sm),
          child: Row(
            children: [
              for (final (tab, icon, label) in _items)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(tab),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: ClaroMotion.fast,
                            padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: 4),
                            decoration: BoxDecoration(
                              color: tab == selected
                                  ? ClaroColors.mint.withValues(alpha: 0.16)
                                  : const Color(0x00000000),
                              borderRadius: ClaroRadius.pill,
                            ),
                            child: Icon(
                              icon,
                              size: 22,
                              color: tab == selected ? ClaroColors.mint : ClaroColors.onInkMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: ClaroType.caption.copyWith(
                              color: tab == selected ? ClaroColors.mint : ClaroColors.onInkMuted,
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
    );
  }
}
