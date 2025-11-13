import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maicosoft/pages/assistente_page.dart';
import 'package:maicosoft/pages/clientes_page.dart';
import 'package:maicosoft/pages/dashboard_shell.dart';
import 'package:maicosoft/pages/login_page.dart';
import 'package:maicosoft/pages/oportunidades_page.dart';
import 'package:maicosoft/pages/pedidos_page.dart';
import 'package:maicosoft/pages/produto_page.dart';
import 'package:maicosoft/services/auth_service.dart';

final AuthService _authService = AuthService();

final GoRouter router = GoRouter(
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(_authService.authStateChanges),

  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return DashboardShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/oportunidades',
          name: 'oportunidades',
          builder: (context, state) => const OportunidadesPage(),
        ),
        GoRoute(
          path: '/clientes',
          name: 'clientes',
          builder: (context, state) => const ClientesPage(),
        ),
        GoRoute(
          path: '/produtos',
          name: 'produtos',
          builder: (context, state) => const ProdutosPage(),
        ),
        GoRoute(
          path: '/pedidos',
          name: 'pedidos',
          builder: (context, state) => const PedidosPage(),
        ),
        GoRoute(
          path: '/assistente',
          name: 'assistente',
          builder: (context, state) => const AssistentePage(),
        ),
      ],
    ),
  ],

  redirect: (context, state) {
    final bool isLoggedIn = _authService.currentUser != null;
    final bool isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    if (isLoggedIn && isLoggingIn) {
      return '/oportunidades';
    }

    return null;
  },
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
