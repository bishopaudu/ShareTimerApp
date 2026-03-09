import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timer_model.dart';
import '../viewmodels/timer_viewmodel.dart';
import '../viewmodels/participant_viewmodel.dart';
import '../viewmodels/shared_alarm_viewmodel.dart';
import 'widgets/custom_loader.dart';
import 'create_timer_screen.dart';
import 'join_timer_screen.dart';
import 'timer_detail_screen.dart';
import 'create_shared_alarm_screen.dart';
import 'join_shared_alarm_screen.dart';
import 'shared_alarm_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigateToCreateTimer() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
  );

  void _navigateToCreateSharedAlarm() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateSharedAlarmScreen()),
  );

  void _navigateToTimerDetail(String timerId) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TimerDetailScreen(timerId: timerId)),
  );

  void _navigateToSettings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );

  void _showJoinSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinBottomSheet(),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, _) => [_buildSliverHeader(colorScheme)],
        body: Column(
          children: [
            // ── Quick-action cards ──────────────────────────────────────────
            _QuickActionRow(
              onNewTimer: _navigateToCreateTimer,
              onNewAlarm: _navigateToCreateSharedAlarm,
            ),

            // ── Tab bar ─────────────────────────────────────────────────────
            _buildTabBar(colorScheme),

            // ── Tab content ─────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TimerTab(onTimerTap: _navigateToTimerDetail),
                  _AlarmTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _JoinFAB(onTap: _showJoinSheet),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildSliverHeader(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: _HeaderBackground(onSettingsTap: _navigateToSettings),
        collapseMode: CollapseMode.pin,
      ),
      // Collapsed state is just the gradient bar — no title needed,
      // quick-action cards are always visible below.
      title: null,
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'MY TIMERS'),
          Tab(text: 'SHARED ALARMS'),
        ],
      ),
    );
  }
}

