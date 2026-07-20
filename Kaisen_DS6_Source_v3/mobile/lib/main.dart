import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/venta_provider.dart';
import 'repositories/product_repository.dart';
import 'repositories/sale_repository.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_repository.dart';
import 'theme/kaisen_theme.dart';

const supabaseUrl =
    String.fromEnvironment('SUPABASE_URL');

const supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.trim().isEmpty || supabasePublishableKey.trim().isEmpty) {
    throw StateError(
      'Falta la configuración de Supabase. Define SUPABASE_URL y '
      'SUPABASE_PUBLISHABLE_KEY mediante --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const KaisenApp());
}

class KaisenApp extends StatelessWidget {
  const KaisenApp({
    super.key,
    this.authRepository,
    this.productRepository,
    this.saleRepository,
  });

  final AuthRepository? authRepository;
  final ProductRepository? productRepository;
  final SaleRepository? saleRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>(
          create: (_) => productRepository ?? SupabaseProductRepository(),
        ),
        Provider<SaleRepository>(
          create: (_) => saleRepository ?? SupabaseSaleRepository(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => InventarioProvider(
            repository: context.read<ProductRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => VentaProvider(
            saleRepository: context.read<SaleRepository>(),
            productRepository: context.read<ProductRepository>(),
            refreshInventory:
                context.read<InventarioProvider>().cargarProductos,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SyncProvider(
            inventarioProvider: context.read<InventarioProvider>(),
            ventaProvider: context.read<VentaProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Kaisen',
        debugShowCheckedModeBanner: false,
        theme: KaisenTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.authenticatedBuilder,
    this.unauthenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;
  final WidgetBuilder? unauthenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.estaAutenticado) {
      return unauthenticatedBuilder?.call(context) ?? const LoginScreen();
    }
    return authenticatedBuilder?.call(context) ?? const DashboardScreen();
  }
}
