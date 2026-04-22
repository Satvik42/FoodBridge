import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';
import 'new_request_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = FirebaseService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<FoodRequest> _filtered(List<FoodRequest> all, RequestStatus? status) {
    if (status == null) return all;
    return all.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('My Requests', style: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabCtrl,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 2.5),
                insets: EdgeInsets.symmetric(horizontal: 20),
              ),
              labelStyle: GoogleFonts.syne(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.syne(fontSize: 12),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<FoodRequest>>(
        stream: _svc.userRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load requests',
              subtitle: snapshot.error.toString(),
            );
          }
          final live = snapshot.data ?? [];
          final all  = live.isNotEmpty ? live : sampleRequests;

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _RequestList(requests: _filtered(all, null)),
              _RequestList(requests: [
                ..._filtered(all, RequestStatus.pending),
                ..._filtered(all, RequestStatus.accepted),
              ]),
              _RequestList(requests: _filtered(all, RequestStatus.completed)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push<FoodRequest>(
            context,
            MaterialPageRoute(builder: (_) => const NewRequestScreen()),
          );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Request for "${result.foodType}" submitted!',
                  style: GoogleFonts.dmSans(fontSize: 13)),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Request', style: GoogleFonts.syne(
            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<FoodRequest> requests;
  const _RequestList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No requests here',
        subtitle: 'Browse available food and tap "Request Food" to get started.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: requests.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _RequestCard(request: requests[i]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FoodRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final mins = request.deliveryMinutes;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: request.statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(request.statusIcon, size: 20,
                color: request.statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.foodType, style: GoogleFonts.syne(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text(DateFormat('MMM d · h:mm a').format(request.requestedAt),
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(
              label: request.statusLabel,
              color: request.statusColor,
              bg: request.statusBg,
              icon: request.statusIcon,
            ),
            const SizedBox(height: 4),
            // Priority badge
            StatusBadge(
              label: request.priority.label,
              color: request.priority.color,
              bg: request.priority.bg,
              icon: Icons.flag_outlined,
            ),
          ]),
        ]),

        const SizedBox(height: 14),
        const AppDivider(),
        const SizedBox(height: 12),

        Row(children: [
          _detail(Icons.scale_outlined, 'Quantity', request.quantity),
          const SizedBox(width: 16),
          _detail(Icons.location_on_outlined, 'Location', request.location),
        ]),

        // Delivery time for completed
        if (mins != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryXL,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.primary2),
              const SizedBox(width: 8),
              Text('Delivered in ${mins} min${mins == 1 ? '' : 's'}',
                  style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ]),
          ),
        ],

        if (request.volunteerName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blueL,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              AvatarCircle(
                initials: request.volunteerName![0].toUpperCase(),
                bg: const Color(0xFFBDD5F7),
                fg: AppColors.blue, size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.volunteerName!, style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
                  Text('Volunteer · On the way',
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.blue.withOpacity(0.7))),
                ],
              )),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: AppColors.blue),
            ]),
          ),
        ],

        const SizedBox(height: 14),
        _StatusStepper(status: request.status),
      ]),
    );
  }

  Widget _detail(IconData icon, String label, String val) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 10, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 3),
        Text(val, style: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final RequestStatus status;
  const _StatusStepper({required this.status});

  int get _step {
    switch (status) {
      case RequestStatus.pending:   return 0;
      case RequestStatus.accepted:  return 1;
      case RequestStatus.completed: return 2;
      case RequestStatus.cancelled: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status == RequestStatus.cancelled) return const SizedBox.shrink();
    const steps = ['Pending', 'Accepted', 'Completed'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final done   = e.key <= _step;
        final active = e.key == _step;
        return Expanded(
          child: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.bg3,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 4),
            Text(e.value, style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: done ? AppColors.primary : AppColors.textMuted)),
            if (e.key < steps.length - 1) Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: e.key < _step
                    ? AppColors.primary : AppColors.divider,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
