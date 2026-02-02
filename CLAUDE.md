# CLAUDE.md - MyReminder App Knowledge Base

> Comprehensive reference for understanding the MyReminder Flutter codebase architecture, patterns, and implementation details.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [State Management](#state-management)
4. [Data Layer](#data-layer)
5. [Core Features](#core-features)
6. [UI Patterns](#ui-patterns)
7. [Business Logic](#business-logic)
8. [Navigation](#navigation)
9. [Authentication](#authentication)
10. [Key Dependencies](#key-dependencies)
11. [Implementation Patterns](#implementation-patterns)
12. [File Reference](#file-reference)
13. [Conventions](#conventions)

---

## Project Overview

**MyReminder** is a production-grade Flutter application for managing subscriptions, appointments, and tasks with a "Modern Soft" design language.

**Key Characteristics:**
- Offline-first hybrid storage (Supabase + SQLite)
- Optimistic UI updates with rollback
- Provider pattern for state management
- Gesture-based interactions (swipe-to-renew)
- Multi-selection and bulk operations
- Dynamic undo timers with "Silent Safety" net

**Tech Stack:**
- Flutter SDK
- Supabase (PostgreSQL + Auth + RLS)
- SQLite (local caching)
- Provider (state management)
- Flutter Local Notifications

---

## Architecture

### Directory Structure

```
lib/
├── main.dart                   # App entry point, provider setup
├── database/                   # SQLite local database layer
│   └── database_helper.dart    # SQLite singleton with migrations
├── models/                     # Domain objects
│   ├── subscription.dart
│   ├── task.dart
│   ├── appointment.dart
│   ├── category.dart
│   └── user_profile.dart
├── providers/                  # State management (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── subscription_provider.dart
│   ├── task_provider.dart
│   ├── appointment_provider.dart
│   └── user_profile_provider.dart
├── repositories/               # Supabase data access layer
│   ├── subscription_repository.dart
│   ├── task_repository.dart
│   ├── appointment_repository.dart
│   └── category_repository.dart
├── services/                   # Business logic & external services
│   ├── subscription_service.dart       # Renewal calculation
│   ├── notification_service.dart       # Local notifications
│   ├── logout_service.dart             # Clean logout flow
│   └── secure_storage_service.dart     # Keychain access
├── utils/                      # Helper functions
│   └── subscription_status_helper.dart # Status computation
├── views/                      # Main screens
│   ├── main_navigation_view.dart       # Bottom nav + nested navigators
│   ├── subscriptions_list_view.dart
│   ├── subscription_form_view.dart
│   ├── tasks_list_view.dart
│   ├── appointments_list_view.dart
│   └── unified_agenda_view.dart        # Chronological dashboard
└── widgets/                    # Reusable UI components
    ├── modern_form_field.dart          # Styled input
    ├── empty_state_view.dart           # Empty state pattern
    ├── subscription_card.dart          # Stateful card with "Ghost" UI
    └── selection_app_bar.dart          # Multi-select toolbar
```

### Layered Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Views/Widgets)        │
├─────────────────────────────────────────┤
│       State Layer (Providers)           │
├─────────────────────────────────────────┤
│     Business Logic (Services/Utils)     │
├─────────────────────────────────────────┤
│  Data Access (Repositories + Database)  │
├─────────────────────────────────────────┤
│    Storage (Supabase + SQLite)          │
└─────────────────────────────────────────┘
```

**Data Flow:**
```
User Action → Widget
    ↓
Provider (optimistic update + notifyListeners)
    ↓
Service (business logic) [optional]
    ↓
Repository (Supabase) ⟷ DatabaseHelper (SQLite)
    ↓
On Success: State persisted
On Error: Rollback + reload
```

---

## State Management

### Provider Pattern

All providers extend `ChangeNotifier` and are registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ChangeNotifierProvider(create: (_) => TaskProvider()),
    ChangeNotifierProvider(create: (_) => AppointmentProvider()),
    // ...
  ],
  child: MyApp(),
)
```

### Core Providers

#### AuthProvider
**Location:** `lib/providers/auth_provider.dart`

**Responsibilities:**
- User authentication state
- Email/password and Google OAuth sign-in
- Password reset flow
- Email verification tracking
- Session management with "Remember Me"

**Key Methods:**
- `signUp(email, password)` - Email signup with verification
- `signIn(email, password)` - Email login
- `signInWithGoogle()` - OAuth login
- `signOut()` - Clean logout via LogoutService
- `sendPasswordResetEmail(email)` - Reset flow initiation

#### SubscriptionProvider
**Location:** `lib/providers/subscription_provider.dart`

**Responsibilities:**
- Subscription CRUD operations
- Renewal logic with undo functionality
- Bulk operations (multi-select renew/delete)
- Notification scheduling integration
- Performance optimization (batch category fetching)

**Key State:**
```dart
List<Subscription> _subscriptions = [];
Set<String> _selectedIds = {};
Map<String, Timer> _renewalTimers = {};
Map<String, int> _pendingRenewalDurations = {};
Set<String> _pendingRenewals = {};
bool _isLoading = false;
```

**Key Methods:**
- `loadSubscriptions()` - Fetch from Supabase/SQLite
- `addSubscription(sub)` - Create with optimistic update
- `updateSubscription(sub)` - Update with optimistic update
- `deleteSubscription(id)` - Delete with optimistic update
- `renewSubscription(id)` - Trigger renewal with timer
- `confirmRenewal(id)` - Commit pending renewal
- `undoRenewal(id)` - Cancel pending renewal
- `toggleSelection(id)` - Multi-select mode
- `renewSelectedSubscriptions()` - Bulk renewal
- `deleteSelectedSubscriptions()` - Bulk delete

**Optimistic Update Pattern:**
```dart
Future<void> updateSubscription(Subscription subscription) async {
  try {
    // 1. Immediate UI update
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      _subscriptions[index] = subscription;
      notifyListeners();
    }

    // 2. Persist to backend
    await _subscriptionRepository.update(subscription.id, subscription.toSupabaseMap());

  } catch (e) {
    // 3. Rollback on failure
    debugPrint('❌ Failed to update subscription: $e');
    await loadSubscriptions(forceRefresh: true);
    rethrow;
  }
}
```

#### TaskProvider & AppointmentProvider
**Locations:** `lib/providers/task_provider.dart`, `lib/providers/appointment_provider.dart`

**Similar structure to SubscriptionProvider:**
- Optimistic CRUD operations
- Completion status tracking
- Multi-selection support
- Rollback on error

---

## Data Layer

### Three-Tier Data Architecture

#### Tier 1: Models (Domain Objects)

All models follow a consistent pattern:

```dart
class Subscription {
  final String id;
  final String userId;
  final String name;
  final double cost;
  final BillingCycle billingCycle;
  final DateTime renewalDate;
  final bool isRenewed;
  final String? categoryId;
  // ...

  // SQLite serialization
  Map<String, dynamic> toMap() { /* ... */ }
  factory Subscription.fromMap(Map<String, dynamic> map) { /* ... */ }

  // Supabase serialization
  Map<String, dynamic> toSupabaseMap() { /* ... */ }
  factory Subscription.fromSupabaseMap(Map<String, dynamic> map) { /* ... */ }

  // Immutable updates
  Subscription copyWith({ /* ... */ }) { /* ... */ }
}
```

**Key Models:**
- `Subscription` - Recurring payments with renewal tracking
- `Task` - To-do items with optional due dates
- `Appointment` - Calendar events with location
- `Category` - Classification system
- `UserProfile` - User metadata

#### Tier 2: Repositories (Supabase Integration)

**Pattern:**
```dart
class SubscriptionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId);
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _client.from('subscriptions').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _client.from('subscriptions').update(data).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }
}
```

**Repositories:**
- `SubscriptionRepository`
- `TaskRepository`
- `AppointmentRepository`
- `CategoryRepository` (read-only)

#### Tier 3: DatabaseHelper (SQLite Caching)

**Location:** `lib/database/database_helper.dart`

**Pattern:** Singleton with migrations

```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('myreminder.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
  }
}
```

**Current Schema (v4):**
- `subscriptions` table
- `tasks` table
- `appointments` table
- Each table has `user_id` for multi-user support

**Dual-Mode Storage:**
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  // Online: save to Supabase
  await _subscriptionRepository.create(subscription.toSupabaseMap());
} else {
  // Offline: save to SQLite
  await DatabaseHelper.instance.insertSubscription(subscription.toMap());
}
```

---

## Core Features

### Subscriptions

#### Renewal Logic
**Location:** `lib/services/subscription_service.dart`

**Algorithm: Sticky End-of-Month**

Ensures that subscriptions renewing on month-end stay on month-end:

```dart
DateTime calculateNextRenewalDate(DateTime currentRenewalDate, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return currentRenewalDate.add(Duration(days: 7));

    case BillingCycle.monthly:
      return _addMonthsSticky(currentRenewalDate, 1);

    case BillingCycle.quarterly:
      return _addMonthsSticky(currentRenewalDate, 3);

    case BillingCycle.yearly:
      return _addMonthsSticky(currentRenewalDate, 12);
  }
}

DateTime _addMonthsSticky(DateTime date, int monthsToAdd) {
  // 1. Check if current date is last day of month
  final isLastDay = _isLastDayOfMonth(date);

  // 2. Calculate target year/month
  int targetMonth = date.month + monthsToAdd;
  int targetYear = date.year;
  while (targetMonth > 12) {
    targetMonth -= 12;
    targetYear++;
  }

  // 3. If was last day, set to last day of target month
  if (isLastDay) {
    return DateTime(targetYear, targetMonth + 1, 0); // Day 0 = last day of previous month
  }

  // 4. Otherwise, clamp day to valid range
  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final targetDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

  return DateTime(targetYear, targetMonth, targetDay);
}
```

**Example:**
- Jan 31 → Feb 28 (non-leap) → Mar 31 → Apr 30 → May 31
- Jan 15 → Feb 15 → Mar 15 (stays on 15th)

#### Swipe-to-Renew Gesture
**Location:** `lib/views/subscriptions_list_view.dart`

**Implementation:**
```dart
Dismissible(
  key: Key(subscription.id),
  direction: DismissDirection.startToEnd, // Right swipe only
  confirmDismiss: (direction) async {
    // Trigger renewal, but don't dismiss
    await provider.renewSubscription(subscription.id);
    return false; // Don't remove from list
  },
  background: Container(
    color: Colors.green,
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.only(left: 20),
    child: Icon(Icons.autorenew, color: Colors.white),
  ),
  child: SubscriptionCard(subscription: subscription),
)
```

#### Renewal Timer System ("Silent Safety")

**Dynamic Undo Windows:**
- **Standard renewal** (today or overdue): 10-second undo
- **Early renewal** (future date): 30-second undo

**State Management:**
```dart
// In SubscriptionProvider
Map<String, Timer> _renewalTimers = {};
Map<String, int> _pendingRenewalDurations = {};
Set<String> _pendingRenewals = {};

Future<void> renewSubscription(String subscriptionId) async {
  final subscription = _subscriptions.firstWhere((s) => s.id == subscriptionId);
  final now = DateTime.now();
  final isEarlyRenewal = subscription.renewalDate.isAfter(now);

  // Set duration: 30s for early, 10s for standard
  final timerDuration = isEarlyRenewal ? 30 : 10;
  _pendingRenewalDurations[subscriptionId] = timerDuration;
  _pendingRenewals.add(subscriptionId);
  notifyListeners();

  // Start countdown timer
  _renewalTimers[subscriptionId] = Timer(Duration(seconds: timerDuration), () {
    confirmRenewal(subscriptionId);
  });
}

void undoRenewal(String subscriptionId) {
  _renewalTimers[subscriptionId]?.cancel();
  _renewalTimers.remove(subscriptionId);
  _pendingRenewalDurations.remove(subscriptionId);
  _pendingRenewals.remove(subscriptionId);
  notifyListeners();
}

Future<void> confirmRenewal(String subscriptionId) async {
  // Calculate new renewal date
  final subscription = _subscriptions.firstWhere((s) => s.id == subscriptionId);
  final newDate = SubscriptionService.calculateNextRenewalDate(
    subscription.renewalDate,
    subscription.billingCycle,
  );

  // Update subscription
  final updated = subscription.copyWith(renewalDate: newDate, isRenewed: true);
  await updateSubscription(updated);

  // Clean up timer state
  _renewalTimers.remove(subscriptionId);
  _pendingRenewalDurations.remove(subscriptionId);
  _pendingRenewals.remove(subscriptionId);
}
```

**Visual Feedback:**
```dart
// In SubscriptionCard widget
if (_isInPendingRenewalState) {
  // Show green "Ghost Card" UI
  Container(
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        LinearProgressIndicator(value: _progress), // Countdown
        ElevatedButton(
          onPressed: () => provider.undoRenewal(subscription.id),
          child: Text('Undo (${_remainingSeconds}s)'),
        ),
      ],
    ),
  )
}
```

#### Multi-Selection & Bulk Operations

**Activation:**
- Long-press on any card enters selection mode
- Haptic feedback on selection

**UI Changes:**
- Selected cards show blue border + checkmark
- `SelectionAppBar` replaces normal AppBar
- Shows count + Clear + Delete + Renew actions

**Implementation:**
```dart
// In SubscriptionProvider
Set<String> _selectedIds = {};
bool get isInSelectionMode => _selectedIds.isNotEmpty;

void toggleSelection(String id) {
  if (_selectedIds.contains(id)) {
    _selectedIds.remove(id);
  } else {
    _selectedIds.add(id);
  }
  notifyListeners();
}

Future<void> renewSelectedSubscriptions() async {
  final List<String> idsToRenew = _selectedIds.toList();
  for (final id in idsToRenew) {
    await renewSubscription(id);
  }
  clearSelection();
}

Future<void> deleteSelectedSubscriptions() async {
  final List<String> idsToDelete = _selectedIds.toList();
  for (final id in idsToDelete) {
    await deleteSubscription(id);
  }
  clearSelection();
}
```

### Tasks & Appointments

#### Appointment Completion with Swipe Gesture ("Ghost Card" Pattern)

Similar to tasks, appointments now use a gesture-based completion system:

**Swipe-to-Complete:**
- **Left-to-Right swipe** triggers appointment completion
- 10-second "Silent Safety" undo window
- "Ghost Card" UI during pending state with green background
- Preserves the original design with status bar and time display

**Implementation:**
- `AppointmentProvider` has same timer methods as `TaskProvider`
- `AppointmentCard` widget maintains the time display, location, and status bar design
- Ghost Card shows countdown timer with "Undo" button
- Status bar color indicates appointment timing (orange=today, blue=future, grey=past)

#### Task Completion with Swipe Gesture ("Ghost Card" Pattern)

Similar to subscription renewals, tasks now use a gesture-based completion system:

**Swipe-to-Complete:**
- **Left-to-Right swipe** triggers task completion
- 10-second "Silent Safety" undo window
- "Ghost Card" UI during pending state

**Implementation:**
```dart
// In TaskProvider
final Map<String, Timer> _completionTimers = {};
final Map<String, int> _pendingCompletionDurations = {};
final Set<String> _pendingCompletions = {};

Future<void> startTaskCompletion(String taskId) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);

  // 10-second undo timer
  const timerDuration = 10;
  _pendingCompletionDurations[taskId] = timerDuration;
  _pendingCompletions.add(taskId);
  notifyListeners();

  // Start countdown
  _completionTimers[taskId] = Timer(Duration(seconds: timerDuration), () {
    confirmTaskCompletion(taskId);
  });
}

void undoTaskCompletion(String taskId) {
  _completionTimers[taskId]?.cancel();
  _completionTimers.remove(taskId);
  _pendingCompletionDurations.remove(taskId);
  _pendingCompletions.remove(taskId);
  notifyListeners();
}

Future<void> confirmTaskCompletion(String taskId) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);
  final updatedTask = task.copyWith(isCompleted: true);
  await updateTask(updatedTask);

  // Clean up timer state
  _completionTimers.remove(taskId);
  _pendingCompletionDurations.remove(taskId);
  _pendingCompletions.remove(taskId);
}
```

**UI Implementation:**
```dart
// In TasksListView - Dismissible wrapper
Dismissible(
  key: Key(task.id),
  direction: DismissDirection.startToEnd, // Left-to-right only
  background: Container(
    color: Colors.green,
    alignment: Alignment.centerLeft,
    child: Icon(Icons.check_circle, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    await provider.startTaskCompletion(task.id);
    return false; // Don't actually dismiss
  },
  child: TaskCard(task: task),
)
```

**TaskCard Widget:**
- Stateless widget with visual design matching SubscriptionCard
- Standalone container with rounded corners (`BorderRadius.circular(16)`)
- Soft shadows for depth (`BoxShadow` with 0.03 opacity)
- Shows normal card or "Ghost Card" based on pending state
- Uses `TweenAnimationBuilder` for smooth countdown animation
- "Ghost Card" features:
  - Green tinted background
  - Progress bar with countdown (10 → 0 seconds)
  - "Undo" button with remaining seconds display
  - Disabled tap interaction
- No longer uses SmartListTile wrapper (removed status strip for cleaner design)

**Filtering:**
```dart
// Separate lists for active and completed
List<Task> get activeTasks => _tasks.where((t) => !t.isCompleted).toList();
List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
```

**Visual Feedback:**
- Tasks: Clean card without checkbox, swipe to complete
- Appointments: Checkmark icon

#### Reminders

**ReminderOffset Enum:**
```dart
enum ReminderOffset {
  none,
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  oneDay,
}
```

**Notification Scheduling:**
```dart
// For tasks/appointments with due dates
final reminderTime = dueDate.subtract(offset.duration);
await NotificationService.instance.scheduleReminder(
  id: task.id,
  title: task.title,
  body: 'Due ${formatDate(task.dueDate)}',
  scheduledTime: reminderTime,
);
```

---

## UI Patterns

### Design System: "Modern Soft"

**Color Palette:**
```dart
const kBackgroundColor = Color(0xFFFAFAFA);        // Colors.grey[50]
const kSurfaceColor = Colors.white;
const kBrandBlue = Color(0xFF2D62ED);
const kUrgencyOrange = Colors.orange;
const kSafeGreen = Colors.teal;
const kTextPrimary = Color(0xFF212121);           // Colors.grey[900]
const kTextSecondary = Color(0xFF757575);         // Colors.grey[600]
```

**Shadows:**
```dart
BoxShadow(
  color: Colors.black.withOpacity(0.03),
  blurRadius: 10,
  offset: Offset(0, 4),
)
```

**Border Radius:**
- Cards: `BorderRadius.circular(16-20)`
- Inputs: `BorderRadius.circular(12)`
- Buttons: `BorderRadius.circular(12)`

### ModernFormField
**Location:** `lib/widgets/modern_form_field.dart`

**Features:**
- Label positioned outside and above field
- Filled grey background (`Colors.grey[100]`)
- No border stroke (borderless)
- Blue focus border (brand color)
- Rounded corners (12px)
- Optional prefix/suffix icons

**Usage:**
```dart
ModernFormField(
  label: 'Subscription Name',
  hint: 'e.g., Netflix',
  controller: _nameController,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

### EmptyStateView
**Location:** `lib/widgets/empty_state_view.dart`

**Pattern:**
- Large circular icon with colored background
- Title (bold)
- Description (lighter)
- CTA button (optional)

**Usage:**
```dart
EmptyStateView(
  icon: Icons.subscriptions,
  iconColor: Colors.blue,
  title: 'No Subscriptions Yet',
  description: 'Add your first subscription to start tracking.',
  actionLabel: 'Add Subscription',
  onAction: () => Navigator.push(...),
)
```

### SubscriptionCard
**Location:** `lib/widgets/subscription_card.dart`

**Complex Stateful Widget with Multiple States:**

**Normal State:**
- Avatar (initials on colored background)
- Subscription name
- Renewal date with status color
- Cost
- Progress bar (cycle completion)

**Pending Renewal State ("Ghost Card"):**
- Green tinted background
- Linear progress indicator (countdown)
- "Undo" button with remaining seconds
- Disabled interaction

**Selected State:**
- Blue border
- Checkmark icon
- Slightly elevated

**Status Color Coding:**
```dart
// Based on subscription_status_helper.dart
Color getStatusColor(SubscriptionStatus status) {
  switch (status) {
    case SubscriptionStatus.overdue:
      return Colors.red.shade400;
    case SubscriptionStatus.dueToday:
      return Colors.orange;
    case SubscriptionStatus.normal:
      return Colors.teal;
  }
}
```

### SelectionAppBar
**Location:** `lib/widgets/selection_app_bar.dart`

**Features:**
- Replaces normal AppBar in selection mode
- Shows selected count
- Close button (exit selection mode)
- Delete button (bulk delete)
- Renew button (bulk renew, for subscriptions)

**Usage:**
```dart
if (provider.isInSelectionMode)
  SelectionAppBar(
    selectedCount: provider.selectedIds.length,
    onClose: provider.clearSelection,
    onDelete: provider.deleteSelectedSubscriptions,
    onRenew: provider.renewSelectedSubscriptions, // Optional
  )
else
  AppBar(title: Text('Subscriptions'))
```

### Unified Agenda View
**Location:** `lib/views/unified_agenda_view.dart`

**Purpose:** Chronological dashboard combining all item types

**Implementation:**
```dart
class UnifiedAgendaView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<SubscriptionProvider>().subscriptions;
    final appointments = context.watch<AppointmentProvider>().activeAppointments;
    final tasks = context.watch<TaskProvider>().activeTasks;

    // Combine all items
    final allItems = [
      ...subscriptions.map((s) => AgendaItem.fromSubscription(s)),
      ...appointments.map((a) => AgendaItem.fromAppointment(a)),
      ...tasks.map((t) => AgendaItem.fromTask(t)),
    ];

    // Sort by date
    allItems.sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        return _buildItemCard(item);
      },
    );
  }
}
```

---

## Business Logic

### Subscription Status Helper
**Location:** `lib/utils/subscription_status_helper.dart`

**Status Calculation:**
```dart
enum SubscriptionStatus { overdue, dueToday, normal }

SubscriptionStatus getSubscriptionStatus(DateTime renewalDate) {
  final now = DateTime.now().toUtc();
  final renewal = renewalDate.toUtc();

  // Convert to timestamps for precise comparison
  final nowTimestamp = now.millisecondsSinceEpoch;
  final renewalTimestamp = renewal.millisecondsSinceEpoch;

  if (renewalTimestamp < nowTimestamp) {
    return SubscriptionStatus.overdue;
  }

  // Check if same calendar day
  final nowDate = DateTime(now.year, now.month, now.day);
  final renewalDate = DateTime(renewal.year, renewal.month, renewal.day);

  if (nowDate == renewalDate) {
    return SubscriptionStatus.dueToday;
  }

  return SubscriptionStatus.normal;
}
```

**Renewal Text Generation:**
```dart
String getRenewalText(DateTime renewalDate) {
  final now = DateTime.now();
  final difference = renewalDate.difference(now).inDays;

  if (difference < 0) {
    return 'Overdue by ${-difference} day${-difference == 1 ? '' : 's'}';
  } else if (difference == 0) {
    return 'Due today';
  } else if (difference == 1) {
    return 'Renews tomorrow';
  } else {
    return 'Renews in $difference days';
  }
}
```

**Progress Calculation:**
```dart
double calculateProgress(Subscription subscription) {
  final now = DateTime.now();
  final cycleInDays = subscription.billingCycle.inDays;
  final lastRenewal = subscription.renewalDate.subtract(Duration(days: cycleInDays));
  final elapsed = now.difference(lastRenewal).inDays;

  return (elapsed / cycleInDays).clamp(0.0, 1.0);
}
```

### Category Resolution

**Problem:** N+1 query when loading subscriptions with categories

**Solution:** Batch fetch categories

```dart
// In SubscriptionProvider.loadSubscriptions()
Future<void> loadSubscriptions({bool forceRefresh = false}) async {
  try {
    _isLoading = true;
    notifyListeners();

    // 1. Fetch all categories once
    final allCategories = await _categoryRepository.getAll();
    final categoryMap = <String, Category>{};
    for (final category in allCategories) {
      categoryMap[category.id] = category;
    }

    // 2. Fetch subscriptions
    final data = await _subscriptionRepository.getAll();

    // 3. Map subscriptions with category lookup
    _subscriptions = data.map((row) {
      final sub = Subscription.fromSupabaseMap(row);
      if (sub.categoryId != null && categoryMap.containsKey(sub.categoryId)) {
        return sub.copyWith(category: categoryMap[sub.categoryId]);
      }
      return sub;
    }).toList();

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    debugPrint('❌ Error loading subscriptions: $e');
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## Navigation

### Nested Navigator Pattern
**Location:** `lib/views/main_navigation_view.dart`

**Architecture:**
```
RootNavigator (AuthGate)
    │
    ├─ LoginScreen
    ├─ SignupScreen
    └─ MainNavigationView (BottomNavigationBar)
           │
           ├─ Home Tab (homeNavigatorKey)
           │      └─ Navigator stack: [WelcomeView, SubscriptionListView, ...]
           │
           └─ Settings Tab (settingsNavigatorKey)
                  └─ Navigator stack: [SettingsView, ProfileView, ...]
```

**Benefits:**
- Bottom bar persists across tab navigation
- Each tab maintains its own back stack
- Prevents navigation conflicts

**Implementation:**
```dart
class MainNavigationView extends StatefulWidget {
  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _settingsNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildNavigator(_homeNavigatorKey, WelcomeView()),
          _buildNavigator(_settingsNavigatorKey, SettingsView()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavigator(GlobalKey<NavigatorState> key, Widget home) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => home);
      },
    );
  }
}
```

**Bottom Bar Visibility:**
```dart
// Uses RouteObserver to detect current route
class _MainNavigationViewState extends State<MainNavigationView> with RouteAware {
  bool _showBottomBar = true;
  final _routeObserver = RouteObserver<PageRoute>();

  // Hide bottom bar on specific screens
  final _screensWithoutBottomBar = [
    'SubscriptionFormView',
    'TaskFormView',
    'AppointmentFormView',
    'ProfileView',
    'AccountDeletionView',
  ];

  @override
  void didPush() {
    final route = ModalRoute.of(context);
    if (route != null) {
      final shouldHide = _screensWithoutBottomBar.contains(route.settings.name);
      setState(() => _showBottomBar = !shouldHide);
    }
  }
}
```

**Global Navigation Keys:**
```dart
// Defined in MainNavigationKeys class
class MainNavigationKeys {
  static final GlobalKey<NavigatorState> homeNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> settingsNavigatorKey = GlobalKey<NavigatorState>();
}

// Usage from anywhere:
MainNavigationKeys.homeNavigatorKey.currentState?.push(
  MaterialPageRoute(builder: (_) => SubscriptionFormView()),
);
```

---

## Authentication

### Supabase Auth
**Location:** `lib/providers/auth_provider.dart`

**Supported Methods:**
1. Email/Password (with verification)
2. Google OAuth

**Authentication Flow:**
```
App Launch
    ↓
AuthGate checks session
    ↓
    ├─ No Session → LoginScreen
    │
    ├─ Session + Unverified Email → EmailVerificationView
    │       (flag stored in SharedPreferences during signup)
    │
    ├─ Session + Password Reset Flag → ResetPasswordScreen
    │       (flag set when user clicks reset email link)
    │
    └─ Session + Verified → MainNavigationView
```

**Email/Password Signup:**
```dart
Future<void> signUp(String email, String password) async {
  try {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'myreminders://auth-callback',
    );

    // Set verification flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_verification_pending', true);

    notifyListeners();
  } catch (e) {
    throw Exception('Signup failed: $e');
  }
}
```

**Email/Password Sign In:**
```dart
Future<void> signIn(String email, String password) async {
  try {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Clear verification flag if exists
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email_verification_pending');

    notifyListeners();
  } catch (e) {
    throw Exception('Sign in failed: $e');
  }
}
```

**Google OAuth:**
```dart
Future<void> signInWithGoogle() async {
  try {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'myreminders://auth-callback',
    );

    // Profile automatically created via Supabase trigger
    notifyListeners();
  } catch (e) {
    throw Exception('Google sign in failed: $e');
  }
}
```

**Session Management:**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Check "Remember Me" preference
  final rememberMe = await SecureStorageService.instance.getRememberMe();
  if (!rememberMe) {
    await Supabase.instance.client.auth.signOut();
  }

  runApp(MyApp());
}
```

