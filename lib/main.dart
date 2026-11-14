// FloraTwin AI — Phase 1 frontend (Flutter)
//
// pubspec.yaml dependencies:
//   google_fonts: ^6.2.1
//   camera: ^0.11.0
//   image: ^4.2.0
//
// Android: add <uses-permission android:name="android.permission.CAMERA"/> and set minSdkVersion 21+
// iOS: add NSCameraUsageDescription to Info.plist.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img_lib;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FloraTwinApp());
}

// ============================================================================
// DESIGN TOKENS
// ============================================================================
class C {
  static const fern = Color(0xFF1F4D3A); // primary
  static const moss = Color(0xFF4C8C5A); // healthy
  static const sprout = Color(0xFFA7D676); // accent
  static const mist = Color(0xFFF2F5EF); // background
  static const sage = Color(0xFFE3EBDD); // soft surface
  static const ink = Color(0xFF14221A);
  static const muted = Color(0xFF6B7A70);
  static const amber = Color(0xFFD9962B);
  static const clay = Color(0xFFC4553F);
}

class FloraTwinApp extends StatelessWidget {
  const FloraTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true).textTheme;
    TextStyle? sans(TextStyle? s) => s == null ? null : GoogleFonts.figtree(textStyle: s);
    TextStyle? serif(TextStyle? s) =>
        s == null ? null : GoogleFonts.fraunces(textStyle: s, fontWeight: FontWeight.w600);

    final text = TextTheme(
      displayLarge: sans(base.displayLarge),
      displayMedium: sans(base.displayMedium),
      displaySmall: sans(base.displaySmall),
      headlineLarge: serif(base.headlineLarge),
      headlineMedium: serif(base.headlineMedium),
      headlineSmall: serif(base.headlineSmall),
      titleLarge: serif(base.titleLarge),
      titleMedium: sans(base.titleMedium),
      titleSmall: sans(base.titleSmall),
      bodyLarge: sans(base.bodyLarge),
      bodyMedium: sans(base.bodyMedium),
      bodySmall: sans(base.bodySmall),
      labelLarge: sans(base.labelLarge),
      labelMedium: sans(base.labelMedium),
      labelSmall: sans(base.labelSmall),
    ).apply(bodyColor: C.ink, displayColor: C.ink);

    return MaterialApp(
      title: 'FloraTwin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.fern,
          primary: C.fern,
          secondary: C.moss,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: C.mist,
        textTheme: text,
        appBarTheme: const AppBarTheme(
          backgroundColor: C.mist,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: C.ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.sage),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.sage),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.fern, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: C.ink,
            side: const BorderSide(color: C.sage, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const Root(),
    );
  }
}

// ============================================================================
// DOMAIN MODELS
// ============================================================================
enum HealthState {
  thriving('Thriving', C.moss, Icons.eco_rounded),
  attention('Needs attention', C.amber, Icons.water_drop_rounded),
  recovering('Recovering', C.clay, Icons.healing_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const HealthState(this.label, this.color, this.icon);
}

enum Sensitivity { hardy, sensitive }

class Species {
  final String name, sci, light, water, humidity, toxicNote;
  final bool toxic;
  final Sensitivity sensitivity;
  const Species(this.name, this.sci, this.light, this.water, this.humidity, this.toxic,
      this.toxicNote, this.sensitivity);
}

const kSpecies = <Species>[
  Species('Monstera', 'Monstera deliciosa', 'Bright indirect, 2–3 h soft sun', 'When top 5 cm of soil is dry',
      '60–70%', true, 'Calcium oxalates irritate mouths of pets and toddlers.', Sensitivity.hardy),
  Species('Heartleaf Philodendron', 'Philodendron hederaceum', 'Medium to bright indirect', 'When top 3 cm is dry',
      '50–60%', true, 'Mildly toxic if chewed by pets or children.', Sensitivity.hardy),
  Species('Golden Pothos', 'Epipremnum aureum', 'Low to bright indirect', 'When soil is dry halfway down',
      '40–60%', true, 'Toxic to cats and dogs if eaten.', Sensitivity.hardy),
  Species('Calathea Orbifolia', 'Goeppertia orbifolia', 'Low to medium indirect, no direct sun',
      'Keep evenly moist, use distilled water', '70–80%', false, 'Non-toxic to pets and children.', Sensitivity.sensitive),
  Species('Fiddle Leaf Fig', 'Ficus lyrata', 'Bright indirect, 3–4 h soft sun', 'Deep drench every ~10 days',
      '50–60%', true, 'Sap irritates skin and the stomach of pets and children.', Sensitivity.sensitive),
  Species('Snake Plant', 'Dracaena trifasciata', 'Low to bright light', 'Every 2–3 weeks',
      '30–50%', true, 'Mildly toxic to pets if eaten.', Sensitivity.hardy),
];

class CheckupEntry {
  final String date;
  final double greenness;
  final String note;
  const CheckupEntry(this.date, this.greenness, this.note);
}

class Plant {
  final String id;
  final Species species;
  String nickname;
  HealthState health;
  double heightCm, potCm;
  String spot;
  int daysSinceCheckup;
  String? activeIssue;
  final List<CheckupEntry> checkups; // newest first
  final List<String> history; // newest first

  Plant({
    required this.id,
    required this.species,
    required this.nickname,
    required this.health,
    required this.heightCm,
    required this.potCm,
    required this.spot,
    required this.daysSinceCheckup,
    required this.checkups,
    required this.history,
    this.activeIssue,
  });

