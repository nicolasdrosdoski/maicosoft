import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final GoRouterState routerState = GoRouter.of(context).state;
    final String location = routerState.uri.toString();
    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                SizedBox(height: 30),
                Row(
                  children: [
                    Text(
                      ' MaicoSoft',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Image.asset('assets/icons/logo.png', width: 30, height: 30),
                  ],
                ),
                SizedBox(height: 60),
                _NavItem(
                  title: 'Oportunidades',
                  icon: FaIcon(
                    FontAwesomeIcons.handshakeSimple,
                    color: Colors.white,
                  ),
                  isSelected: location == '/oportunidades',
                  onTap:
                      () => setState(() {
                        context.go('/oportunidades');
                      }),
                ),

                _NavItem(
                  title: 'Clientes',
                  icon: FaIcon(FontAwesomeIcons.users, color: Colors.white),
                  isSelected: location == '/clientes',
                  onTap:
                      () => setState(() {
                        context.go('/clientes');
                      }),
                ),

                _NavItem(
                  title: 'Produtos',
                  icon: FaIcon(FontAwesomeIcons.boxOpen, color: Colors.white),
                  isSelected: location == '/produtos',
                  onTap:
                      () => setState(() {
                        context.go('/produtos');
                      }),
                ),

                _NavItem(
                  title: 'Pedidos',
                  icon: FaIcon(FontAwesomeIcons.truckFast, color: Colors.white),
                  isSelected: location == '/pedidos',
                  onTap:
                      () => setState(() {
                        context.go('/pedidos');
                      }),
                ),

                _NavItem(
                  title: 'Assistente',
                  icon: FaIcon(FontAwesomeIcons.brain, color: Colors.white),
                  isSelected: location == '/assistente',
                  onTap:
                      () => setState(() {
                        context.go('/assistente');
                      }),
                ),
              ],
            ),
            _NavItem(
              title: 'Sair',
              icon: FaIcon(
                FontAwesomeIcons.arrowRightFromBracket,
                color: Colors.white,
              ),
              isSelected: false,
              onTap: () {
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// class _SectionTitle extends StatelessWidget {
//   final String title;
//   const _SectionTitle({required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: Colors.grey[400],
//           fontSize: 14,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

class _NavItem extends StatefulWidget {
  final String title;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color contentColor;

    if (widget.isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      contentColor = Colors.white;
    } else if (_isHovering) {
      backgroundColor = Colors.white.withAlpha(25);
      contentColor = Colors.white;
    } else {
      backgroundColor = Colors.transparent;
      contentColor = Colors.grey[400]!;
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      onHover: (hovering) {
        setState(() {
          _isHovering = hovering;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                widget.icon,
                const SizedBox(width: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 15),
          ],
        ),
      ),
    );
  }
}
