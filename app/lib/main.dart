import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/storage.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Light-only by design. Committing to one theme means every surface gets the
  // full attention rather than two getting half each.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Both are resolved before the first frame, so no screen in the app ever has
  // to render a loading state for its own data.
  final storage = await Storage.open();
  final repo = await ExerciseRepository.load();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        exerciseRepoProvider.overrideWithValue(repo),
      ],
      child: const ForgeApp(),
    ),
  );
}