**Password Reset Flow:**
```dart
// 1. User requests reset
Future<void> sendPasswordResetEmail(String email) async {
  await _supabase.auth.resetPasswordForEmail(
    email,
    redirectTo: 'myreminders://auth-callback',
  );

  // Set flag for AuthGate to detect
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('password_reset_pending', true);
}

// 2. User clicks email link → app opens with session
// 3. AuthGate detects flag + session → shows ResetPasswordScreen

// 4. User updates password
Future<void> updatePassword(String newPassword) async {
  await _supabase.auth.updateUser(UserAttributes(password: newPassword));

  // Clear flag and sign out
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('password_reset_pending');
  await signOut();
}
```

**Clean Logout:**
```dart
// Uses LogoutService for clean navigation stack reset
Future<void> signOut() async {
  await LogoutService.signOut(context);
}

// In LogoutService:
static Future<void> signOut(BuildContext context) async {
  // 1. Clear all provider data
  context.read<SubscriptionProvider>().clearData();
  context.read<TaskProvider>().clearData();
  context.read<AppointmentProvider>().clearData();

  // 2. Sign out from Supabase
  await Supabase.instance.client.auth.signOut();

  // 3. Reset navigation stack
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => AuthGate()),
    (route) => false,
  );
}
```

---

## Key Dependencies

