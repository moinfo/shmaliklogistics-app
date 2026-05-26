# Real Estate — Mobile (Flutter) Build Contract

Read-only staff screens for the Real Estate module, consuming the existing API at
`/api/staff/modules/real-estate/*` (controller `App\Http\Controllers\Api\Staff\Modules\RealEstateController`,
already built — DO NOT touch it). One agent per feature folder, fully disjoint. The orchestrator owns the
drawer (`lib/core/widgets/app_drawer.dart`) and the registry (`lib/core/widgets/module_registry.dart`).

## Conventions (mirror these reference files EXACTLY)
- Service: `lib/features/mod_vehicles/mod_vehicles_service.dart` — `class ModXService { ModXService(this._api); final ApiClient _api; }`,
  a `_unwrapList(raw)` helper that handles both `[...]` and `{data:[...]}` (paginator), `await _api.get('/staff/modules/...')`.
- Screen: `lib/features/mod_vehicles/screens/vehicles_screen.dart` — entry screen class
  `class <ScreenClass> extends StatefulWidget { const <ScreenClass>({super.key, required this.apiClient}); final ApiClient apiClient; }`.
  `Scaffold(backgroundColor: AppColors.surfaceVariant(context))` + `AppGradientHeader(eyebrow, title, subtitle, actions:[HeaderIconButton(icon: Icons.refresh_rounded,...)])`
  + `FutureBuilder` (waiting→skeleton, error→`AppError(onRetry)`) + `RefreshIndicator` + `CustomScrollView` with a search `TextField`, `ChoiceChip` status filters, `AppEmpty`, and `AppCard`/`StatusPill` rows wrapped in `RevealOnLoad(delayMs:(i*60).clamp(0,300))`. Tap → push a detail screen in the same folder.
- Detail screen: like `lib/features/mod_vehicles/screens/vehicle_detail_screen.dart` — takes `{required int <x>Id, required <Service> service, <Model>? initial}`, fetches detail in initState, shows `SectionHeader` + `AppCard` blocks + `StatCard`s.
- Model: `models/*.dart` — `fromJson` factories; money via `double.tryParse(x.toString()) ?? 0`; ints via `(x as num?)?.toInt()`; nullable strings as `x as String?`.
- Imports available: `core/api/api_client.dart`, `core/ui/ui_kit.dart`, `core/ui/typography.dart` (`AppType.body/number/display/eyebrow`), `core/utils/colors.dart` (`AppColors.*`, `kPrimary`,`kMuted`,`kDanger`,`kWarning`,`kSuccess`), `core/utils/app_theme.dart`, `core/utils/formatters.dart` (`formatDate`, money formatters — check what exists). Use `StatusPill(label:, color:)`. Money: format with `intl`/existing formatter; TZS values are plain numbers.
- Status colors arrive from the API as hex strings (e.g. `status_color: "#22C55E"`). Parse with a helper: `Color _hex(String? s)=> s==null?kMuted:Color(int.parse('FF${s.replaceAll('#','')}',radix:16));`. Fall back to kMuted.
- Do NOT edit `main.dart`, drawer, registry, kit, `core/*`, or other features. Do NOT run flutter builds. Expose only your screen class.

## API base + envelopes
Base path: `/staff/modules/real-estate`. Lists arrive as `{ "<key>": {data:[...], current_page, last_page, ...} }` (paginator) — unwrap with `_unwrapList`. Detail as a flat object under a key. Stats/enum maps (`stats`,`statuses`,`types`,`categories`,`billingCycles`) are sibling keys on list responses.

## The 5 modules

### 1) Properties — folder `mod_re_properties`, service `ModRePropertiesService`, screen `RealEstatePropertiesScreen`, detail `PropertyDetailScreen`
- `GET /properties?search=&status=&type=` → `{ properties:{data:[ROW]}, stats:{total,occupied,under_renovation,monthly_roll}, types:{key:{label,color}}, statuses:{...} }`
  ROW: id, code, name, type, type_label, type_color, status, status_label, status_color, ownership, address, region, district, units_count, occupied_units_count, monthly_rent_roll(number)
- `GET /properties/{id}` → `{ property:{id,code,name,type,type_label,type_color,status,status_label,status_color,ownership,address,region,district,acquisition_date,purchase_currency,market_value,title_deed_number,title_deed_url,description,notes,units_count,occupied_units_count}, units:[{id,unit_number,type,type_label,status,status_label,status_color,rent_amount,rent_currency,bedrooms,bathrooms,size_sqm,active_lease:{id,lease_number,tenant_name,rent_amount,start_date,end_date}|null}], expenses:[{id,category,category_label,category_icon,description,amount,currency,amount_tzs,expense_date,phase,vendor,unit_label}], financials:{purchase_price,renovation_total,total_invested,annual_rent_roll,expense_total} }`
- List: 4 StatCards (Total/Occupied/Under Renovation/Monthly Roll TZS), search, status+type chips, cards show name+code, status pill (use status_color), address/region, units_count·occupied, monthly_rent_roll. Detail: header w/ code+status; financials StatCards (Total Invested, Renovation, Annual Rent Roll); a Units section (each unit card: unit_number, type_label, status pill, rent, and active-lease tenant+lease_number if present); recent Expenses section (category_icon+label, description, amount_tzs, date).