// ── Header Background ─────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final VoidCallback onSettingsTap;
  const _HeaderBackground({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, const Color(0xFF9C27B0)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Greeting
              Expanded(
                child: Consumer<ParticipantViewModel>(
                  builder: (context, vm, _) {
                    final name =
                        vm.userProfile?.displayName.split(' ').first ?? 'there';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Avatar / Settings button
              Consumer<ParticipantViewModel>(
                builder: (context, vm, _) {
                  return GestureDetector(
                    onTap: onSettingsTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          vm.userProfile?.emoji ?? '👤',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Quick-action row ──────────────────────────────────────────────────────────

class _QuickActionRow extends StatelessWidget {
  final VoidCallback onNewTimer;
  final VoidCallback onNewAlarm;

  const _QuickActionRow({required this.onNewTimer, required this.onNewAlarm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              label: 'New Timer',
              icon: Icons.timer_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: onNewTimer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              label: 'New Alarm',
              icon: Icons.alarm_add_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: onNewAlarm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timer tab ─────────────────────────────────────────────────────────────────

class _TimerTab extends StatelessWidget {
  final void Function(String timerId) onTimerTap;
  const _TimerTab({required this.onTimerTap});

  @override
  Widget build(BuildContext context) {
    final participantViewModel = context.watch<ParticipantViewModel>();
    final timerViewModel = context.read<TimerViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final createdIds = participantViewModel.createdTimerIds.take(3).toList();
    final joinedIds = participantViewModel.joinedTimerIds.take(3).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context: context,
            title: 'Created by You',
            subtitle: 'Timers you started',
            ids: createdIds,
            viewModel: timerViewModel,
            onTap: onTimerTap,
            accent: colorScheme.primary,
            sectionIcon: Icons.timer_rounded,
            emptyIcon: Icons.timer_outlined,
            emptyTitle: 'No Created Timers Yet',
            emptySubtitle: 'Tap "New Timer" above to get started.',
            isJoined: false,
          ),
          const SizedBox(height: 28),
          _buildSection(
            context: context,
            title: 'Recently Joined',
            subtitle: 'Timers from others',
            ids: joinedIds,
            viewModel: timerViewModel,
            onTap: onTimerTap,
            accent: const Color(0xFF00897B),
            sectionIcon: Icons.group_rounded,
            emptyIcon: Icons.group_add_outlined,
            emptyTitle: 'Not Joined Any Timers',
            emptySubtitle: 'Press JOIN below to enter a share code.',
            isJoined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<String> ids,
    required TimerViewModel viewModel,
    required void Function(String) onTap,
    required Color accent,
    required IconData sectionIcon,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required bool isJoined,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(sectionIcon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (ids.length >= 3)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Full history coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'See all',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (ids.isEmpty)
          _buildEmptyCard(
            emptyIcon: emptyIcon,
            emptyTitle: emptyTitle,
            emptySubtitle: emptySubtitle,
            accent: accent,
          )
        else
          FutureBuilder<List<TimerModel>>(
            future: viewModel.getTimersByIds(ids),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accent,
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return _buildEmptyCard(
                  emptyIcon: emptyIcon,
                  emptyTitle: emptyTitle,
                  emptySubtitle: emptySubtitle,
                  accent: accent,
                );
              }
              final timers = snapshot.data!;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      for (int i = 0; i < timers.length; i++) ...[
                        _HistoryListTile(
                          timer: timers[i],
                          accent: accent,
                          isJoined: isJoined,
                          onTap: () => onTap(timers[i].id),
                        ),
                        if (i < timers.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 72,
                            color: Colors.grey[100],
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyCard({
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.08), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(emptyIcon, color: accent.withOpacity(0.5), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emptyTitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  emptySubtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── History list tile ─────────────────────────────────────────────────────────

class _HistoryListTile extends StatelessWidget {
  final TimerModel timer;
  final Color accent;
  final bool isJoined;
  final VoidCallback onTap;

  const _HistoryListTile({
    required this.timer,
    required this.accent,
    required this.isJoined,
    required this.onTap,
  });

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = DateTime.now().isAfter(timer.endTime);
    final statusColor = isFinished ? Colors.grey[400]! : accent;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Gradient icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isFinished
                    ? null
                    : LinearGradient(
                        colors: [accent, accent.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isFinished ? Colors.grey[100] : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isFinished
                    ? []
                    : [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                isJoined ? Icons.group_rounded : Icons.timer_rounded,
                color: isFinished ? Colors.grey[400] : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDuration(timer.durationSeconds),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(timer.createdAt),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFinished ? 'Done' : 'Live',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[300],
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alarm tab ─────────────────────────────────────────────────────────────────

class _AlarmTab extends StatelessWidget {
  const _AlarmTab();

  @override
  Widget build(BuildContext context) {
    final participantViewModel = Provider.of<ParticipantViewModel>(
      context,
      listen: false,
    );
    final alarmViewModel = Provider.of<SharedAlarmViewModel>(
      context,
      listen: false,
    );
    final userId = participantViewModel.getUserId();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: alarmViewModel.getUserSharedAlarms(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoader(label: 'Loading alarms…'));
        }
        if (snapshot.hasError) {
          return _ErrorState(message: 'Could not load your alarms.');
        }

        final alarms = snapshot.data ?? [];

        if (alarms.isEmpty) {
          return _EmptyState(
            icon: Icons.alarm_add_rounded,
            title: 'No Shared Alarms',
            subtitle: 'Tap "New Alarm" above to set one up!',
            iconColor: colorScheme.secondary,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: alarms.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final alarm = alarms[index];
            final triggerStr = alarm.triggerTime
                .toLocal()
                .toString()
                .split('.')
                .first;
            return _AlarmListCard(
              title: alarm.title,
              triggerTime: triggerStr,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharedAlarmDetailsScreen(alarmId: alarm.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AlarmListCard extends StatelessWidget {
  final String title;
  final String triggerTime;
  final VoidCallback onTap;

  const _AlarmListCard({
    required this.title,
    required this.triggerTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.alarm, color: colorScheme.secondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Triggers: $triggerTime',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Join FAB ──────────────────────────────────────────────────────────────────

class _JoinFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _JoinFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      heroTag: 'join_fab',
      onPressed: onTap,
      backgroundColor: colorScheme.secondary,
      icon: const Icon(Icons.login_rounded, color: Colors.white),
      label: Text(
        'JOIN',
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Join bottom sheet ─────────────────────────────────────────────────────────

class _JoinBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Join with a Code',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose what you want to join.',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            _JoinOption(
              icon: Icons.timer_rounded,
              label: 'Join Shared Timer',
              color: colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const JoinTimerScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _JoinOption(
              icon: Icons.alarm_rounded,
              label: 'Join Shared Alarm',
              color: colorScheme.secondary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => const JoinSharedAlarmScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _JoinOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1D1D1D),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