**From `pubspec.yaml`:**

### State Management
- `provider: ^6.1.2` - Reactive state management with ChangeNotifier

### Backend & Database
- `supabase_flutter: ^2.0.0` - Backend-as-a-Service (PostgreSQL + Auth + Storage)
- `sqflite: ^2.3.3+1` - SQLite for local caching
- `path: ^1.9.0` - Path manipulation for SQLite database

### Notifications
- `flutter_local_notifications: ^19.5.0` - Local push notifications
- `timezone: ^0.10.1` - Timezone-aware scheduling

### Utilities
- `uuid: ^4.5.1` - UUID generation for IDs
- `intl: ^0.19.0` - Internationalization and date formatting
- `flutter_dotenv: ^5.1.0` - Environment variable management
- `shared_preferences: ^2.2.2` - Simple key-value storage
- `flutter_secure_storage: ^9.0.0` - Secure storage (Keychain/Keystore)

### UI
- `fl_chart: ^1.1.1` - Beautiful charts (bar chart for spending visualization)

### Testing
- `mockito: ^5.4.4` - Mocking framework
- `build_runner: ^2.4.8` - Code generation for tests

---

## Implementation Patterns

### Pattern 1: Optimistic Updates

**Used throughout all providers for instant UI feedback:**

```dart
Future<void> updateItem(Item item) async {
  try {
    // Step 1: Optimistically update local state
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners(); // ← Instant UI update
    }

    // Step 2: Persist to backend (async)
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _repository.update(item.id, item.toSupabaseMap());
    } else {
      await DatabaseHelper.instance.update(item.toMap());
    }

  } catch (e) {
    // Step 3: Rollback on failure
    debugPrint('❌ Update failed: $e');
    await loadItems(forceRefresh: true); // Reload from source
    rethrow; // Let UI handle error
  }
}
```

