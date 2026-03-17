# Complete Firestore Integration Guide for SGuard App

## Overview
Your app currently uses local state. This guide shows how to integrate the new Firestore system step-by-step.

---

## STEP 1: Update Your RecordBookPage

### Current State
- Uses `SpendingCategory` and `SpendingItem` (local classes)
- Data stored in `RecordBookData` static variables
- No Firestore persistence

### Required Changes
Replace the local data model with Firestore integration.

**File**: `lib/presentation/pages/recordbook/recordbookpage.dart`

**Changes needed**:

1. **Add imports**:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fully_cloud_sguard/data/repositories/repository_provider.dart';
import 'package:fully_cloud_sguard/domain/entities/expense.dart';
```

2. **Remove these static classes** (you can delete them):
   - `SpendingItem` class
   - `SpendingCategory` class
   - `RecordBookData` class

3. **Update `_RecordBookPageState` to use Firestore**:

```dart
class _RecordBookPageState extends State<RecordBookPage> {
  late final RepositoryProvider _repositories = RepositoryProvider();
  late final String _userId = FirebaseAuth.instance.currentUser!.uid;
  
  double balance = 0.0;
  DateTime startDate = DateTime(2026, 1, 1);
  DateTime endDate = DateTime(2026, 2, 1);
  
  @override
  void initState() {
    super.initState();
    _loadUserBalance();
  }
  
  Future<void> _loadUserBalance() async {
    final user = await _repositories.userRepository.getUserAccount(_userId);
    if (user != null) {
      setState(() => balance = user.balance);
    }
  }
  
  // Replace category/item management with Firestore calls
}
```

4. **Replace add expense logic**:

Instead of:
```dart
// OLD: setState(() { RecordBookData.categories.add(...) })
```

Use:
```dart
// NEW: Save to Firestore
final newExpense = Expense(
  id: '',
  userId: _userId,
  category: categoryName,
  amount: amount,
  description: description,
  date: DateTime.now(),
  createdAt: DateTime.now(),
);

await _repositories.expenseRepository.addExpense(newExpense);
setState(() {}); // Refresh UI
```

5. **Replace expense display with streaming**:

Instead of displaying static `RecordBookData.categories`:
```dart
// NEW: Stream expenses from Firestore
StreamBuilder<List<Expense>>(
  stream: _repositories.expenseRepository.streamUserExpenses(_userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text('No expenses yet');
    }
    
    final expenses = snapshot.data!;
    // Group by category and display
    return _buildCategoryList(expenses);
  },
)
```

---

## STEP 2: Update Registration Page

**File**: `lib/presentation/pages/signin_or_signup/registerpage.dart`

After user registration, save their account to Firestore:

```dart
// After: final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(...)

