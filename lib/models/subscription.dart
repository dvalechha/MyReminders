import 'package:uuid/uuid.dart';

enum SubscriptionCategory {
  entertainment('Entertainment'),
  utilities('Utilities'),
  productivity('Productivity'),
  retail('Retail'),
  health('Health'),
  travel('Travel'),
  food('Food'),
  insurance('Insurance'),
  other('Other');

  const SubscriptionCategory(this.value);
  final String value;

  static SubscriptionCategory fromString(String value) {
    return SubscriptionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionCategory.other,
    );
  }
}

enum BillingCycle {
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const BillingCycle(this.value);
  final String value;

  static BillingCycle fromString(String value) {
    return BillingCycle.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BillingCycle.monthly,
    );
  }
}

enum ReminderTime {
  none('None'),
  oneDay('1 day before'),
  threeDays('3 days before'),
  sevenDays('7 days before'),
  custom('Custom');

  const ReminderTime(this.value);
  final String value;

  static ReminderTime fromString(String value) {
    return ReminderTime.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReminderTime.none,
    );
  }
}

enum Currency {
  usd('USD'),
  cad('CAD'),
  eur('EUR'),
  inr('INR');

  const Currency(this.value);
  final String value;

  static Currency fromString(String value) {
    return Currency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Currency.usd,
    );
  }
}

class Subscription {
  final String id;
  final String serviceName;
  final SubscriptionCategory category;
  final double amount;
  final Currency currency;
  final DateTime renewalDate;
  final BillingCycle billingCycle;
  final ReminderTime reminder;
  final String reminderType; // 'none', 'preset', 'custom'
  final int reminderDaysBefore;
  final String? notificationId;
  final String? notes;
  final String? paymentMethod;

  Subscription({
    String? id,
    required this.serviceName,
    required this.category,
    required this.amount,
    required this.currency,
    required this.renewalDate,
    required this.billingCycle,
    required this.reminder,
    required this.reminderType,
    required this.reminderDaysBefore,
    this.notificationId,
    this.notes,
    this.paymentMethod,
  }) : id = id ?? const Uuid().v4();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'category': category.value,
      'amount': amount,
      'currency': currency.value,
      'renewalDate': renewalDate.toIso8601String(),
      'billingCycle': billingCycle.value,
      'reminder': reminder.value,
      'reminderType': reminderType,
      'reminderDaysBefore': reminderDaysBefore,
      'notificationId': notificationId,
      'notes': notes,
      'paymentMethod': paymentMethod,
    };
  }

  // Create from Map (database)
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String,
      category: SubscriptionCategory.fromString(map['category'] as String),
      amount: map['amount'] as double,
      currency: Currency.fromString(map['currency'] as String),
      renewalDate: DateTime.parse(map['renewalDate'] as String),
      billingCycle: BillingCycle.fromString(map['billingCycle'] as String),
      reminder: ReminderTime.fromString(map['reminder'] as String),
      reminderType: map['reminderType'] as String? ?? 'none',
      reminderDaysBefore: map['reminderDaysBefore'] as int? ?? 0,
      notificationId: map['notificationId'] as String?,
      notes: map['notes'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }

  // Create a copy with updated fields
  Subscription copyWith({
    String? id,
    String? serviceName,
    SubscriptionCategory? category,
    double? amount,
    Currency? currency,
    DateTime? renewalDate,
    BillingCycle? billingCycle,
    ReminderTime? reminder,
    String? reminderType,
    int? reminderDaysBefore,
    String? notificationId,
    String? notes,
    String? paymentMethod,
  }) {
    return Subscription(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      renewalDate: renewalDate ?? this.renewalDate,
      billingCycle: billingCycle ?? this.billingCycle,
      reminder: reminder ?? this.reminder,
      reminderType: reminderType ?? this.reminderType,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notificationId: notificationId ?? this.notificationId,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  // Convert to Supabase format (for repository layer)
  Map<String, dynamic> toSupabaseMap({
    required String userId,
    required String categoryId,
  }) {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': serviceName,
      'amount': amount,
      'currency': currency.value,
      'renewal_date': renewalDate.toIso8601String(), // TIMESTAMPTZ format
      'billing_cycle': billingCycle.value.toLowerCase(),
      'reminder_days_before': reminderDaysBefore,
      'payment_last4': paymentMethod?.length == 4 ? paymentMethod : null,
      'notes': notes,
    };
  }

  // Create from Supabase format
  factory Subscription.fromSupabaseMap(
    Map<String, dynamic> map,
    SubscriptionCategory categoryEnum,
  ) {
    return Subscription(
      id: map['id'] as String,
      serviceName: map['title'] as String,
      category: categoryEnum,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: Currency.fromString(map['currency'] as String? ?? 'USD'),
      renewalDate: DateTime.parse(map['renewal_date'] as String),
      billingCycle: BillingCycle.fromString(map['billing_cycle'] as String),
      reminder: ReminderTime.values.firstWhere(
        (e) => e.value.contains('${map['reminder_days_before']} day'),
        orElse: () => ReminderTime.none,
      ),
      reminderType: (map['reminder_days_before'] as int?) != null ? 'preset' : 'none',
      reminderDaysBefore: map['reminder_days_before'] as int? ?? 0,
      notes: map['notes'] as String?,
      paymentMethod: map['payment_last4'] as String?,
    );
  }
}