**Benefits:**
- No loading spinners for CRUD operations
- App feels instant and responsive
- Graceful error handling with rollback

### Pattern 2: Dual-Mode Storage (Online/Offline)

**Used in all data persistence operations:**

```dart
final user = Supabase.instance.client.auth.currentUser;

if (user != null) {
  // Online mode: persist to Supabase (cloud)
  await _subscriptionRepository.create(subscription.toSupabaseMap());
} else {
  // Offline mode: persist to SQLite (local)
  await DatabaseHelper.instance.insertSubscription(subscription.toMap());
}
```

**Data Loading:**
```dart
Future<void> loadSubscriptions({bool forceRefresh = false}) async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user != null) {
    // Load from Supabase
    final data = await _subscriptionRepository.getAll();
    _subscriptions = data.map((row) => Subscription.fromSupabaseMap(row)).toList();
  } else {
    // Load from SQLite
    final data = await DatabaseHelper.instance.getSubscriptions();
    _subscriptions = data.map((row) => Subscription.fromMap(row)).toList();
  }

  notifyListeners();
}
```

### Pattern 3: Lazy Loading

**Providers don't load data in constructor:**

```dart
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider() {
    // Constructor is lightweight, no async operations
  }

  // Data loaded when screen is shown
  Future<void> loadSubscriptions() async { /* ... */ }
}
```