  int get checkupIntervalDays => health == HealthState.recovering
      ? 3
      : (species.sensitivity == Sensitivity.hardy ? 30 : 7);
  int get daysUntilCheckup => math.max(0, checkupIntervalDays - daysSinceCheckup);
  double get greenness => checkups.isEmpty ? 0.8 : checkups.first.greenness;
}

class CareTask {
  final String id, plantId, plantName, action, amount, why, nextAfter;
  final IconData icon;
  bool done;
  CareTask({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.action,
    required this.amount,
    required this.why,
    required this.nextAfter,
    required this.icon,
    this.done = false,
  });
}

class RelocationAlert {
  final String plantName, reason, action;
  final bool severe;
  const RelocationAlert(this.plantName, this.reason, this.action, this.severe);
}

class Candidate {
  final Species species;
  final double confidence;
  const Candidate(this.species, this.confidence);
}

class Diagnosis {
  final String condition, advice;
  final double confidence;
  final bool healthy;
  const Diagnosis(this.condition, this.confidence, this.advice, this.healthy);
}

// ============================================================================
// APP STATE
// ============================================================================
class AppState extends ChangeNotifier {
  bool signedIn = false, locationGranted = false, onboarded = false;
  String email = '';
  double lat = 33.6844, lon = 73.0479; // TODO: replace with real GPS
  bool hasPets = false, hasKids = false;
  bool remindWatering = true, remindSeasonal = true, remindRecovery = true;

  // TODO: replace with OpenWeatherMap response
  final weather = (temp: 14, humidity: 84, summary: 'Overcast, light rain later');

  bool get safetyOn => hasPets || hasKids;
  bool get northern => lat >= 0;

  late final List<Plant> plants = [
    Plant(
      id: 'p1', species: kSpecies[0], nickname: 'Monty', health: HealthState.thriving,
      heightCm: 85, potCm: 24, spot: 'South window', daysSinceCheckup: 13,
      checkups: const [
        CheckupEntry('1 Nov', 0.94, 'New split leaf unfurled.'),
        CheckupEntry('18 Oct', 0.91, 'Stable colour across the canopy.'),
      ],
      history: ['Aug 14: Thrips treated with spinosad, resolved'],
    ),
    Plant(
      id: 'p2', species: kSpecies[3], nickname: 'Orbi', health: HealthState.recovering,
      heightCm: 40, potCm: 18, spot: 'East window', daysSinceCheckup: 2,
      activeIssue: 'Tip burn from tap water and dry air',
      checkups: const [
        CheckupEntry('11 Nov', 0.68, 'Brown leaf edges spreading.'),
        CheckupEntry('5 Nov', 0.74, 'Crisp edges after humidity drop.'),
      ],
      history: ['Nov 9: Switched to distilled water, moved out of afternoon sun'],
    ),
    Plant(
      id: 'p3', species: kSpecies[4], nickname: 'Fig', health: HealthState.attention,
      heightCm: 130, potCm: 30, spot: 'Hallway shelf', daysSinceCheckup: 5,
      checkups: const [CheckupEntry('7 Nov', 0.84, 'Slowing down as days shorten.')],
      history: ['Jun 21: Botrytis leaf spot treated with copper fungicide, resolved'],
    ),
  ];

  late final List<CareTask> tasks = [
    CareTask(
      id: 't1', plantId: 'p1', plantName: 'Monty', action: 'Water', amount: '450 ml',
      icon: Icons.water_drop_rounded,
      why: 'Pushed back 2 days. Humidity is 84% and it is overcast, so soil is drying about 38% slower.',
      nextAfter: 'Next watering in about 9 days',
    ),
    CareTask(
      id: 't2', plantId: 'p2', plantName: 'Orbi', action: 'Neem oil wipe + refill humidifier',
      amount: 'Day 4 of 7', icon: Icons.healing_rounded,
      why: 'Indoor heating dropped room humidity by 14% overnight, which the plant is reacting to.',
      nextAfter: 'Next treatment tomorrow',
    ),
    CareTask(
      id: 't3', plantId: 'p3', plantName: 'Fig', action: 'Feed 3-1-2 liquid fertiliser',
      amount: 'Half strength', icon: Icons.spa_rounded,
      why: 'Dose halved because daylight is down to 10 h 14 m and growth is slowing.',
      nextAfter: 'Next feeding in about 5 weeks',
    ),
  ];

  final List<RelocationAlert> alerts = const [
    RelocationAlert('Fig', 'Winter sun sits lower, so the hallway shelf now gets under 2 hours of light.',
        'Move next to the south window.', false),
    RelocationAlert('Monty', 'Window glass may drop to 4°C tonight.', 'Pull it 30 cm back from the glass.', true),
  ];

  void signIn(String e) {
    signedIn = true;
    email = e;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    onboarded = false;
    notifyListeners();
  }

  void grantLocation() {
    locationGranted = true;
    notifyListeners();
  }

  void setSafety({bool? pets, bool? kids}) {
    hasPets = pets ?? hasPets;
    hasKids = kids ?? hasKids;
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    notifyListeners();
  }

  void toggleSetting(void Function() change) {
    change();
    notifyListeners();
  }

  /// Closed loop: log the task, then the engine reschedules from the forecast.
  String completeTask(CareTask t) {
    t.done = true;
    plants.firstWhere((p) => p.id == t.plantId).history.insert(0, 'Today: ${t.action} (${t.amount})');
    notifyListeners();
    return t.nextAfter;
  }

