part of '../../prayers.dart';

enum DashboardStatus { loading, ready, locationRequired, error }

class DashboardController extends GetxController with WidgetsBindingObserver {
  DashboardController(this.prepare, this.clock, {this.onExit})
    : selectedDate = PreparePrayerDashboard.day(clock.now()).obs,
      now = clock.now().obs;
  final PreparePrayerDashboard prepare;
  final DashboardClock clock;
  final void Function()? onExit;
  void leaveScreen() => onExit?.call();
  final Rx<DateTime> selectedDate;
  final Rx<DateTime> now;
  final data = Rxn<DashboardData>();
  final countdown = Rxn<PrayerCountdown>();
  final status = DashboardStatus.loading.obs;
  final refreshingLocation = false.obs;
  final locationFailed = false.obs;
  StreamSubscription<void>? _changes;
  StreamSubscription<DateTime>? _ticks;
  int _request = 0;
  bool _visible = true;
  bool _resumed = true;
  bool _countdownVisible = false;
  Worker? _layoutWorker;

  bool get canGoBack => selectedDate.value.isAfter(
    PreparePrayerDashboard.shiftDay(now.value, -7),
  );
  bool get canGoForward => selectedDate.value.isBefore(
    PreparePrayerDashboard.shiftDay(now.value, 7),
  );

  void attachLayoutWorker(Worker worker) => _layoutWorker = worker;
  void setCountdownVisible(bool visible) {
    _countdownVisible = visible;
    _updateTicker();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _changes = prepare.repository.changes.listen((_) {
      if (_visible && _resumed) unawaited(reload());
    });
    _updateTicker();
    unawaited(reload());
  }

  void setVisible(bool visible) {
    _visible = visible;
    _updateTicker();
    if (visible) {
      _advanceDay(clock.now());
      unawaited(reload());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _updateTicker();
    if (_resumed && _visible) {
      _advanceDay(clock.now());
      unawaited(reload());
    }
  }

  void _updateTicker() {
    _ticks?.cancel();
    _ticks = null;
    if (!_visible || !_resumed || isClosed) return;
    // A single subscription belongs to the controller. No timer in any view.
    _ticks = clock
        .ticks(
          _countdownVisible
              ? const Duration(seconds: 1)
              : const Duration(minutes: 1),
        )
        .listen((time) {
          final oldNow = now.value;
          final dayChanged = !PreparePrayerDashboard.sameDay(time, oldNow);
          final minuteChanged =
              time.minute != oldNow.minute ||
              time.difference(oldNow).abs() >= const Duration(minutes: 1);
          _advanceDay(time);
          if (minuteChanged || dayChanged) {
            now.value = time;
          }
          _updateCountdown(time);
          if (dayChanged || minuteChanged) unawaited(reload());
        });
  }

  void _advanceDay(DateTime time) {
    if (!PreparePrayerDashboard.sameDay(time, now.value)) {
      selectedDate.value =
          PreparePrayerDashboard.sameDay(selectedDate.value, now.value)
          ? PreparePrayerDashboard.day(time)
          : PreparePrayerDashboard.constrainDate(selectedDate.value, time);
    }
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = PreparePrayerDashboard.constrainDate(
      date,
      clock.now(),
    );
    await reload();
  }

  void previousDay() => unawaited(
    selectDate(PreparePrayerDashboard.shiftDay(selectedDate.value, -1)),
  );
  void nextDay() => unawaited(
    selectDate(PreparePrayerDashboard.shiftDay(selectedDate.value, 1)),
  );
  void today() => unawaited(selectDate(clock.now()));

  Future<void> reload() async {
    final request = ++_request;
    final availability = prepare.repository.availability;
    if (availability != DashboardAvailability.ready) {
      status.value = availability == DashboardAvailability.locationRequired
          ? DashboardStatus.locationRequired
          : DashboardStatus.loading;
      data.value = null;
      countdown.value = null;
      return;
    }
    if (data.value == null ||
        !PreparePrayerDashboard.sameDay(data.value!.date, selectedDate.value)) {
      status.value = DashboardStatus.loading;
    }
    try {
      final loaded = await prepare.load(selectedDate.value, clock.now());
      if (isClosed || request != _request) return;
      data.value = loaded;
      now.value = clock.now();
      _updateCountdown();
      status.value = DashboardStatus.ready;
    } catch (_) {
      if (!isClosed && request == _request) {
        status.value = DashboardStatus.error;
      }
    }
  }

  void _updateCountdown([DateTime? time]) {
    countdown.value = data.value == null
        ? null
        : PreparePrayerDashboard.countdown(
            data.value!.liveTimes,
            time ?? now.value,
          );
  }

  Future<void> updateLocation() async {
    if (refreshingLocation.value) return;
    refreshingLocation.value = true;
    locationFailed.value = false;
    try {
      await prepare.repository.updateLocation();
      if (!isClosed) await reload();
    } catch (_) {
      if (!isClosed) locationFailed.value = true;
    } finally {
      if (!isClosed) refreshingLocation.value = false;
    }
  }

  @override
  void onClose() {
    _request++;
    _ticks?.cancel();
    _changes?.cancel();
    _layoutWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