**In Views:**
```dart
@override
void initState() {
  super.initState();

  // Load data after widget tree is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<SubscriptionProvider>().loadSubscriptions();
  });
}
```

**Benefits:**
- Faster app startup
- Data only loaded when needed
- Avoid race conditions with widget tree

### Pattern 4: Notification Preferences Check

**Before scheduling any notification:**

```dart
final notificationPrefs = NotificationPreferencesService.instance;
final enabled = await notificationPrefs.areSubscriptionNotificationsEnabled();

if (enabled && subscription.reminderDaysBefore != null) {
  final reminderDate = subscription.renewalDate.subtract(
    Duration(days: subscription.reminderDaysBefore!),
  );

  await NotificationService.instance.scheduleReminder(
    id: subscription.id,
    title: 'Subscription Renewal',
    body: '${subscription.name} renews soon',
    scheduledTime: reminderDate,
  );
}
```

### Pattern 5: Deduplication

**When loading data from Supabase (which may have duplicates):**

```dart
Future<void> loadSubscriptions() async {
  final data = await _subscriptionRepository.getAll();

  // Use Map to deduplicate by ID (last-one-wins)
  final Map<String, Subscription> mapped = {};
  for (final row in data) {
    final subscription = Subscription.fromSupabaseMap(row);
    mapped[subscription.id] = subscription;
  }

  _subscriptions = mapped.values.toList();
  notifyListeners();
}
```