  void addPlant(Species s, String nick, double h, double pot, String spot) {
    plants.insert(
      0,
      Plant(
        id: 'p${DateTime.now().millisecondsSinceEpoch}', species: s, nickname: nick,
        health: HealthState.thriving, heightCm: h, potCm: pot, spot: spot,
        daysSinceCheckup: 0, checkups: [const CheckupEntry('Today', 0.9, 'First photo added.')],
        history: ['Today: Added to your garden'],
      ),
    );
    notifyListeners();
  }

  void logCheckup(Plant p, Diagnosis d) {
    p.checkups.insert(0, CheckupEntry('Today', d.healthy ? 0.92 : 0.7, d.healthy ? 'Looks healthy.' : d.condition));
    p.daysSinceCheckup = 0;
    p.activeIssue = d.healthy ? null : d.condition;
    p.health = d.healthy ? HealthState.thriving : HealthState.recovering;
    if (!d.healthy) p.history.insert(0, 'Today: ${d.condition} detected');
    notifyListeners();
  }
}

// ============================================================================
// AI SERVICE STUBS — swap with ONNX Runtime / FastAPI calls
// ============================================================================
class PlantAI {
  static Future<List<Candidate>> identify(File photo) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    // Mock: low top-1 confidence so the picker appears.
    return [Candidate(kSpecies[0], 0.52), Candidate(kSpecies[1], 0.31), Candidate(kSpecies[2], 0.11)];
  }

  static Future<Diagnosis> diagnose(File photo, Plant plant) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    return const Diagnosis(
      'Early tip burn', 0.88,
      'Switch to distilled or rain water, raise humidity above 65%, and trim only the fully brown tips. '
          'Your last two check-ins show the same pattern, so recheck in 3 days.',
      false,
    );
  }
}

// ============================================================================
// PHOTO QUALITY GATE (runs on-device before the photo reaches the model)
// ============================================================================
enum Level { pass, warn, fail }

class QualityCheck {
  final String title, message;
  final Level level;
  const QualityCheck(this.title, this.message, this.level);
}

class PhotoQuality {
  final List<QualityCheck> checks;
  const PhotoQuality(this.checks);
  bool get blocked => checks.any((c) => c.level == Level.fail);
  bool get hasWarnings => checks.any((c) => c.level == Level.warn);
}

/// Top-level so it can run in an isolate via compute().
/// Thresholds are starting points. Tune them on real photos from your target phones.
PhotoQuality analyzePhoto(String path) {
  var im = img_lib.decodeImage(File(path).readAsBytesSync());
  if (im == null) {
    return const PhotoQuality([QualityCheck('Photo', 'This image could not be read. Take a new photo.', Level.fail)]);
  }
  im = img_lib.bakeOrientation(im);
  im = img_lib.copyResize(im, width: 320);
  final w = im.width, h = im.height;
  final lum = List<double>.filled(w * h, 0);
  double sum = 0;
  int green = 0, bright = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = im.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final l = 0.299 * r + 0.587 * g + 0.114 * b;

      lum[y * w + x] = l;
      sum += l;
      if (l > 250) bright++;
      if (g > r * 1.08 && g > b * 1.08 && g > 45) green++;
    }
  }
  final n = w * h;
  final meanL = sum / n, greenRatio = green / n, glare = bright / n;

  // Variance of the Laplacian: low value means blur.
  double lapSum = 0, lapSq = 0;
  int cnt = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final v = 4 * lum[i] - lum[i - 1] - lum[i + 1] - lum[i - w] - lum[i + w];
      lapSum += v;
      lapSq += v * v;
      cnt++;
    }
  }
  final lapMean = lapSum / cnt;
  final sharp = lapSq / cnt - lapMean * lapMean;

  final checks = <QualityCheck>[
    if (sharp < 40)
      const QualityCheck('Focus', 'Photo is blurry. Hold steady, tap the leaf to focus, then retake.', Level.fail)
    else if (sharp < 90)
      const QualityCheck('Focus', 'Slightly soft. A steadier shot will give better results.', Level.warn)
    else
      const QualityCheck('Focus', 'Sharp and in focus.', Level.pass),
    if (meanL < 60)
      const QualityCheck('Light', 'Too dark. Move near a window or turn on the flash.', Level.fail)
    else if (meanL > 220 || glare > 0.15)
      const QualityCheck('Light', 'Too bright or glare on leaves. Step out of direct sun.', Level.warn)
    else
      const QualityCheck('Light', 'Good lighting.', Level.pass),
    if (greenRatio < 0.03)
      const QualityCheck('Plant', 'No plant found. Point the camera at the leaves.', Level.fail)
    else if (greenRatio < 0.18)
      const QualityCheck('Distance', 'Plant looks far away. Move closer so leaves fill the frame.', Level.warn)
    else
      const QualityCheck('Distance', 'Plant fills the frame well.', Level.pass),
  ];
  return PhotoQuality(checks);
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class HealthRing extends StatelessWidget {
  final double value, size;
  final Color color;
  final Widget? child;
  const HealthRing({super.key, required this.value, required this.color, this.size = 56, this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => CustomPaint(painter: _RingPainter(v, color), child: Center(child: child)),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  _RingPainter(this.v, this.color);

  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(4, 4, s.width - 8, s.height - 8);
    final track = Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = color.withValues(alpha: 0.15);
    final arc = Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..color = color;
    c.drawArc(r, 0, math.pi * 2, false, track);
    c.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color;
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(99)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
      Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );
}

class Title2 extends StatelessWidget {
  final String text;
  const Title2(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

void toast(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? C.clay : C.fern,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Text(msg),
    ));
}

// ============================================================================
// ROOT: AUTH -> ONBOARDING -> SHELL
// ============================================================================
class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  final app = AppState();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (_, __) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: !app.signedIn
          ? AuthScreen(key: const ValueKey('auth'), app: app)
          : !app.onboarded
          ? OnboardingScreen(key: const ValueKey('onb'), app: app)
          : Shell(key: const ValueKey('shell'), app: app),
    ),
  );
}

