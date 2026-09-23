import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/assessments/presentation/pages/evaluations_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  final int userId;
  const HomeShell({super.key, required this.userId});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 1;
  int _direction = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = ref.watch(
      authProvider.select((auth) => auth.user?.username ?? ''),
    );
    const titles = ['Evaluaciones', 'Cursos', 'Notas'];
    final pages = [
      EvaluationsPage(userId: widget.userId),
      CoursesPage(userId: widget.userId),
      GradesPage(userId: widget.userId),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            onSelected: (_) => ref.read(authProvider.notifier).logout(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    const Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_outlined),
                  const SizedBox(width: 6),
                  Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => SlideTransition(
          position:
              Tween<Offset>(
                begin: Offset(_direction.toDouble(), 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: _ModernBottomBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() {
          _direction = i > _index ? 1 : -1;
          _index = i;
        }),
      ),
    );
  }
}

class _ModernBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ModernBottomBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = const [
      _NavItemData(
        label: 'Evaluaciones',
        unselectedIcon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
      ),
      _NavItemData(
        label: 'Cursos',
        unselectedIcon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
      ),
      _NavItemData(
        label: 'Notas',
        unselectedIcon: Icons.grade_outlined,
        selectedIcon: Icons.grade_rounded,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < items.length; i++)
                _NavItemPill(
                  item: items[i],
                  isSelected: selectedIndex == i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelected(i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;

  const _NavItemData({
    required this.label,
    required this.unselectedIcon,
    required this.selectedIcon,
  });
}

class _NavItemPill extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemPill({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBg = theme.colorScheme.primaryContainer;
    final activeFg = theme.colorScheme.onPrimaryContainer;
    final inactiveFg = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.unselectedIcon,
                color: isSelected ? activeFg : inactiveFg,
                size: 22,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    color: activeFg,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