### Pattern 6: Timer Cleanup

**Always clean up timers to prevent memory leaks:**

```dart
class SubscriptionProvider extends ChangeNotifier {
  Map<String, Timer> _renewalTimers = {};

  @override
  void dispose() {
    // Cancel all active timers
    for (final timer in _renewalTimers.values) {
      timer.cancel();
    }
    _renewalTimers.clear();
    super.dispose();
  }

  void cancelRenewalTimer(String subscriptionId) {
    _renewalTimers[subscriptionId]?.cancel();
    _renewalTimers.remove(subscriptionId);
  }
}
```

### Pattern 7: Safe State Updates

**Always check `mounted` before calling `setState()` in async callbacks:**

```dart
Future<void> loadData() async {
  final data = await fetchData();

  if (!mounted) return; // Widget disposed, don't update

  setState(() {
    _data = data;
  });
}
```

---

## File Reference

### Critical Files by Feature

#### Entry Point
- `lib/main.dart` - App initialization, provider setup, Supabase configuration

#### Authentication
- `lib/providers/auth_provider.dart` - Auth state management
- `lib/widgets/auth_gate.dart` - Authentication routing logic
- `lib/views/login_screen.dart` - Login UI
- `lib/views/signup_screen.dart` - Signup UI
- `lib/services/logout_service.dart` - Clean logout flow