// ============================================================================
// LOGIN / REGISTER
// ============================================================================
class AuthScreen extends StatefulWidget {
  final AppState app;
  const AuthScreen({super.key, required this.app});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _register = false, _hide = true, _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700)); // TODO: call FastAPI auth
    if (mounted) widget.app.signIn(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: C.fern,
      body: Stack(children: [
        Positioned(top: -60, right: -50, child: _blob(220, C.moss.withValues(alpha: 0.35))),
        Positioned(top: 90, left: -80, child: _blob(180, C.sprout.withValues(alpha: 0.18))),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.spa_rounded, color: C.sprout),
                    const SizedBox(width: 8),
                    Text('FloraTwin', style: t.titleLarge?.copyWith(color: Colors.white, fontSize: 20)),
                  ]),
                  const SizedBox(height: 28),
                  Text('Care that follows\nyour weather and light.',
                      style: t.headlineMedium?.copyWith(color: Colors.white, height: 1.15)),
                ]),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                color: C.mist,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Sign in')),
                        ButtonSegment(value: true, label: Text('Create account')),
                      ],
                      selected: {_register},
                      onSelectionChanged: (s) => setState(() => _register = s.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Enter a valid email address' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: _hide,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(_register ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => widget.app.signIn('you@gmail.com'), // TODO: Google SSO
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Google'),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => widget.app.signIn('you@icloud.com'), // TODO: Apple SSO
                        icon: const Icon(Icons.apple, size: 22),
                        label: const Text('Apple'),
                      )),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _blob(double s, Color c) => Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ============================================================================
// ONBOARDING: LOCATION + HOUSEHOLD SAFETY
// ============================================================================
class OnboardingScreen extends StatefulWidget {
  final AppState app;
  const OnboardingScreen({super.key, required this.app});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final t = Theme.of(context).textTheme;
    final steps = [
      _Step(
        icon: Icons.wb_sunny_rounded,
        title: 'Share your location',
        body: 'We use it for local weather and the sun\'s seasonal path, so watering and placement advice matches your home.',
        child: FilledButton.icon(
          onPressed: () {
            app.grantLocation();
            setState(() => step = 1);
          },
          icon: const Icon(Icons.my_location),
          label: const Text('Allow location'),
        ),
      ),
      _Step(
        icon: Icons.pets_rounded,
        title: 'Who shares your space?',
        body: 'We will flag toxic plants and keep them off the floor if you have pets or small children.',
        child: ListenableBuilder(
          listenable: app,
          builder: (_, __) => Column(children: [
            SoftCard(
              child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cats or dogs'),
                  value: app.hasPets,
                  onChanged: (v) => app.setSafety(pets: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Young children'),
                  value: app.hasKids,
                  onChanged: (v) => app.setSafety(kids: v),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: app.finishOnboarding, child: const Text('Start growing')),
          ]),
        ),
      ),
    ];
    final s = steps[step];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: List.generate(2, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                decoration: BoxDecoration(color: i <= step ? C.fern : C.sage, borderRadius: BorderRadius.circular(9)),
              ),
            ))),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: C.sage, borderRadius: BorderRadius.circular(20)),
                    child: Icon(s.icon, size: 32, color: C.fern),
                  ),
                  const SizedBox(height: 20),
                  Text(s.title, style: t.headlineMedium),
                  const SizedBox(height: 10),
                  Text(s.body, style: t.bodyLarge?.copyWith(color: C.muted, height: 1.4)),
                  const SizedBox(height: 28),
                  s.child,
                ],
              ),
            ),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title, body;
  final Widget child;
  _Step({required this.icon, required this.title, required this.body, required this.child});
}

// ============================================================================
// SHELL WITH CENTRE SCAN BUTTON
// ============================================================================
class Shell extends StatefulWidget {
  final AppState app;
  const Shell({super.key, required this.app});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  void _scan() => Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ScanFlow(app: widget.app),
  ));

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final pages = [TodayTab(app: app), PlantsTab(app: app), PlacementTab(app: app), SettingsTab(app: app)];
    Widget item(int i, IconData icon, IconData sel, String label) {
      final on = tab == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => tab = i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(on ? sel : icon, color: on ? C.fern : C.muted),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w800 : FontWeight.w500, color: on ? C.fern : C.muted)),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(tab), child: pages[tab])),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: C.sage))),
        child: SafeArea(
          child: Row(children: [
            item(0, Icons.today_outlined, Icons.today_rounded, 'Today'),
            item(1, Icons.eco_outlined, Icons.eco_rounded, 'Plants'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: _scan,
                child: Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: C.sprout, shape: BoxShape.circle),
                  child: const Icon(Icons.photo_camera_rounded, color: C.fern, size: 26),
                ),
              ),
            ),
            item(2, Icons.light_mode_outlined, Icons.light_mode_rounded, 'Light'),
            item(3, Icons.person_outline, Icons.person_rounded, 'You'),
          ]),
        ),
      ),
    );
  }
}

