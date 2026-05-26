import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../customer_service.dart';
import '../models/cargo.dart';
import '../models/customer_invoice.dart';
import '../models/quote_request.dart';
import 'customer_status_colors.dart';
import 'customer_widgets.dart';
import 'invoice_detail_screen.dart';
import 'quote_request_form_screen.dart';
import 'trip_detail_screen.dart';

/// Self-contained customer portal home. Exposes the five customer sections via
/// an internal segmented tab bar: Overview, Trips, Invoices, Cargo, Quotes.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late final CustomerService _service;
  int _tab = 0;

  /// Bumped per-tab so the header refresh action forces the active tab to
  /// re-run its `initState` fetch — preserving each tab's own load behavior.
  final List<int> _reloadKeys = List<int>.filled(5, 0);

  static const _tabs = [
    ('Overview', Icons.dashboard_outlined),
    ('My Trips', Icons.local_shipping_outlined),
    ('Invoices', Icons.receipt_long_outlined),
    ('Cargo', Icons.inventory_2_outlined),
    ('Quote Requests', Icons.request_quote_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _service = CustomerService(widget.apiClient);
  }

  void _refreshCurrentTab() => setState(() => _reloadKeys[_tab]++);

  @override
  Widget build(BuildContext context) {
    final name = AppSession.instance.name;
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Customer Portal',
            subtitle: 'Welcome,',
            title: name.isEmpty ? 'Customer Portal' : name,
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _refreshCurrentTab,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = _tab == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? ModuleAccent.brand.base : AppColors.chipUnselected(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? ModuleAccent.brand.base : AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(_tabs[i].$2, size: 15, color: selected ? Colors.white : kMuted),
                      const SizedBox(width: 6),
                      Text(_tabs[i].$1,
                          style: AppType.body(12.5,
                              weight: FontWeight.w600,
                              color: selected ? Colors.white : kMuted)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return _OverviewTab(
            key: ValueKey('overview-${_reloadKeys[0]}'),
            service: _service,
            onSeeTrips: () => setState(() => _tab = 1));
      case 1:
        return _TripsTab(key: ValueKey('trips-${_reloadKeys[1]}'), service: _service);
      case 2:
        return _InvoicesTab(key: ValueKey('invoices-${_reloadKeys[2]}'), service: _service);
      case 3:
        return _CargoTab(key: ValueKey('cargo-${_reloadKeys[3]}'), service: _service);
      case 4:
        return _QuotesTab(key: ValueKey('quotes-${_reloadKeys[4]}'), service: _service);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ───────────────────────────────────────────────────────────── Overview tab ──

class _OverviewTab extends StatefulWidget {
  final CustomerService service;
  final VoidCallback onSeeTrips;
  const _OverviewTab({super.key, required this.service, required this.onSeeTrips});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  CustomerDashboard? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.service.fetchDashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildShimmer();
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 60),
        CustomerErrorView(message: _error!, onRetry: _load),
      ]);
    }
    final d = _data!;
    final cardWidth = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          RevealOnLoad(
            delayMs: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.companyName != null && d.companyName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(d.companyName!,
                        style: AppType.display(18, color: AppColors.textNavy(context))),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: 'Active Trips',
                        value: '${d.stats.activeTrips}',
                        icon: Icons.local_shipping_rounded,
                        accent: ModuleAccent.brand,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: 'Total Trips',
                        value: '${d.stats.totalTrips}',
                        icon: Icons.route_rounded,
                        accent: ModuleAccent.brand,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: 'Pending Amount',
                        value: formatCurrency(d.stats.pendingAmount),
                        icon: Icons.account_balance_wallet_rounded,
                        accent: ModuleAccent.finance,
                        danger: d.stats.pendingAmount > 0,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        label: 'Paid Invoices',
                        value: '${d.stats.paidInvoices}',
                        icon: Icons.verified_rounded,
                        accent: ModuleAccent.finance,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          RevealOnLoad(
            delayMs: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Active Trips',
                  eyebrow: 'In motion',
                  icon: Icons.local_shipping_rounded,
                  accent: ModuleAccent.brand,
                  trailing: d.activeTrips.isNotEmpty
                      ? TextButton(
                          onPressed: widget.onSeeTrips,
                          child: Text('See all',
                              style: AppType.body(12.5,
                                  weight: FontWeight.w600, color: kPrimary)),
                        )
                      : null,
                ),
                if (d.activeTrips.isEmpty)
                  _MutedCard(text: 'No active trips right now.')
                else
                  ...d.activeTrips.take(4).map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TripCard(trip: t, service: widget.service),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 22),
          RevealOnLoad(
            delayMs: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Recent Invoices',
                  eyebrow: 'Billing',
                  icon: Icons.receipt_long_rounded,
                  accent: ModuleAccent.brand,
                ),
                if (d.recentInvoices.isEmpty)
                  _MutedCard(text: 'No invoices yet.')
                else
                  ...d.recentInvoices.take(4).map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InvoiceCard(invoice: i, service: widget.service),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    final w = (MediaQuery.sizeOf(context).width - 40 - 12) / 2;
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          AppSkeleton.box(context, height: 20, width: 160, radius: 6),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < 4; i++) AppSkeleton.box(context, height: 118, width: w, radius: 18),
            ],
          ),
          const SizedBox(height: 26),
          AppSkeleton.box(context, height: 22, width: 140, radius: 6),
          const SizedBox(height: 14),
          for (var i = 0; i < 2; i++) ...[
            AppSkeleton.box(context, height: 96, radius: 16),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────── Trips tab ──

class _TripsTab extends StatefulWidget {
  final CustomerService service;
  const _TripsTab({super.key, required this.service});

  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  late Future<List<Trip>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchTrips();
  }

  void _refresh() => setState(() => _future = widget.service.fetchTrips());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Trip>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ListSkeleton();
        }
        if (snapshot.hasError) {
          return CustomerErrorView(message: snapshot.error.toString(), onRetry: _refresh);
        }
        final trips = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _refresh(),
          child: trips.isEmpty
              ? ListView(children: const [
                  SizedBox(
                    height: 360,
                    child: CustomerEmptyView(
                      icon: Icons.local_shipping_outlined,
                      title: 'No trips yet',
                      subtitle: 'Your shipments will appear here once they are scheduled.',
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: trips.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: _TripCard(trip: trips[i], service: widget.service),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────── Invoices tab ──

class _InvoicesTab extends StatefulWidget {
  final CustomerService service;
  const _InvoicesTab({super.key, required this.service});

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  late Future<List<CustomerInvoice>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchInvoices();
  }

  void _refresh() => setState(() => _future = widget.service.fetchInvoices());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerInvoice>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ListSkeleton();
        }
        if (snapshot.hasError) {
          return CustomerErrorView(message: snapshot.error.toString(), onRetry: _refresh);
        }
        final invoices = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _refresh(),
          child: invoices.isEmpty
              ? ListView(children: const [
                  SizedBox(
                    height: 360,
                    child: CustomerEmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No invoices',
                      subtitle: 'Invoices issued to your account will appear here.',
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: _InvoiceCard(invoice: invoices[i], service: widget.service),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────── Cargo tab ──

class _CargoTab extends StatefulWidget {
  final CustomerService service;
  const _CargoTab({super.key, required this.service});

  @override
  State<_CargoTab> createState() => _CargoTabState();
}

class _CargoTabState extends State<_CargoTab> {
  late Future<List<Cargo>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchCargo();
  }

  void _refresh() => setState(() => _future = widget.service.fetchCargo());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cargo>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ListSkeleton();
        }
        if (snapshot.hasError) {
          return CustomerErrorView(message: snapshot.error.toString(), onRetry: _refresh);
        }
        final cargo = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _refresh(),
          child: cargo.isEmpty
              ? ListView(children: const [
                  SizedBox(
                    height: 360,
                    child: CustomerEmptyView(
                      icon: Icons.inventory_2_outlined,
                      title: 'No cargo',
                      subtitle: 'Shipments registered for you will be tracked here.',
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: cargo.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: _CargoCard(cargo: cargo[i]),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────── Quotes tab ──

class _QuotesTab extends StatefulWidget {
  final CustomerService service;
  const _QuotesTab({super.key, required this.service});

  @override
  State<_QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<_QuotesTab> {
  late Future<List<QuoteRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchQuoteRequests();
  }

  void _refresh() => setState(() => _future = widget.service.fetchQuoteRequests());

  Future<void> _openForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuoteRequestFormScreen(service: widget.service)),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote request submitted. Our team will contact you shortly.'),
          backgroundColor: kSuccess,
        ),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<QuoteRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }
          if (snapshot.hasError) {
            return CustomerErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final quotes = snapshot.data ?? [];
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async => _refresh(),
            child: quotes.isEmpty
                ? ListView(children: const [
                    SizedBox(
                      height: 360,
                      child: CustomerEmptyView(
                        icon: Icons.request_quote_outlined,
                        title: 'No quote requests',
                        subtitle: 'Tap the button below to request a quote for a new shipment.',
                      ),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: quotes.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RevealOnLoad(
                        delayMs: (i * 60).clamp(0, 300),
                        child: _QuoteCard(quote: quotes[i]),
                      ),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Request a Quote', style: AppType.body(14, weight: FontWeight.w700)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── Cards ──

class _TripCard extends StatelessWidget {
  final Trip trip;
  final CustomerService service;
  const _TripCard({required this.trip, required this.service});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);
    return AppCard(
      accentColor: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerTripDetailScreen(tripId: trip.id, service: service)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trip.tripNumber,
                  style: AppType.display(14.5, color: AppColors.textNavy(context))),
              StatusPill(label: trip.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(trip.routeFrom,
                    style: AppType.body(13,
                        weight: FontWeight.w600, color: AppColors.textPrimary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: kMuted),
              ),
              Expanded(
                child: Text(trip.routeTo,
                    textAlign: TextAlign.right,
                    style: AppType.body(13,
                        weight: FontWeight.w600, color: AppColors.textPrimary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (trip.departureDate != null) ...[
                const Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(trip.departureDate),
                    style: AppType.body(11, color: kMuted)),
              ],
              if (trip.vehiclePlate != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.directions_car_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(trip.vehiclePlate!, style: AppType.body(11, color: kMuted)),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 16, color: kPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final CustomerInvoice invoice;
  final CustomerService service;
  const _InvoiceCard({required this.invoice, required this.service});

  @override
  Widget build(BuildContext context) {
    final color = invoiceStatusColor(invoice.status);
    final outstanding = invoice.balanceDue > 0;
    return AppCard(
      accentColor: color,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerInvoiceDetailScreen(invoiceId: invoice.id, service: service)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(invoice.documentNumber,
                    style: AppType.display(14.5, color: AppColors.textNavy(context))),
              ),
              StatusPill(label: invoice.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 14),
          // Balance shown prominently as the headline figure.
          Text(outstanding ? 'Balance due' : 'Fully paid',
              style: AppType.body(11, weight: FontWeight.w500, color: kMuted)),
          const SizedBox(height: 2),
          Text(formatCurrency(outstanding ? invoice.balanceDue : invoice.total),
              style: AppType.number(22, color: outstanding ? kDanger : kSuccess)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Total ${formatCurrency(invoice.total)}',
                  style: AppType.body(11.5, color: kMuted)),
              if (invoice.dueDate != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('Due ${formatDate(invoice.dueDate)}',
                    style: AppType.body(11.5, color: kMuted)),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 16, color: kPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _CargoCard extends StatelessWidget {
  final Cargo cargo;
  const _CargoCard({required this.cargo});

  @override
  Widget build(BuildContext context) {
    final color = cargoStatusColor(cargo.status);
    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cargo.cargoNumber,
                    style: AppType.display(14.5, color: AppColors.textNavy(context))),
              ),
              StatusPill(label: cargo.statusLabel, color: color),
            ],
          ),
          if (cargo.description != null && cargo.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(cargo.description!,
                style: AppType.body(13, color: AppColors.textPrimary(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          if (cargo.origin != null || cargo.destination != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(cargo.origin ?? cargo.tripRouteFrom ?? '—',
                      style: AppType.body(12, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: kMuted),
                ),
                Expanded(
                  child: Text(cargo.destination ?? cargo.tripRouteTo ?? '—',
                      textAlign: TextAlign.right,
                      style: AppType.body(12, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (cargo.typeLabel != null) ...[
                const Icon(Icons.category_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(cargo.typeLabel!, style: AppType.body(11, color: kMuted)),
              ],
              if (cargo.tripNumber != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.local_shipping_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(cargo.tripNumber!, style: AppType.body(11, color: kMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteRequest quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final color = quoteStatusColor(quote.status);
    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(quote.routeFrom,
                          style: AppType.display(14.5, color: AppColors.textNavy(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: kMuted),
                    ),
                    Flexible(
                      child: Text(quote.routeTo,
                          style: AppType.display(14.5, color: AppColors.textNavy(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: quote.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(quote.cargoDescription,
              style: AppType.body(13, color: AppColors.textPrimary(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              if (quote.preferredDate != null) ...[
                const Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('Preferred ${formatDate(quote.preferredDate)}',
                    style: AppType.body(11, color: kMuted)),
              ] else if (quote.createdAt != null) ...[
                const Icon(Icons.schedule_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('Requested ${formatDate(quote.createdAt)}',
                    style: AppType.body(11, color: kMuted)),
              ],
            ],
          ),
          if (quote.staffNotes != null && quote.staffNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 14, color: kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(quote.staffNotes!,
                        style: AppType.body(12, color: AppColors.textPrimary(context))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MutedCard extends StatelessWidget {
  final String text;
  const _MutedCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.inbox_rounded, size: 18, color: kMuted.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppType.body(13, color: kMuted)),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for the list tabs (Trips / Invoices / Cargo / Quotes).
class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