#### Subscriptions
- `lib/providers/subscription_provider.dart` - State + business logic
- `lib/services/subscription_service.dart` - Renewal calculation algorithm
- `lib/utils/subscription_status_helper.dart` - Status computation
- `lib/views/subscriptions_list_view.dart` - List UI with swipe gestures
- `lib/views/subscription_form_view.dart` - Add/Edit form
- `lib/widgets/subscription_card.dart` - Card component with "Ghost" UI
- `lib/repositories/subscription_repository.dart` - Supabase data access

#### Tasks
- `lib/providers/task_provider.dart` - State management with completion timers
- `lib/views/tasks_list_view.dart` - List UI with swipe-to-complete
- `lib/views/task_form_view.dart` - Add/Edit form
- `lib/widgets/task_card.dart` - Stateful card with "Ghost Card" UI
- `lib/repositories/task_repository.dart` - Supabase data access

#### Appointments
- `lib/providers/appointment_provider.dart` - State management with completion timers
- `lib/views/appointments_list_view.dart` - List UI with swipe-to-complete
- `lib/views/appointment_form_view.dart` - Add/Edit form
- `lib/widgets/appointment_card.dart` - Stateful card with "Ghost Card" UI (NEW)
- `lib/repositories/appointment_repository.dart` - Supabase data access

#### Navigation
- `lib/views/main_navigation_view.dart` - Bottom nav + nested navigators
- `lib/views/welcome_view.dart` - Home dashboard

#### Shared UI Components
- `lib/widgets/modern_form_field.dart` - Styled input field
- `lib/widgets/empty_state_view.dart` - Empty state pattern
- `lib/widgets/selection_app_bar.dart` - Multi-select toolbar

#### Data Layer
- `lib/database/database_helper.dart` - SQLite singleton
- `lib/models/*` - Domain objects

#### Services
- `lib/services/notification_service.dart` - Local notifications
- `lib/services/secure_storage_service.dart` - Keychain access