// ============================================================================
// TODAY TAB
// ============================================================================
class TodayTab extends StatelessWidget {
  final AppState app;
  const TodayTab({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final open = app.tasks.where((x) => !x.done).length;
        final due = app.plants.where((p) => p.daysUntilCheckup == 0).toList();
        return SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            Text('Good morning', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(open == 0 ? 'Everything is cared for today.' : '$open ${open == 1 ? 'task' : 'tasks'} for your plants today.',
                style: t.bodyLarge?.copyWith(color: C.muted)),
            const SizedBox(height: 16),
            SoftCard(
              color: C.fern,
              child: Row(children: [
                const Icon(Icons.cloud_rounded, color: C.sprout, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${app.weather.temp}°C · ${app.weather.humidity}% humidity',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('${app.weather.summary}. Watering times are adjusted for this.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                  ]),
                ),
              ]),
            ),
            if (due.isNotEmpty) ...[
              const Title2('Photo check-ins due'),
              ...due.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      fullscreenDialog: true, builder: (_) => ScanFlow(app: app, checkupFor: p))),
                  child: Row(children: [
                    const Icon(Icons.photo_camera_outlined, color: C.fern),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${p.nickname} is due for a check-in', style: const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.chevron_right, color: C.muted),
                  ]),
                ),
              )),
            ],
            const Title2('Care tasks'),
            ...app.tasks.map((task) => _TaskCard(app: app, task: task)),
          ]),
        );
      },
    );
  }
}

class _TaskCard extends StatefulWidget {
  final AppState app;
  final CareTask task;
  const _TaskCard({required this.app, required this.task});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: task.done ? 0.55 : 1,
        child: SoftCard(
          onTap: () => setState(() => open = !open),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: C.sage, borderRadius: BorderRadius.circular(14)),
                child: Icon(task.icon, color: C.fern, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(task.action, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.done ? TextDecoration.lineThrough : null)),
                  Text('${task.plantName} · ${task.amount}', style: const TextStyle(color: C.muted, fontSize: 13)),
                ]),
              ),
              IconButton.filledTonal(
                onPressed: task.done ? null : () => toast(context, widget.app.completeTask(task)),
                icon: Icon(task.done ? Icons.check_rounded : Icons.check),
                style: IconButton.styleFrom(backgroundColor: task.done ? C.moss : C.sage, foregroundColor: task.done ? Colors.white : C.fern),
              ),
            ]),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.mist, borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.lightbulb_outline, size: 18, color: C.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(task.why, style: const TextStyle(fontSize: 13, height: 1.35))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ============================================================================
// PLANTS TAB + DETAIL
// ============================================================================
class PlantsTab extends StatelessWidget {
  final AppState app;
  const PlantsTab({super.key, required this.app});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (_, __) => SafeArea(
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(child: Text('Your plants', style: Theme.of(context).textTheme.headlineMedium)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.88),
            itemCount: app.plants.length,
            itemBuilder: (_, i) {
              final p = app.plants[i];
              return SoftCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantDetail(app: app, plant: p))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HealthRing(value: p.greenness, color: p.health.color, size: 58, child: Icon(p.health.icon, color: p.health.color, size: 22)),
                  const Spacer(),
                  Text(p.nickname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  Text(p.species.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Pill(p.health.label, p.health.color),
                ]),
              );
            },
          ),
        ),
      ]),
    ),
  );
}

class PlantDetail extends StatelessWidget {
  final AppState app;
  final Plant plant;
  const PlantDetail({super.key, required this.app, required this.plant});

  Widget _row(IconData i, String label, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, size: 20, color: C.moss),
      const SizedBox(width: 12),
      Expanded(child: Text.rich(TextSpan(children: [
        TextSpan(text: '$label  ', style: const TextStyle(color: C.muted)),
        TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final p = plant;
        return Scaffold(
          appBar: AppBar(),
          body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
            Row(children: [
              HealthRing(value: p.greenness, color: p.health.color, size: 84,
                  child: Text('${(p.greenness * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: p.health.color))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nickname, style: t.headlineMedium),
                Text(p.species.sci, style: const TextStyle(fontStyle: FontStyle.italic, color: C.muted)),
                const SizedBox(height: 8),
                Pill(p.health.label, p.health.color, icon: p.health.icon),
              ])),
            ]),
            if (p.activeIssue != null) ...[
              const SizedBox(height: 16),
              SoftCard(
                color: C.clay.withValues(alpha: 0.1),
                child: Row(children: [
                  const Icon(Icons.healing_rounded, color: C.clay),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Active issue: ${p.activeIssue}', style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
            const Title2('What it needs'),
            SoftCard(child: Column(children: [
              _row(Icons.light_mode_outlined, 'Light', p.species.light),
              _row(Icons.water_drop_outlined, 'Water', p.species.water),
              _row(Icons.air_rounded, 'Humidity', p.species.humidity),
              _row(Icons.straighten_rounded, 'Size', '${p.heightCm.round()} cm tall · ${p.potCm.round()} cm pot'),
              _row(Icons.place_outlined, 'Spot', p.spot),
            ])),
            const SizedBox(height: 12),
            SoftCard(
              color: p.species.toxic ? C.amber.withValues(alpha: 0.12) : C.sage,
              child: Row(children: [
                Icon(p.species.toxic ? Icons.warning_amber_rounded : Icons.verified_rounded, color: p.species.toxic ? C.amber : C.moss),
                const SizedBox(width: 10),
                Expanded(child: Text(p.species.toxicNote, style: const TextStyle(fontSize: 13.5))),
              ]),
            ),
            const Title2('Check-ins'),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => ScanFlow(app: app, checkupFor: p))),
              icon: const Icon(Icons.photo_camera_rounded),
              label: Text(p.daysUntilCheckup == 0 ? 'Take check-in photo (due now)' : 'Take check-in photo'),
            ),
            const SizedBox(height: 6),
            Text('Next check-in ${p.daysUntilCheckup == 0 ? 'is due' : 'in ${p.daysUntilCheckup} days'} · every ${p.checkupIntervalDays} days'
                '${p.health == HealthState.recovering ? ' while recovering' : ''}',
                style: const TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 12),
            ...p.checkups.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  SizedBox(width: 58, child: Text(c.date, style: const TextStyle(color: C.muted, fontSize: 13))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(value: c.greenness, minHeight: 7, backgroundColor: C.sage, color: C.moss),
                    ),
                    const SizedBox(height: 6),
                    Text(c.note, style: const TextStyle(fontSize: 13)),
                  ])),
                ]),
              ),
            )),
            const Title2('History'),
            ...p.history.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: C.moss)),
                const SizedBox(width: 10),
                Expanded(child: Text(h)),
              ]),
            )),
          ]),
        );
      },
    );
  }
}

