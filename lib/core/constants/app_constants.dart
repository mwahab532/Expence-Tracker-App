class FirestoreCollections {
  // Top-level users collection; everything else is a per-user subcollection
  // so each user's data is naturally isolated and queries stay small.
  // /users/{uid}
  // /users/{uid}/expenses/{expenseId}
  // /users/{uid}/categories/{categoryId}
  static const String users = 'users';
  static const String expenses = 'expenses';
  static const String categories = 'categories';
}

class DefaultCategories {
  static const List<String> names = [
    'Food',
    'Bills',
    'Shopping',
    'Entertainment',
    'Transport',
  ];
}

class StorageFolders {
  static const String receipts = 'receipts';
  static const String profilePictures = 'profile_pictures';
}

class PrefsKeys {
  static const String themeMode = 'theme_mode';
}