---

## Conventions

### Naming Conventions

**Files:**
- `snake_case.dart` for all Dart files
- Match class name: `SubscriptionProvider` → `subscription_provider.dart`

**Classes:**
- `PascalCase` for all classes
- Suffix for type clarity:
  - `*Provider` for state management
  - `*Repository` for data access
  - `*Service` for business logic
  - `*View` for screens
  - `*Helper` for utilities

**Variables:**
- `camelCase` for public fields/methods
- `_leadingUnderscore` for private fields/methods
- `kCamelCase` for constants (or `SCREAMING_SNAKE_CASE`)

**Example:**
```dart
class SubscriptionProvider extends ChangeNotifier {
  // Private state
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  // Public getters
  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  // Public methods
  Future<void> loadSubscriptions() async { /* ... */ }

  // Private methods
  Future<void> _fetchFromSupabase() async { /* ... */ }
}
```

### Error Handling

**Pattern:**
```dart
try {
  // Attempt operation
  await riskyOperation();
} catch (e) {
  // Log error with emoji prefix
  debugPrint('❌ Operation failed: $e');

  // Rollback optimistic update
  await reloadFromSource();

  // Rethrow for UI to handle
  rethrow;
}
```

**Logging Emoji Prefixes:**
- 🔔 Notifications
- 💳 Subscriptions
- 📅 Appointments
- ✅ Tasks
- 🔐 Auth
- 🏷️ Categories
- ❌ Errors

### State Updates

**Provider Pattern:**
```dart
// Always call notifyListeners() after state change
void updateState() {
  _value = newValue;
  notifyListeners(); // ← Required
}
```

**Widget Pattern:**
```dart
// Always check mounted before setState() in async callbacks
Future<void> asyncOperation() async {
  final result = await fetchData();

  if (!mounted) return; // Widget may be disposed

  setState(() {
    _data = result;
  });
}
```

### Code Organization

**Separation of Concerns:**
- **Views** - UI only, no business logic
- **Providers** - State management + orchestration
- **Services** - Stateless business logic
- **Repositories** - Thin wrappers over Supabase
- **Utils** - Pure functions (no side effects)

**Import Order:**
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter framework
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Project imports
import 'package:myreminder/models/subscription.dart';
import 'package:myreminder/providers/subscription_provider.dart';
```

### Documentation

**Comment Style:**
```dart
/// Public API documentation using triple-slash
///
/// Explains what the method does, parameters, and return value
Future<void> loadSubscriptions({bool forceRefresh = false}) async {
  // Implementation comments using double-slash
  // Explain the "why" not the "what"
}
```

**Inline Comments:**
- Use sparingly, only when code is non-obvious
- Prefer self-documenting code (good naming)

---

## Recent Changes (Current Branch: feature/fix-subs-DV)

**Modified Files:**
- `docs/brainstorming_myreminder_gemini.md` - Updated documentation
- `docs/prompts/prompt.md` - Updated prompts
- `docs/technical_documentation.md` - Updated technical specs
- `lib/providers/subscription_provider.dart` - Renewal timer fixes
- `lib/providers/task_provider.dart` - Added completion timer logic (NEW)
- `lib/views/appointment_form_view.dart` - Form improvements
- `lib/views/subscription_form_view.dart` - Form improvements
- `lib/views/subscriptions_list_view.dart` - Swipe gesture refinements
- `lib/views/task_form_view.dart` - Form improvements
- `lib/views/tasks_list_view.dart` - Swipe-to-complete gesture (REFACTORED)
- `lib/views/appointments_list_view.dart` - Swipe-to-complete gesture (REFACTORED)
- `lib/views/unified_agenda_view.dart` - UI polish
- `lib/widgets/selection_app_bar.dart` - Multi-select enhancements
- `lib/widgets/subscription_card.dart` - "Ghost Card" UI refinements
- `lib/widgets/task_card.dart` - Stateful card with "Ghost" UI (NEW)
- `lib/widgets/appointment_card.dart` - Stateful card with "Ghost" UI (NEW)
- `CLAUDE.md` - Comprehensive knowledge base (NEW)

**Recent Commits:**
- `243a839` - Feature/task appnt enhance dv (#41)
- `626a132` - Fixes (#40)
- `eb5b7ef` - Implement Renewal Logic (#39)
- `2ff5fa7` - Feature/renew list screens dv (#38)
- `e5eeada` - Fixes (#37)

---

## Summary

MyReminder is a well-architected Flutter application demonstrating:

1. **Clean Architecture** - Layered design with clear separation of concerns
2. **Offline-First** - Hybrid Supabase + SQLite storage with optimistic updates
3. **Modern UX** - Gesture-based interactions, "Silent Safety" undo timers, instant feedback
4. **Robust State** - Provider pattern with consistent error handling and rollback
5. **Production Quality** - Comprehensive business logic (sticky end-of-month, status computation)

**Key Strengths:**
- Consistent code patterns across features
- Strong error handling with user-friendly fallbacks
- Performance optimizations (batch loading, deduplication)
- Polished UI with "Modern Soft" design system
- Thorough documentation in codebase

**Architecture Highlights:**
- Three-tier data layer (Models → Repositories → Database)
- Nested navigation for tab persistence
- Optimistic updates for instant UX
- Dynamic undo timers (10s/30s based on context)
- Multi-selection with bulk operations

This knowledge base should serve as a comprehensive reference for understanding, maintaining, and extending the MyReminder application.
