import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'shared/widgets/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BootApp()));
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});
  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  bool _ready = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    di
        .initDependencies()
        .then((_) {
          if (mounted) setState(() => _ready = true);
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _ready = true;
              _initError = e;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return ClassCanApp(initError: _initError);
  }
}

class ClassCanApp extends ConsumerWidget {
  final Object? initError;
  const ClassCanApp({super.key, this.initError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;
    return MaterialApp(
      title: 'Classcan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authState.isAuthenticated && userId != null
          ? HomeShell(userId: userId)
          : LoginPage(initError: initError),
    );
  }
}