// ============================================================================
// LIGHT & PLACEMENT TAB (Phase 1: seasonal guidance, no floor grid)
// ============================================================================
class PlacementTab extends StatelessWidget {
  final AppState app;
  const PlacementTab({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = DateTime.now().month;
    final winter = app.northern ? (m == 11 || m == 12 || m == 1 || m == 2) : (m >= 5 && m <= 8);
    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        Text('Light & placement', style: t.headlineMedium),
        const SizedBox(height: 14),
        SoftCard(
          color: C.sage,
          child: Row(children: [
            Icon(winter ? Icons.wb_twilight_rounded : Icons.wb_sunny_rounded, color: C.fern, size: 32),
            const SizedBox(width: 14),
            Expanded(child: Text(
              winter
                  ? 'The sun is low and days are short. Move light-hungry plants closer to windows and pull sensitive ones back from cold glass.'
                  : 'The sun is high. Keep plants a little back from south and west windows to avoid leaf scorch.',
              style: const TextStyle(height: 1.35),
            )),
          ]),
        ),
        if (app.remindSeasonal) ...[
          const Title2('Suggested moves'),
          ...app.alerts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  backgroundColor: (a.severe ? C.clay : C.amber).withValues(alpha: 0.14),
                  child: Icon(a.severe ? Icons.ac_unit_rounded : Icons.wb_twilight_rounded, color: a.severe ? C.clay : C.amber),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.plantName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(a.reason, style: const TextStyle(color: C.muted, fontSize: 13.5)),
                  const SizedBox(height: 6),
                  Text(a.action, style: const TextStyle(fontWeight: FontWeight.w700, color: C.fern)),
                ])),
              ]),
            ),
          )),
        ],
        const Title2('Where each plant is happiest'),
        ...app.plants.map((p) {
          final blocked = app.safetyOn && p.species.toxic;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(p.nickname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Text('Now: ${p.spot}', style: const TextStyle(color: C.muted, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Text(p.species.light),
                if (blocked) ...[
                  const SizedBox(height: 8),
                  const Pill('Keep off the floor', C.amber, icon: Icons.shield_outlined),
                ],
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ============================================================================
// SETTINGS TAB
// ============================================================================
class SettingsTab extends StatelessWidget {
  final AppState app;
  const SettingsTab({super.key, required this.app});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (_, __) => SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
        Text('You', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 14),
        SoftCard(child: Row(children: [
          const CircleAvatar(backgroundColor: C.sage, child: Icon(Icons.person, color: C.fern)),
          const SizedBox(width: 12),
          Expanded(child: Text(app.email, style: const TextStyle(fontWeight: FontWeight.w700))),
        ])),
        const Title2('Household safety'),
        SoftCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Cats or dogs'), value: app.hasPets, onChanged: (v) => app.setSafety(pets: v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Young children'), value: app.hasKids, onChanged: (v) => app.setSafety(kids: v)),
        ])),
        const Title2('Notifications'),
        SoftCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: [
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Watering reminders'), value: app.remindWatering,
              onChanged: (v) => app.toggleSetting(() => app.remindWatering = v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Seasonal and weather move alerts'), value: app.remindSeasonal,
              onChanged: (v) => app.toggleSetting(() => app.remindSeasonal = v)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Recovery mode alerts'), value: app.remindRecovery,
              onChanged: (v) => app.toggleSetting(() => app.remindRecovery = v)),
        ])),
        const Title2('Location'),
        SoftCard(child: Row(children: [
          Icon(app.locationGranted ? Icons.location_on : Icons.location_off, color: C.fern),
          const SizedBox(width: 12),
          Expanded(child: Text(app.locationGranted ? 'Using your location for weather and sun path' : 'Location is off')),
        ])),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: app.signOut, child: const Text('Sign out')),
      ]),
    ),
  );
}

// ============================================================================
// SCAN FLOW: still capture -> quality gate -> AI -> pick/details or diagnosis
// ============================================================================
enum Phase { capture, checking, review, thinking, pick, details, diagnosis }

class ScanFlow extends StatefulWidget {
  final AppState app;
  final Plant? checkupFor;
  const ScanFlow({super.key, required this.app, this.checkupFor});
  @override
  State<ScanFlow> createState() => _ScanFlowState();
}

