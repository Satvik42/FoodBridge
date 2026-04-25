import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import '../widgets/food_card.dart';
import 'surplus_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc          = FirebaseService();
  String _filter      = 'All';
  String _searchQuery = '';
  int    _notifCount  = 2;

  List<FoodListing> _applyFilter(List<FoodListing> all) {
    List<FoodListing> base;
    switch (_filter) {
      case 'Fresh':
        base = all.where((l) => l.expiryStatus == ExpiryStatus.fresh).toList();
        break;
      case 'Near Expiry':
        base = all.where((l) => l.expiryStatus == ExpiryStatus.nearExpiry).toList();
        break;
      case 'Nearby':
        base = all.where((l) => l.distanceKm <= 2.0).toList();
        break;
      case 'High Priority':
        base = all.where((l) => l.priority == Priority.high).toList();
        break;
      default:
        base = all;
    }
    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((l) =>
        l.foodType.toLowerCase().contains(q) ||
        l.location.toLowerCase().contains(q) ||
        l.donorName.toLowerCase().contains(q) ||
        l.description.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return StreamBuilder<List<FoodListing>>(
      stream: _svc.listingsStream(),
      builder: (context, snapshot) {
        final allListings = snapshot.data ?? sampleListings;
        final filtered    = _applyFilter(allListings);
        final isLoading   = snapshot.connectionState == ConnectionState.waiting
            && !snapshot.hasData;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(appState, allListings),
                SliverToBoxAdapter(child: _buildHeroSection(appState, allListings)),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildFilterChips()),
                SliverToBoxAdapter(child: _buildListingsHeader(filtered)),
                isLoading ? _buildLoadingSliver() : _buildListingsSliver(filtered),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AppState appState, List<FoodListing> all) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: AppColors.primary,
      title: Row(children: [
        Text('Food', style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Bridge', style: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: const Color(0xFFB7E4C7))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text('User', style: GoogleFonts.syne(
              fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
        ),
      ]),
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => _showNotifications(context),
          ),
          if (_notifCount > 0) Positioned(
            right: 10, top: 10,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: AppColors.coral, shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Center(child: Text('$_notifCount', style: GoogleFonts.syne(
                  fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => _showProfileSheet(context, appState),
            borderRadius: BorderRadius.circular(16),
            child: AvatarCircle(
              initials: appState.userName.isNotEmpty
                  ? appState.userName[0].toUpperCase() : 'U',
              bg: const Color(0xFF40916C), fg: Colors.white, size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(AppState appState, List<FoodListing> all) {
    final highPriority = all.where((l) => l.priority == Priority.high).length;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Good morning, ${appState.userName} 👋',
            style: GoogleFonts.dmSans(
                fontSize: 14, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text('Find food near you', style: GoogleFonts.syne(
            fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 16),
        Row(children: [
          MiniStatCard(
            value: '${all.length}', label: 'Available now',
            icon: Icons.restaurant_outlined,
            color: Colors.white, bg: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            value: '${all.where((l) => l.expiryStatus == ExpiryStatus.fresh).length}',
            label: 'Fresh items',
            icon: Icons.eco_outlined,
            color: Colors.white, bg: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            value: '$highPriority',
            label: 'High priority',
            icon: Icons.flag_outlined,
            color: Colors.white, bg: Colors.white.withOpacity(0.15),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search food type, location...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.tune, color: Colors.white, size: 16),
          ),
          filled: true, fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All', 'Fresh', 'Near Expiry', 'Nearby', 'High Priority'];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f  = filters[i];
          final on = _filter == f;
          Color chipColor = on ? AppColors.primary : AppColors.cardBg;
          if (on && f == 'High Priority') chipColor = AppColors.coral;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: on
                      ? (f == 'High Priority' ? AppColors.coral : AppColors.primary)
                      : AppColors.border,
                  width: on ? 1 : 0.5,
                ),
              ),
              child: Text(f, style: GoogleFonts.syne(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: on ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingsHeader(List<FoodListing> filtered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: _searchQuery.isEmpty ? 'Available Near You' : 'Search Results',
          subtitle: '${filtered.length} listing${filtered.length == 1 ? '' : 's'}'
              '${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}',
          action: TextButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary2),
            label: Text('Refresh', style: GoogleFonts.syne(
                fontSize: 12, color: AppColors.primary2)),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SurplusFoodScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.primaryXL,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary3.withOpacity(0.4), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.volunteer_activism_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Have surplus food? Report it here',
                  style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.primary))),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.primary2),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildLoadingSliver() => SliverList(
    delegate: SliverChildBuilderDelegate(
      (_, i) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: LoadingCard(),
      ),
      childCount: 3,
    ),
  );

  Widget _buildListingsSliver(List<FoodListing> filtered) {
    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.no_food_outlined,
          title: 'No listings found',
          subtitle: 'Try changing the filter or check back soon.',
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FoodCard(
            listing: filtered[i],
            onRequest: () => _handleRequest(filtered[i]),
          ),
        ),
        childCount: filtered.length,
      ),
    );
  }

  Future<void> _handleRequest(FoodListing listing) async {
    await _svc.createRequest(
      foodId:   listing.isSurplus ? listing.surplusId : listing.id,
      foodType: listing.foodType,
      location: listing.location,
      quantity: listing.quantity,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Request sent for ${listing.foodType}!',
          style: GoogleFonts.dmSans(fontSize: 13)),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showNotifications(BuildContext context) {
    setState(() => _notifCount = 0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(notifications: sampleNotifications),
    );
  }

  void _showProfileSheet(BuildContext ctx, AppState appState) {
    showModalBottomSheet(
      context: ctx, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(children: [
            AvatarCircle(
                initials: appState.userName.isNotEmpty ? appState.userName[0].toUpperCase() : 'U',
                bg: AppColors.primary, fg: Colors.white, size: 50),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appState.userName, style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text('User / Donor', style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textMuted)),
            ]),
          ]),
          const SizedBox(height: 24),
          const AppDivider(),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.coral),
            title: Text('Sign Out', style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              await AuthService().signOut();
              appState.clearUser();
              if (c.mounted) Navigator.pop(c);
            },
          ),
        ]),
      ),
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;
  const _NotificationSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Text('Notifications', style: GoogleFonts.syne(
            fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...notifications.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: n.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(n.icon, size: 18, color: n.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: n.isRead
                        ? AppColors.textMuted : AppColors.textPrimary)),
                Text(n.body, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted, height: 1.4)),
              ],
            )),
            if (!n.isRead) Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary2, shape: BoxShape.circle),
            ),
          ]),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }
}
