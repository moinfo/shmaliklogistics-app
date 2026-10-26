import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../../features/mod_vehicles/screens/vehicles_screen.dart';
import '../../features/mod_drivers/screens/drivers_screen.dart';
import '../../features/mod_permits/screens/permits_screen.dart';
import '../../features/mod_documents/screens/documents_screen.dart';
import '../../features/mod_fuel_logs/screens/fuel_logs_screen.dart';
import '../../features/mod_inspections/screens/inspections_screen.dart';
import '../../features/mod_inventory/screens/inventory_screen.dart';
import '../../features/mod_maintenance/screens/maintenance_screen.dart';
import '../../features/mod_proformas/screens/proformas_screen.dart';
import '../../features/mod_purchase_orders/screens/purchase_orders_screen.dart';
import '../../features/mod_quote_requests/screens/quote_requests_screen.dart';
import '../../features/mod_quotes/screens/quotes_screen.dart';
import '../../features/mod_clients/screens/clients_screen.dart';
import '../../features/mod_expenses/screens/expenses_screen.dart';
import '../../features/mod_cargo/screens/cargo_screen.dart';
import '../../features/mod_check_ins/screens/check_ins_screen.dart';
import '../../features/mod_suppliers/screens/suppliers_screen.dart';
import '../../features/mod_employees/screens/employees_screen.dart';
import '../../features/mod_talent/screens/talent_screen.dart';
import '../../features/mod_payroll/screens/payroll_screen.dart';
import '../../features/mod_reports/screens/reports_screen.dart';
import '../../features/mod_re_properties/screens/properties_screen.dart';
import '../../features/mod_re_tenants/screens/tenants_screen.dart';
import '../../features/mod_re_leases/screens/leases_screen.dart';
import '../../features/mod_re_rent/screens/rent_screen.dart';
import '../../features/mod_re_expenses/screens/expenses_screen.dart';
import '../../features/mod_reference/screens/reference_screen.dart';

/// Maps a navigation-drawer menu label to the built mobile screen for that
/// module. Labels absent here fall back to the `ModulePlaceholderScreen`, so
/// the full permitted menu stays navigable while modules are still being built.
final Map<String, Widget Function(ApiClient)> kModuleScreens = {
  // Operations & fleet
  'All Vehicles': (api) => VehiclesScreen(apiClient: api),
  'Drivers': (api) => DriversScreen(apiClient: api),
  'Permits': (api) => PermitsScreen(apiClient: api),
  'Documents': (api) => DocumentsScreen(apiClient: api),
  'Fuel Logs': (api) => FuelLogsScreen(apiClient: api),
  'Inspections': (api) => InspectionsScreen(apiClient: api),
  'Check-Ins': (api) => CheckInsScreen(apiClient: api),
  'Cargo': (api) => CargoScreen(apiClient: api),
  // Procurement & inventory
  'Inventory': (api) => InventoryScreen(apiClient: api),
  'Maintenance': (api) => MaintenanceScreen(apiClient: api),
  'Suppliers': (api) => SuppliersScreen(apiClient: api),
  'Purchase Orders': (api) => PurchaseOrdersScreen(apiClient: api),
  // Billing
  'Quotes': (api) => QuotesScreen(apiClient: api),
  'Proforma': (api) => ProformasScreen(apiClient: api),
  'Quote Requests': (api) => QuoteRequestsScreen(apiClient: api),
  'Expenses': (api) => ExpensesScreen(apiClient: api),
  // People & clients
  'Clients': (api) => ClientsScreen(apiClient: api),
  'Employees': (api) => EmployeesScreen(apiClient: api),
  'Payroll': (api) => PayrollScreen(apiClient: api),
  'Salary Slips': (api) => PayrollScreen(apiClient: api),
  'Salary Slip': (api) => PayrollScreen(apiClient: api),
  // Reference lists (read-only, generic screen)
  'Allowances': (api) => ReferenceScreen(apiClient: api, title: 'Allowances', eyebrow: 'HR', path: '/staff/modules/allowances', icon: Icons.card_giftcard_rounded),
  'Notifications': (api) => ReferenceScreen(apiClient: api, title: 'Notifications', eyebrow: 'Alerts', path: '/staff/notifications', icon: Icons.notifications_rounded),
  'Company Settings': (api) => ReferenceScreen(apiClient: api, title: 'Company Settings', eyebrow: 'Settings', path: '/staff/modules/settings/company', icon: Icons.business_rounded),
  'Licence Classes': (api) => ReferenceScreen(apiClient: api, title: 'Licence Classes', eyebrow: 'Settings', path: '/staff/modules/settings/license-classes', icon: Icons.credit_card_rounded),
  'Document Types': (api) => ReferenceScreen(apiClient: api, title: 'Document Types', eyebrow: 'Settings', path: '/staff/modules/settings/document-types', icon: Icons.description_rounded),
  'Payroll Settings': (api) => ReferenceScreen(apiClient: api, title: 'Payroll Settings', eyebrow: 'Settings', path: '/staff/modules/settings/payroll', icon: Icons.account_balance_wallet_rounded),
  'Deductions': (api) => ReferenceScreen(apiClient: api, title: 'Deductions', eyebrow: 'Settings', path: '/staff/modules/settings/deductions', icon: Icons.list_alt_rounded),
  'Deduction Subscriptions': (api) => ReferenceScreen(apiClient: api, title: 'Deduction Subscriptions', eyebrow: 'Settings', path: '/staff/modules/settings/deduction-subscriptions', icon: Icons.link_rounded),
  'Staff Bank Details': (api) => ReferenceScreen(apiClient: api, title: 'Staff Bank Details', eyebrow: 'Settings', path: '/staff/modules/settings/bank-details', icon: Icons.account_balance_rounded),
  'Departments': (api) => ReferenceScreen(apiClient: api, title: 'Departments', eyebrow: 'Settings', path: '/staff/modules/settings/departments', icon: Icons.apartment_rounded),
  'Roles & Permissions': (api) => ReferenceScreen(apiClient: api, title: 'Roles & Permissions', eyebrow: 'Settings', path: '/staff/modules/settings/roles', icon: Icons.vpn_key_rounded),
  'Users': (api) => ReferenceScreen(apiClient: api, title: 'Users', eyebrow: 'Settings', path: '/staff/modules/settings/users', icon: Icons.person_rounded),
  'Recruitment': (api) => TalentScreen(apiClient: api),
  'Appraisals': (api) => TalentScreen(apiClient: api),
  // Reports (one screen, three report tabs)
  'Route Profitability': (api) => ReportsScreen(apiClient: api),
  'Financial Summary': (api) => ReportsScreen(apiClient: api, initialTab: 1),
  'Fleet Utilization': (api) => ReportsScreen(apiClient: api, initialTab: 2),
  // Real Estate
  'Properties': (api) => RealEstatePropertiesScreen(apiClient: api),
  'Tenants': (api) => RealEstateTenantsScreen(apiClient: api),
  'Leases': (api) => RealEstateLeasesScreen(apiClient: api),
  'Rent': (api) => RealEstateRentScreen(apiClient: api),
  'Property Expenses': (api) => RealEstateExpensesScreen(apiClient: api),
};