class _ScanFlowState extends State<ScanFlow> {
  CameraController? _cam;
  String? _camError;
  FlashMode _flash = FlashMode.off;
  Phase phase = Phase.capture;
  File? photo;
  PhotoQuality? quality;
  List<Candidate> candidates = [];
  Species? chosen;
  Diagnosis? diagnosis;
  Timer? _tipTimer;
  int _tip = 0;

  final _nick = TextEditingController();
  final _height = TextEditingController();
  final _pot = TextEditingController();
  String _spot = 'South window';
  static const spots = ['South window', 'East window', 'West window', 'North window', 'Bright room, no window', 'Hallway'];
  static const tips = [
    'Fill about half the frame with leaves.',
    'Use daylight and avoid strong backlight.',
    'Tap a leaf to focus, then hold steady.',
  ];

  bool get isCheckup => widget.checkupFor != null;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && phase == Phase.capture) setState(() => _tip = (_tip + 1) % tips.length);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _cam?.dispose();
    _nick.dispose();
    _height.dispose();
    _pot.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) setState(() => _camError = 'No camera found on this device.');
        return;
      }
      final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first);
      final c = CameraController(back, ResolutionPreset.veryHigh, enableAudio: false);
      await c.initialize();
      await c.setFlashMode(_flash);
      if (!mounted) return c.dispose();
      setState(() => _cam = c);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _camError = e.code.contains('Denied')
            ? 'Camera access is off. Turn it on in your phone settings to scan plants.'
            : 'The camera could not start. Close other camera apps and try again.');
      }
    } catch (_) {
      if (mounted) setState(() => _camError = 'No camera found on this device.');
    }
  }

  Future<void> _shoot() async {
    final c = _cam;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      final f = await c.takePicture();
      photo = File(f.path);
      setState(() => phase = Phase.checking);
      final q = await compute(analyzePhoto, f.path);
      if (!mounted) return;
      setState(() {
        quality = q;
        phase = Phase.review;
      });
    } catch (_) {
      if (mounted) toast(context, 'Could not take the photo. Try again.', error: true);
    }
  }

  Future<void> _toggleFlash() async {
    _flash = _flash == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await _cam?.setFlashMode(_flash);
    setState(() {});
  }

  Future<void> _submitPhoto() async {
    setState(() => phase = Phase.thinking);
    if (isCheckup) {
      final d = await PlantAI.diagnose(photo!, widget.checkupFor!);
      if (mounted) setState(() { diagnosis = d; phase = Phase.diagnosis; });
    } else {
      final list = await PlantAI.identify(photo!);
      if (!mounted) return;
      setState(() {
        candidates = list;
        if (list.first.confidence >= 0.75) {
          chosen = list.first.species;
          _nick.text = chosen!.name.split(' ').first;
          phase = Phase.details;
        } else {
          phase = Phase.pick; // top-3 picker when unsure
        }
      });
    }
  }

  void _retake() => setState(() {
    photo = null;
    quality = null;
    phase = Phase.capture;
  });

  void _savePlant() {
    final h = double.tryParse(_height.text) ?? 30;
    final p = double.tryParse(_pot.text) ?? 15;
    final name = _nick.text.trim().isEmpty ? chosen!.name : _nick.text.trim();
    widget.app.addPlant(chosen!, name, h, p, _spot);
    final m = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    m.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: C.fern, content: Text('$name added to your garden')));
  }

  @override
  Widget build(BuildContext context) {
    final dark = phase == Phase.capture;
    return Scaffold(
      backgroundColor: dark ? Colors.black : C.mist,
      appBar: AppBar(
        backgroundColor: dark ? Colors.black : C.mist,
        foregroundColor: dark ? Colors.white : C.ink,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text(isCheckup ? 'Check-in: ${widget.checkupFor!.nickname}' : 'Add a plant',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: dark ? Colors.white : C.ink)),
        actions: [
          if (dark && _cam != null)
            IconButton(icon: Icon(_flash == FlashMode.off ? Icons.flash_off : Icons.flash_auto), onPressed: _toggleFlash),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(phase), child: switch (phase) {
          Phase.capture => _capture(),
          Phase.checking => _busy('Checking photo quality'),
          Phase.review => _review(),
          Phase.thinking => _busy(isCheckup ? 'Looking at the leaves' : 'Identifying your plant'),
          Phase.pick => _pick(),
          Phase.details => _details(),
          Phase.diagnosis => _diagnosis(),
        }),
      ),
    );
  }

  // ---------- capture ----------
  Widget _capture() {
    if (_camError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
          const SizedBox(height: 14),
          Text(_camError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 18),
          FilledButton(onPressed: () { setState(() => _camError = null); _initCamera(); }, child: const Text('Try again')),
        ]),
      ));
    }
    final c = _cam;
    if (c == null) return const Center(child: CircularProgressIndicator(color: C.sprout));
    return Column(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(builder: (ctx, box) => GestureDetector(
            onTapUp: (d) {
              final o = Offset(d.localPosition.dx / box.maxWidth, d.localPosition.dy / box.maxHeight);
              c.setFocusPoint(o);
              c.setExposurePoint(o);
            },
            child: Stack(fit: StackFit.expand, children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(width: c.value.previewSize!.height, height: c.value.previewSize!.width, child: CameraPreview(c)),
              ),
              CustomPaint(painter: _FramePainter()),
              Positioned(
                left: 16, right: 16, top: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(_tip),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.tips_and_updates_outlined, color: C.sprout, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tips[_tip], style: const TextStyle(color: Colors.white, fontSize: 13.5))),
                    ]),
                  ),
                ),
              ),
            ]),
          )),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: GestureDetector(
            onTap: _shoot,
            child: Container(
              width: 76, height: 76,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: Container(decoration: const BoxDecoration(color: C.sprout, shape: BoxShape.circle)),
            ),
          ),
        ),
      ),
    ]);
  }

  // ---------- busy ----------
  Widget _busy(String label) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3.5, color: C.fern)),
      const SizedBox(height: 18),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    ]),
  );

  // ---------- review (quality gate) ----------
  Widget _review() {
    final q = quality!;
    final headline = q.blocked
        ? 'Let\'s retake this one'
        : q.hasWarnings ? 'Usable, but could be better' : 'Great photo';
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
      ClipRRect(borderRadius: BorderRadius.circular(22), child: AspectRatio(aspectRatio: 4 / 3, child: Image.file(photo!, fit: BoxFit.cover))),
      const SizedBox(height: 16),
      Text(headline, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      ...q.checks.map((c) {
        final col = switch (c.level) { Level.pass => C.moss, Level.warn => C.amber, Level.fail => C.clay };
        final ic = switch (c.level) { Level.pass => Icons.check_circle_rounded, Level.warn => Icons.error_rounded, Level.fail => Icons.cancel_rounded };
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SoftCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(ic, color: col),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(c.message, style: const TextStyle(color: C.muted, fontSize: 13.5)),
              ])),
            ]),
          ),
        );
      }),
      const SizedBox(height: 12),
      if (q.blocked)
        FilledButton.icon(onPressed: _retake, icon: const Icon(Icons.replay), label: const Text('Retake photo'))
      else ...[
        FilledButton(onPressed: _submitPhoto, child: Text(q.hasWarnings ? 'Use anyway' : 'Use this photo')),
        if (q.hasWarnings) ...[const SizedBox(height: 10), OutlinedButton(onPressed: _retake, child: const Text('Retake photo'))],
      ],
    ]);
  }

  // ---------- pick top-3 ----------
  Widget _pick() => ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
    Text('Which one is it?', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 6),
    const Text('These plants look alike. Pick the closest match.', style: TextStyle(color: C.muted)),
    const SizedBox(height: 16),
    ...candidates.map((c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: () => setState(() {
          chosen = c.species;
          _nick.text = c.species.name.split(' ').first;
          phase = Phase.details;
        }),
        child: Row(children: [
          HealthRing(value: c.confidence, color: C.moss, size: 52, child: Text('${(c.confidence * 100).round()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.species.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(c.species.sci, style: const TextStyle(fontStyle: FontStyle.italic, color: C.muted, fontSize: 13)),
          ])),
          const Icon(Icons.chevron_right, color: C.muted),
        ]),
      ),
    )),
    const SizedBox(height: 6),
    OutlinedButton(onPressed: _retake, child: const Text('None of these, retake photo')),
  ]);

  // ---------- details ----------
  Widget _details() {
    final s = chosen!;
    final blocked = widget.app.safetyOn && s.toxic;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
      Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
      Text(s.sci, style: const TextStyle(fontStyle: FontStyle.italic, color: C.muted)),
      const SizedBox(height: 14),
      SoftCard(color: C.sage, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Light: ${s.light}'),
        const SizedBox(height: 4),
        Text('Water: ${s.water}'),
        const SizedBox(height: 4),
        Text('Humidity: ${s.humidity}'),
      ])),
      if (blocked) ...[
        const SizedBox(height: 10),
        SoftCard(
          color: C.amber.withValues(alpha: 0.13),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: C.amber),
            const SizedBox(width: 10),
            Expanded(child: Text('${s.toxicNote} Keep it on a shelf or table, away from the floor.')),
          ]),
        ),
      ],
      const Title2('A few details we cannot see'),
      TextField(controller: _nick, decoration: const InputDecoration(labelText: 'Nickname')),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)'))),
        const SizedBox(width: 12),
        Expanded(child: TextField(controller: _pot, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pot width (cm)'))),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _spot,
        decoration: const InputDecoration(labelText: 'Where will it live?'),
        items: spots.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _spot = v ?? _spot),
      ),
      const SizedBox(height: 22),
      FilledButton(onPressed: _savePlant, child: const Text('Add to my garden')),
    ]);
  }

  // ---------- diagnosis ----------
  Widget _diagnosis() {
    final d = diagnosis!;
    final col = d.healthy ? C.moss : C.clay;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
      ClipRRect(borderRadius: BorderRadius.circular(22), child: AspectRatio(aspectRatio: 16 / 9, child: Image.file(photo!, fit: BoxFit.cover))),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Text(d.healthy ? 'Looking healthy' : d.condition, style: Theme.of(context).textTheme.headlineSmall)),
        Pill('${(d.confidence * 100).round()}% sure', col),
      ]),
      const SizedBox(height: 12),
      SoftCard(child: Text(d.advice, style: const TextStyle(height: 1.45))),
      const SizedBox(height: 22),
      FilledButton(
        onPressed: () {
          widget.app.logCheckup(widget.checkupFor!, d);
          Navigator.of(context).pop();
        },
        child: Text(d.healthy ? 'Save check-in' : 'Save and start recovery plan'),
      ),
    ]);
  }
}

/// Corner brackets that show where to place the plant.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.8, height: s.height * 0.6),
      const Radius.circular(26),
    );
    final dim = Path()..addRect(Offset.zero & s)..addRRect(r)..fillType = PathFillType.evenOdd;
    c.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.28));
    c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = C.sprout.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}