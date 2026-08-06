import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/events/data/repositories/activity_repository.dart';
import 'package:manager_connect/features/events/presentation/providers/activities_provider.dart';
import 'package:manager_connect/features/feed/data/repositories/feed_repository.dart';
import 'package:manager_connect/features/feed/presentation/providers/feed_provider.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

String _toTitleCase(String raw) => raw
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _titleController    = TextEditingController();
  final _descController     = TextEditingController();
  final _locationController = TextEditingController();
  final _costController     = TextEditingController();
  final _locationFocusNode  = FocusNode();
  String  _category  = 'outings';
  String? _eventType;
  DateTime? _eventDate;
  bool _submitting = false;
  List<String> _locationSuggestions = [];
  bool _loadingLocations = false;
  Timer? _locationDebounce;

  static const _categories = {
    'games':          'Games',
    'outings':        'Outings',
    'social_connect': 'Social Connect',
  };

  static const _eventTypes = {
    'games':          ['cricket', 'badminton', 'pickleball', 'table_tennis', 'other'],
    'social_connect': ['coffee_connect', 'lunch_meetup', 'dinner_meetup', 'other'],
  };

  static const _categoryIcons = {
    'games':          Icons.sports_cricket,
    'outings':        Icons.hiking,
    'social_connect': Icons.coffee,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _costController.dispose();
    _locationFocusNode.dispose();
    _locationDebounce?.cancel();
    super.dispose();
  }

  void _onLocationChanged(String query) {
    _locationDebounce?.cancel();
    if (query.trim().length < 3) {
      if (_locationSuggestions.isNotEmpty) {
        setState(() => _locationSuggestions = []);
      }
      return;
    }
    _locationDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchLocationSuggestions(query.trim());
    });
  }

  Future<void> _fetchLocationSuggestions(String query) async {
    if (!mounted) return;
    setState(() => _loadingLocations = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=6&addressdetails=0',
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ManagerConnect/1.0',
        },
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _locationSuggestions = data
              .map((item) => (item as Map<String, dynamic>)['display_name'] as String)
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _locationSuggestions = []);
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  void _selectLocation(String name) {
    setState(() {
      _locationController.text = name;
      _locationSuggestions = [];
      _loadingLocations = false;
    });
    _locationDebounce?.cancel();
    _locationFocusNode.unfocus();
  }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate:   now,
      lastDate:    now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _eventDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      showErrorToast(context, 'Title is required');
      return;
    }
    if (_eventDate == null) {
      showErrorToast(context, 'Date and time are required');
      return;
    }
    final authState = ref.read(authProvider);
    if (authState is! AppAuthStateAuthenticated) return;

    setState(() => _submitting = true);
    try {
      final client   = ref.read(supabaseClientProvider);
      final actRepo  = ActivityRepository(client);
      final feedRepo = FeedRepository(client);

      // 1. Create the activity
      final activity = await actRepo.createActivity(
        createdBy:     authState.session.userId,
        title:         _titleController.text.trim(),
        description:   _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        eventCategory: _category,
        eventType:     _eventType,
        location:      _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        eventDate:     _eventDate!,
        costNote:      _costController.text.trim().isNotEmpty
            ? _costController.text.trim()
            : null,
      );

      // 2. Auto-post a feed poll linked to this activity
      final daysUntil = _eventDate!.difference(DateTime.now()).inDays.clamp(1, 365);
      await feedRepo.createPollPost(
        userId:     authState.session.userId,
        question:   '📅 ${activity.title} — Are you joining?',
        options:    ['Available', 'Maybe', 'Not Available'],
        closesInDays: daysUntil,
        activityId: activity.id,
      );

      await Future.wait([
        ref.read(activitiesProvider.notifier).refresh(),
        ref.read(feedProvider.notifier).refresh(),
      ]);

      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Event created & posted to feed!');
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to create event');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: const BoxDecoration(
                color: MCColors.card,
                border: Border(bottom: BorderSide(color: MCColors.borderLight)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    color: MCColors.textPrimary,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Create Event', style: MCTypography.h3),
                      Text('Schedule an activity', style: MCTypography.caption),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: MCColors.primaryMid,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusPill),
                        boxShadow: MCColors.primaryButtonShadow,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create',
                              style: MCTypography.labelSm
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MCSpacing.pageH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Navy hero banner ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E4585), Color(0xFF1A3A6B)],
                        ),
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.event,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Team Event',
                                    style: MCTypography.h4
                                        .copyWith(color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(
                                  'Visible to all community members',
                                  style: MCTypography.caption.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Title ─────────────────────────────────────────
                    Text('Event title *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    MCInput(
                      controller: _titleController,
                      hint: 'Give your event a name',
                      prefixIcon: Icons.title,
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Category ──────────────────────────────────────
                    Text('Category *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    Row(
                      children: _categories.entries.map((e) {
                        final sel = _category == e.key;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: e.key != 'social_connect' ? 8 : 0,
                            ),
                            child: GestureDetector(
                              onTap: _submitting
                                  ? null
                                  : () => setState(() {
                                        _category  = e.key;
                                        _eventType = null;
                                      }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? MCColors.primaryPale
                                      : MCColors.card,
                                  borderRadius: BorderRadius.circular(
                                      MCSpacing.radiusSm),
                                  border: Border.all(
                                    color: sel
                                        ? MCColors.primaryMid
                                        : MCColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _categoryIcons[e.key],
                                      size: 22,
                                      color: sel
                                          ? MCColors.primaryMid
                                          : MCColors.textMuted,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.value,
                                      textAlign: TextAlign.center,
                                      style: MCTypography.labelSm.copyWith(
                                        color: sel
                                            ? MCColors.primaryMid
                                            : MCColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Event type (conditional) ───────────────────────
                    if (_eventTypes.containsKey(_category)) ...[
                      Text('Event type', style: MCTypography.h4),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _eventTypes[_category]!.map((t) {
                          final sel   = _eventType == t;
                          final label = _toTitleCase(t);
                          return GestureDetector(
                            onTap: _submitting
                                ? null
                                : () => setState(() => _eventType = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                // Selected: solid primary fill; unselected: tinted bg
                                color: sel
                                    ? MCColors.primaryMid
                                    : MCColors.primaryPale.withValues(
                                        alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                    MCSpacing.radiusPill),
                                border: Border.all(
                                  color: sel
                                      ? MCColors.primaryMid
                                      : MCColors.primary
                                          .withValues(alpha: 0.3),
                                  width: sel ? 0 : 1,
                                ),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: MCColors.primaryMid
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                label,
                                style: MCTypography.labelSm.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : MCColors.primary,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: MCSpacing.lg),
                    ],

                    // ── Date & time ───────────────────────────────────
                    Text('Date & time *', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _submitting ? null : _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: MCColors.card,
                          borderRadius: BorderRadius.circular(
                              MCSpacing.radiusInput),
                          border: Border.all(color: MCColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: MCColors.primaryMid),
                            const SizedBox(width: 10),
                            Text(
                              _eventDate == null
                                  ? 'Pick date & time'
                                  : DateFormat('EEE, MMM d · h:mm a')
                                      .format(_eventDate!),
                              style: MCTypography.body.copyWith(
                                color: _eventDate == null
                                    ? MCColors.textMuted
                                    : MCColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                size: 18, color: MCColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Location ──────────────────────────────────────
                    Text('Location', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: MCColors.card,
                        borderRadius: _locationSuggestions.isNotEmpty || _loadingLocations
                            ? const BorderRadius.vertical(
                                top: Radius.circular(MCSpacing.radiusInput))
                            : BorderRadius.circular(MCSpacing.radiusInput),
                        border: Border.all(color: MCColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 14),
                                child: Icon(Icons.location_on,
                                    size: 20, color: Colors.redAccent),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _locationController,
                                  focusNode: _locationFocusNode,
                                  enabled: !_submitting,
                                  onChanged: _onLocationChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Search for a place…',
                                    hintStyle: MCTypography.body
                                        .copyWith(color: MCColors.textMuted),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                  ),
                                  style: MCTypography.body,
                                  textCapitalization:
                                      TextCapitalization.none,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _loadingLocations
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              MCColors.primaryMid),
                                        ),
                                      )
                                    : const Icon(Icons.search,
                                        size: 18, color: MCColors.textMuted),
                              ),
                            ],
                          ),
                          if (_locationSuggestions.isEmpty && !_loadingLocations)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF6FF),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(MCSpacing.radiusInput - 1),
                                  bottomRight: Radius.circular(MCSpacing.radiusInput - 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 13,
                                      color: MCColors.primaryMid),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Type 3+ characters to search places',
                                    style: MCTypography.caption.copyWith(
                                        color: MCColors.primaryMid),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Suggestions dropdown
                    if (_locationSuggestions.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: MCColors.card,
                          border: const Border(
                            left: BorderSide(color: MCColors.border),
                            right: BorderSide(color: MCColors.border),
                            bottom: BorderSide(color: MCColors.border),
                          ),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(MCSpacing.radiusInput)),
                          boxShadow: MCColors.cardShadow,
                        ),
                        child: Column(
                          children: _locationSuggestions.asMap().entries.map((entry) {
                            final isLast = entry.key == _locationSuggestions.length - 1;
                            return InkWell(
                              onTap: () => _selectLocation(entry.value),
                              borderRadius: isLast
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(MCSpacing.radiusInput))
                                  : BorderRadius.zero,
                              child: Column(
                                children: [
                                  if (entry.key > 0)
                                    const Divider(
                                        height: 1,
                                        color: MCColors.borderLight),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 16,
                                            color: MCColors.primaryMid),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: MCTypography.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Description ───────────────────────────────────
                    Text('Description', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    MCInput(
                      controller: _descController,
                      hint: 'Tell people what to expect…',
                      maxLines: 4,
                      minLines: 3,
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    // ── Cost ──────────────────────────────────────────
                    Text('Cost note', style: MCTypography.h4),
                    const SizedBox(height: 8),
                    MCInput(
                      controller: _costController,
                      hint: 'e.g. Free, ₹200 per person',
                      prefixIcon: Icons.currency_rupee,
                      enabled: !_submitting,
                    ),
                    const SizedBox(height: 28),

                    // ── Poll note ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MCColors.primaryPale,
                        borderRadius:
                            BorderRadius.circular(MCSpacing.radiusSm),
                        border: Border.all(
                            color: MCColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.poll_outlined,
                              size: 18, color: MCColors.primaryMid),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A poll will be auto-posted to the feed asking members to RSVP.',
                              style: MCTypography.caption
                                  .copyWith(color: MCColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Submit ────────────────────────────────────────
                    MCPrimaryButton(
                      label: 'Create Event',
                      icon: Icons.event_available,
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
