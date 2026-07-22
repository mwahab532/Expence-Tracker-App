import 'package:flutter/material.dart';
import 'package:flutter_expence_tracker/data/repositories/Buget_Repository_Imp.dart';
import 'package:flutter_expence_tracker/data/services/contectivity_servics.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';
import 'package:flutter_expence_tracker/providers/Network_conectivity_provider.dart';
import 'package:flutter_expence_tracker/screens/offline_Banner.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/auth_gate.dart';
import '../data/repositories/auth_repository_Imp.dart';
import '../data/repositories/category_repository_imp.dart';
import '../data/repositories/expense_repository_imp.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/route_generator.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ---- Services (thin Firebase wrappers) ----
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()..enableOfflinePersistence()),
        Provider(create: (_) => StorageService()),

        // ---- Repositories (business logic, depend only on services) ----
        ProxyProvider<FirestoreService, CategoryRepository>(
          update: (_, firestoreService, _) =>
              CategoryRepositoryImpl(firestoreService: firestoreService),
        ),
        ProxyProvider3<AuthService, FirestoreService, CategoryRepository, AuthRepository>(
          update: (_, authService, firestoreService, categoryRepository, _) => AuthRepositoryImpl(
            authService: authService,
            firestoreService: firestoreService,
            categoryRepository: categoryRepository,
          ),
        ),
        ProxyProvider2<FirestoreService, StorageService, ExpenseRepository>(
          update: (_, firestoreService, storageService, _) => ExpenseRepositoryImpl(
            firestoreService: firestoreService,
            storageService: storageService,
          ),
        ),

         ProxyProvider<FirestoreService, BudgetRepository>(
          update: (_, firestoreService, _) =>
              BudgetRepositoryImpl(firestoreService: firestoreService),
        ),

        // ---- App-wide providers (state that outlives individual screens) ----
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (ctx) => AuthProvider(authRepository: ctx.read<AuthRepository>()),
          update: (_, _, previous) => previous!,
        ),
          Provider(create: (_) => ConnectivityService()),
        ChangeNotifierProxyProvider<ConnectivityService, ConnectivityProvider>(
          create: (ctx) => ConnectivityProvider(connectivityService: ctx.read<ConnectivityService>()),
          update: (_, __, previous) => previous!,
        ),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            onGenerateRoute: RouteGenerator.generateRoute,
            home: OfflineBanner(child: const AuthGate()),
          );
        },
      ),
    );
  }
}
