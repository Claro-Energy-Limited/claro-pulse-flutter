import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_theme.dart';
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
import '../usage/monthly_report_screen.dart';
import '../usage/usage_tab.dart';
import 'home_dashboard.dart';
import 'pump_control.dart';
import 'pump_state.dart';
import 'run_story.dart';

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

class MonthlyReportRoute extends HomeRoute {
  const MonthlyReportRoute(this.device);

  final MyDevice device;
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
  final Map<String, List<PumpRun>> _runsById = {};
  final Map<String, PumpInsights> _insightsById = {};

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
      if (_route is TabsRoute && _tab == HomeNavTab.home) {
        _loadStatusFor(device.deviceId, quiet: true);
        _loadRunsFor(device.deviceId);
      }
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

  /// Runs and insights are extras: if they can't load, their cards simply
  /// don't show. They never turn Home into an error.
  Future<void> _loadRunsFor(String deviceId) async {
    try {
      final runs = await _api.listRecentRuns(deviceId);
      if (mounted) setState(() => _runsById[deviceId] = runs);
    } on ApiException {
      if (mounted) setState(() => _runsById.remove(deviceId));
    }
  }

  Future<void> _loadInsightsFor(String deviceId) async {
    try {
      final insights = await _api.getInsights(deviceId);
      if (mounted) setState(() => _insightsById[deviceId] = insights);
    } on ApiException {
      if (mounted) setState(() => _insightsById.remove(deviceId));
    }
  }

  void _loadExtrasFor(String deviceId) {
    _loadRunsFor(deviceId);
    _loadInsightsFor(deviceId);
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
        _loadExtrasFor(device.deviceId);
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
      _loadExtrasFor(device.deviceId);
      await _loadStatusFor(device.deviceId);
    }
  }

  void _selectDevice(int index) {
    final devices = _devices;
    if (devices == null || index < 0 || index >= devices.length) return;
    setState(() => _selected = index);
    _bluetooth.value = BluetoothLink.off;
    final id = devices[index].deviceId;
    if (!_statusById.containsKey(id)) {
      _loadStatusFor(id);
      _loadExtrasFor(id);
    }
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
          if (command == PumpCommand.start) _snack('Pump started');
          await _loadRunsFor(deviceId);
          if (!mounted) return;
          if (command == PumpCommand.stop) {
            // A finished run gets its moment: the run story says it all.
            // Without a run to show, a short message confirms the stop.
            final run = _runsById[deviceId]?.firstOrNull;
            if (run != null && !run.isOngoing) {
              _openRunStory(run);
            } else {
              _snack('Pump stopped');
            }
          }
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

  void _openRunStory(PumpRun run) {
    final device = _device;
    showRunStory(context, run: run, deviceName: device?.deviceUid ?? 'Your pump');
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
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.panel,
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
                child: Text('Your devices', style: ClaroType.title.copyWith(color: p.text)),
              ),
              const SizedBox(height: ClaroSpacing.md),
              for (var i = 0; i < devices.length; i++)
                ListTile(
                  shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.md),
                  leading: Icon(
                    DeviceKind.from(devices[i].kind) == DeviceKind.inverter
                        ? Icons.solar_power_rounded
                        : Icons.water_drop_rounded,
                    color: p.accentText,
                  ),
                  title: Text(deviceTitle(devices[i]), style: ClaroType.subtitle.copyWith(color: p.text)),
                  subtitle: Text(
                    devices[i].deviceUid,
                    style: ClaroType.caption.copyWith(color: p.textMuted),
                  ),
                  trailing: i == _selected ? Icon(Icons.check_circle_rounded, color: p.accentText) : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _selectDevice(i);
                  },
                ),
              Divider(color: p.border),
              ListTile(
                shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.md),
                leading: Icon(Icons.add_circle_outline_rounded, color: p.accentText),
                title: Text('Add a device', style: ClaroType.subtitle.copyWith(color: p.accentText)),
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
      case MonthlyReportRoute():
        _goToTab(HomeNavTab.usage);
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
      child: AnimatedSwitcher(
        duration: ClaroMotion.base,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_route.runtimeType), child: _page()),
      ),
    );
  }

  Widget _page() {
    return switch (_route) {
        // Adding a device is a camera-first flow, designed dark: it stays
        // dark in both themes.
        QrScanRoute() => _dark(QrScannerScreen(
            onScanned: (value) => _setRoute(ClaimConfirmRoute(scannedValue: value, enteredManually: false)),
            onEnterManually: () => _setRoute(const ManualEntryRoute()),
            onClose: () => _setRoute(const TabsRoute()),
          )),
        ManualEntryRoute() => _dark(ManualDeviceEntryScreen(
            onSubmit: (value) => _setRoute(ClaimConfirmRoute(scannedValue: value, enteredManually: true)),
            onBack: () => _setRoute(const QrScanRoute()),
          )),
        ClaimConfirmRoute(:final scannedValue, :final enteredManually) => _dark(DeviceClaimScreen(
            scannedValue: scannedValue,
            enteredManually: enteredManually,
            api: _api,
            onSubmitted: () {
              _goToTab(HomeNavTab.home);
              _loadDevices();
            },
            onBack: () => _setRoute(const TabsRoute()),
          )),
        MonthlyReportRoute(:final device) => MonthlyReportScreen(
            device: device,
            api: _api,
            onBack: () => _goToTab(HomeNavTab.usage),
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
      };
  }

  Widget _dark(Widget child) => Theme(data: ClaroTheme.dark, child: child);

  Widget _tabs() {
    return Scaffold(
      backgroundColor: context.palette.bg,
      extendBody: true,
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
          runs: device == null ? null : _runsById[device.deviceId],
          insights: device == null ? null : _insightsById[device.deviceId],
          complaintUpdate: _complaints
              ?.where((c) => c.latestUpdate != null && c.status != ComplaintStatus.resolved)
              .firstOrNull,
          onSeeAllRuns: () => _goToTab(HomeNavTab.usage),
          onOpenRunStory: _openRunStory,
          onOpenComplaints: () => _goToTab(HomeNavTab.complaints),
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
          onOpenReport: () {
            if (device != null) _setRoute(MonthlyReportRoute(device));
          },
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
          settings: widget.services.settings,
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
    final p = context.palette;
    const radius = BorderRadius.all(Radius.circular(28));
    // A floating, slightly see-through bar: content scrolls softly underneath.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: ClaroSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xs, vertical: ClaroSpacing.sm),
              decoration: BoxDecoration(
                color: p.panel.withValues(alpha: p.isDark ? 0.82 : 0.88),
                borderRadius: radius,
                border: Border.all(color: p.border),
              ),
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
                                      ? p.accent.withValues(alpha: p.isDark ? 0.18 : 0.32)
                                      : const Color(0x00000000),
                                  borderRadius: ClaroRadius.pill,
                                ),
                                child: Icon(icon, size: 22, color: tab == selected ? p.accentText : p.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClaroType.caption.copyWith(
                                  color: tab == selected ? p.accentText : p.textMuted,
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
      ),
    );
  }
}
