import 'package:flutter/material.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _direction = i > _index ? 1 : -1;
          _index = i;
        }),
        backgroundColor: theme.colorScheme.surfaceContainer,
        height: 78,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorShape: const CircleBorder(),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Evaluaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Cursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: 'Notas',
          ),
        ],
      ),
    );
  }
}