### 2) Tenants — folder `mod_re_tenants`, service `ModReTenantsService`, screen `RealEstateTenantsScreen`, detail `TenantDetailScreen`
- `GET /tenants?search=&status=&type=` → `{ tenants:{data:[ROW]}, stats:{total,active,companies}, types, statuses }`
  ROW: id, code, name, type, type_label, type_color, status, status_label, status_color, phone, email, company_name, active_leases_count
- `GET /tenants/{id}` → `{ tenant:{id,code,name,type,type_label,status,status_label,status_color,phone,phone_alt,email,national_id,company_name,tin,address,emergency_contact_name,emergency_contact_phone,notes}, leases:[{id,lease_number,property_label,rent_amount,rent_currency,billing_cycle,start_date,end_date,status,status_label,status_color}] }`
- List: 3 StatCards (Total/Active/Companies), search, status+type chips, cards: name (+company_name), type pill, phone, active_leases_count. Detail: contact card (phone, alt, email, national_id, company/tin, address, emergency contact) + Leases section (lease_number, property_label, rent, dates, status pill).

### 3) Leases — folder `mod_re_leases`, service `ModReLeasesService`, screen `RealEstateLeasesScreen`, detail `LeaseDetailScreen`
- `GET /leases?search=&status=` → `{ leases:{data:[ROW]}, stats:{active,expiring_30d,expired,monthly_roll}, statuses, billingCycles:{key:{label,months}} }`
  ROW: id, lease_number, tenant_name, property_label, rent_amount, rent_currency, billing_cycle, start_date, end_date, status, status_label, status_color, has_contract(bool)
- `GET /leases/{id}` → `{ lease:{id,lease_number,property_label,property_id,property_name,unit_id,unit_number,tenant_id,tenant_name,tenant_phone,start_date,end_date,billing_cycle,rent_amount,rent_currency,deposit_amount,payment_day,status,status_label,status_color,has_contract,contract_url,contract_uploaded_at,terms,notes}, invoices:[{id,invoice_number,period_start,period_end,due_date,amount,currency,status,status_label,status_color,amount_paid,balance_due}], billingCycles }`
- List: 4 StatCards (Active/Expiring ≤30d/Expired/Monthly Roll), search, status chips, cards: lease_number, tenant_name, property_label, rent + billing cycle label, status pill, a small "Contract ✓"/"No contract" chip from has_contract. Detail: lease terms card (rent, cycle, deposit, payment_day, start/end), tenant card (name+phone), property/unit card, a Contract row (if contract_url show "View contract" via url_launcher? — no url_launcher dep; just show contract_uploaded_at + "Contract on file" / "No contract"), and a Rent Invoices section (invoice_number, period, amount, status pill, amount_paid/balance_due).

### 4) Rent — folder `mod_re_rent`, service `ModReRentService`, screen `RealEstateRentScreen` (LIST ONLY, no detail endpoint)
- `GET /rent-invoices?search=&status=` → `{ invoices:{data:[ROW]}, stats:{total_billed,total_collected,outstanding,overdue_count}, statuses }`
  ROW: id, invoice_number, tenant_name, property_label, period_start, period_end, due_date, amount, currency, status, status_label, status_color, amount_paid(number), balance_due(number)
- List: 4 StatCards (Total Billed/Collected/Outstanding[red]/Overdue count), search, status chips, cards: invoice_number, tenant_name, property_label, period (start–end), due_date, amount, status pill, balance_due (red if >0). No tap-through detail needed (read-only summary). Subtitle of header: "Rent invoices & collection".

### 5) Property Expenses — folder `mod_re_expenses`, service `ModReExpensesService`, screen `RealEstateExpensesScreen` (LIST ONLY)
- `GET /expenses?search=&category=&phase=&property_id=` → `{ expenses:{data:[ROW]}, stats:{total_tzs,this_month_tzs,renovation_tzs}, categories:{key:{label,icon}}, phases:{key:{label,color}} }`
  ROW: id, property_id, property_label, unit_label, category, category_label, category_icon, description, amount, currency, amount_tzs(number), expense_date, phase, phase_label, vendor, receipt_number
- List: 3 StatCards (Total TZS / This Month TZS / Renovation TZS), search, category chips (from `categories` keys → label), cards: category_icon+category_label, description, property_label (+unit_label), vendor, amount_tzs (red), date, a small phase chip. No tap-through detail needed.

## Drawer + registry (orchestrator does this — for your awareness only)
Labels (must be unique): `Properties`, `Tenants`, `Leases`, `Rent`, `Property Expenses`. Group `Real Estate`, perms `realestate_<x>.view`.