try {
  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  
  // NEW: Save user to Firestore
  final repositories = RepositoryProvider();
  final newUser = UserAccount(
    uid: credential.user!.uid,
    email: email,
    name: name, // You need to ask for name in the form
    balance: 0.0, // Starting balance
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  await repositories.userRepository.saveUserAccount(newUser);
  
  Navigator.of(context).pushReplacementNamed('/home');
} on FirebaseAuthException catch (e) {
  // Handle error
}
```

**Add import**:
```dart
import 'package:fully_cloud_sguard/data/repositories/repository_provider.dart';
import 'package:fully_cloud_sguard/domain/entities/user_account.dart';
```

---

## STEP 3: Update Profile Page

**File**: `lib/presentation/pages/profile/profile_action_page.dart`

Show user data from Firestore and allow balance updates:

```dart
import 'package:fully_cloud_sguard/data/repositories/repository_provider.dart';

class ProfileActionPage extends StatefulWidget {
  @override
  State<ProfileActionPage> createState() => _ProfileActionPageState();
}

class _ProfileActionPageState extends State<ProfileActionPage> {
  late final RepositoryProvider _repositories = RepositoryProvider();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return FutureBuilder(
      future: _repositories.userRepository.getUserAccount(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData) {
          return const Text('User not found');
        }
        
        final userAccount = snapshot.data!;
        
        return Column(
          children: [
            Text('Name: ${userAccount.name}'),
            Text('Email: ${userAccount.email}'),
            Text('Balance: \$${userAccount.balance}'),
            ElevatedButton(
              onPressed: () => _updateBalance(user.uid),
              child: const Text('Update Balance'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _updateBalance(String uid) async {
    // Show dialog to enter new balance
    final newBalance = 1500.0; // Get from user input
    await _repositories.userRepository.updateUserBalance(uid, newBalance);
    setState(() {});
  }
}
```

---

## STEP 4: Add Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules

Replace with:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /expenses/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

This ensures users can only access their own data.

---

## STEP 5: Data Migration (If you have existing data)

If you have expenses stored locally, run this migration script:

```dart
// Run this ONCE in main.dart or a setup page
Future<void> migrateLocalDataToFirestore() async {
  final repositories = RepositoryProvider();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Example: migrate old RecordBookData
  // for (var category in RecordBookData.categories) {
  //   for (var item in category.items) {
  //     await repositories.expenseRepository.addExpense(
  //       Expense(
  //         id: '',
  //         userId: userId,
  //         category: category.name,
  //         amount: item.amount,
  //         description: item.name,
  //         date: item.date,
  //         createdAt: DateTime.now(),
  //       ),
  //     );
  //   }
  // }
}
```

---

## STEP 6: Testing Checklist

- [ ] User registration saves to Firestore
- [ ] User profile loads from Firestore
- [ ] Adding an expense saves to Firestore
- [ ] Expenses display in real-time when added
- [ ] Deleting an expense removes it from Firestore
- [ ] Balance updates persist
- [ ] Logout and login shows same data

---

## Quick Reference: What Each Class Does

| File | Purpose |
|------|---------|
| `Expense` (entity) | Business logic expense object |
| `ExpenseModel` | Converts Expense ↔ Firestore JSON |
| `ExpenseRepository` | Interface for expense operations |
| `ExpenseRepositoryImpl` | Implements expense operations |
| `FirestoreDatasource` | Direct Firestore calls |
| `RepositoryProvider` | Singleton to access repos easily |

---

## Common Operations Reference

```dart
final repos = RepositoryProvider();
final userId = FirebaseAuth.instance.currentUser!.uid;

// Add expense
await repos.expenseRepository.addExpense(expense);

// Get all expenses
final expenses = await repos.expenseRepository.getUserExpenses(userId);

// Listen to real-time updates
repos.expenseRepository.streamUserExpenses(userId).listen((expenses) {
  setState(() {}); // Update UI
});

// Update expense
await repos.expenseRepository.updateExpense(userId, expenseId, updatedExpense);

// Delete expense
await repos.expenseRepository.deleteExpense(userId, expenseId);

// Get by date range
final rangeExpenses = await repos.expenseRepository.getExpensesByDateRange(
  userId,
  startDate,
  endDate,
);

// Get by category
final categoryExpenses = await repos.expenseRepository.getExpensesByCategory(
  userId,
  'Food',
);

// Save user
await repos.userRepository.saveUserAccount(user);

// Get user
final user = await repos.userRepository.getUserAccount(userId);

// Update balance
await repos.userRepository.updateUserBalance(userId, newBalance);
```

---

## Troubleshooting

**Error: "FirebaseAuthException: [firebase_auth/user-not-found]"**
- User hasn't registered yet, make sure registration completes

**Error: "Permission denied" in Firestore**
- Check Firebase security rules (see Step 4)
- Make sure userId matches authenticated user

**Expenses not showing**
- Check user is logged in: `FirebaseAuth.instance.currentUser != null`
- Check Firestore has data: Go to Firebase Console
- Make sure using correct userId

**Data disappears after restart**
- Make sure using Firestore, not local state
- Check app is properly saving to Firestore

---

## Next Steps

1. Update RecordBookPage with Firestore integration
2. Update Registration page to save user data
3. Update Profile page to load from Firestore
4. Test all CRUD operations
5. Set Firestore security rules
6. Deploy and verify on device
