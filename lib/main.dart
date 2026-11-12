import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const BotanicalDigitalTwinApp());
}

// ============================================================================
// CORE THEME & DESIGN SYSTEM
// ============================================================================
class BotanicalDigitalTwinApp extends StatelessWidget {
  const BotanicalDigitalTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeliosTwin Botanical OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          primary: const Color(0xFF1B4332),
          secondary: const Color(0xFF40916C),
          tertiary: const Color(0xFFD8F3DC),
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
      ),
      home: const RootOrchestrator(),
    );
  }
}

// ============================================================================
// DOMAIN MODELS & FINITE STATE MACHINE (FSM)
// ============================================================================

enum PlantHealthFSM {
  thriving('Thriving', Color(0xFF2D6A4F), Icons.check_circle_outline, 14),
  acclimating('Acclimating', Color(0xFFD97706), Icons.sync, 7),
  stressed('Light/Water Stress', Color(0xFFE07A5F), Icons.warning_amber_rounded, 3),
  recoveryMode('Recovery Mode (Critical)', Color(0xFFBC4749), Icons.medical_services_outlined, 1);

  final String label;
  final Color color;
  final IconData icon;
  final int photoCheckupIntervalDays;
  const PlantHealthFSM(this.label, this.color, this.icon, this.photoCheckupIntervalDays);
}

enum PlacementElevation {
  floor('Floor Level (0.0m)'),
  table('Tabletop (0.8m)'),
  highShelf('High Shelf / Hanging (1.8m)');

  final String label;
  const PlacementElevation(this.label);
}

class DiagnosticRecord {
  final String date;
  final String condition;
  final double cnnConfidence;
  final String treatmentProtocol;
  final bool resolved;

  const DiagnosticRecord({
    required this.date,
    required this.condition,
    required this.cnnConfidence,
    required this.treatmentProtocol,
    required this.resolved,
  });
}

class HealthCheckupLog {
  final String date;
  final double canopyGreennessIndex; // 0.0 to 1.0
  final PlantHealthFSM stateAtLog;
  final String note;

  const HealthCheckupLog({
    required this.date,
    required this.canopyGreennessIndex,
    required this.stateAtLog,
    required this.note,
  });
}

class PlantSpecimen {
  final String id;
  final String commonName;
  final String scientificName;
  final bool isToxicToPetsOrKids;
  final String toxicityWarning;
  final double minDLI; // mol/m²/d
  final double maxDLI;
  final int idealHumidityPercent;
  final String wateringRule;
  final PlantHealthFSM currentFSMState;
  final int hoursUntilNextPhotoCheckup;

  // Spatial Digital Twin Coordinates (0..7 Grid)
  int gridX;
  int gridY;
  PlacementElevation elevation;

  final List<HealthCheckupLog> checkupTimeline;
  final List<DiagnosticRecord> diagnosticHistory;

  PlantSpecimen({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.isToxicToPetsOrKids,
    required this.toxicityWarning,
    required this.minDLI,
    required this.maxDLI,
    required this.idealHumidityPercent,
    required this.wateringRule,
    required this.currentFSMState,
    required this.hoursUntilNextPhotoCheckup,
    required this.gridX,
    required this.gridY,
    required this.elevation,
    required this.checkupTimeline,
    required this.diagnosticHistory,
  });
}

class CareTask {
  final String id;
  final String plantId;
  final String plantName;
  final String actionType; // 'Watering', 'Nutrition', 'Medicine (Neem Oil)'
  final String standardSchedule;
  final String weatherAdjustedRationale;
  bool isCompleted;

  CareTask({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.actionType,
    required this.standardSchedule,
    required this.weatherAdjustedRationale,
    this.isCompleted = false,
  });
}

class RelocationAlert {
  final String id;
  final String plantName;
  final String reason;
  final String targetCoordinates;
  final String severity; // 'Seasonal Shift' | 'Severe Weather Alert'

  const RelocationAlert({
    required this.id,
    required this.plantName,
    required this.reason,
    required this.targetCoordinates,
    required this.severity,
  });
}

// ============================================================================
// APPLICATION STATE CONTROLLER (DIGITAL TWIN ENGINE)
// ============================================================================
class AppStateController extends ChangeNotifier {
  // 1. Auth & Onboarding State
  bool isAuthenticated = false;
  String userEmail = '';
  String authProvider = '';
  bool isLocationGranted = false;
  double latitude = 37.7749;
  double longitude = -122.4194;
  bool hasPets = true;
  bool hasYoungChildren = false;
  bool onboardingComplete = false;

  // 2. Digital Twin Spatial Engine State
  bool is3DView = false;
  bool showSolarHeatmap = true;
  double timeOfDayHour = 13.5; // 1:30 PM default
  double externalObstructionFactor = 0.20; // 20% skyline blocked by neighbor building
  double sensorCalibrationMultiplier = 1.0; // Adjusted via physical Lux calibration

  // 5. Settings & Notification Toggles
  bool muteRoutineWatering = false;
  bool enableSeasonalRelocationAlerts = true;
  bool enableRecoveryModeTriggers = true;

  bool get safetyFilterActive => hasPets || hasYoungChildren;

  late List<PlantSpecimen> plants;
  late List<CareTask> tasks;
  late List<RelocationAlert> relocationQueue;

  AppStateController() {
    _seedInitialBotanicalData();
  }

  void _seedInitialBotanicalData() {
    plants = [
      PlantSpecimen(
        id: 'p1',
        commonName: 'Monstera Deliciosa',
        scientificName: 'Monstera deliciosa',
        isToxicToPetsOrKids: true,
        toxicityWarning: 'Contains insoluble calcium oxalates. Causes intense oral irritation and swelling in cats, dogs, and toddlers.',
        minDLI: 6.0,
        maxDLI: 16.0,
        idealHumidityPercent: 65,
        wateringRule: 'Every 7–9 days (Wait for top 5cm soil dry)',
        currentFSMState: PlantHealthFSM.thriving,
        hoursUntilNextPhotoCheckup: 118,
        gridX: 1,
        gridY: 2,
        elevation: PlacementElevation.table,
        checkupTimeline: const [
          HealthCheckupLog(date: '2026-11-01', canopyGreennessIndex: 0.94, stateAtLog: PlantHealthFSM.thriving, note: 'New fenestrated leaf unfurled (+12% surface area).'),
          HealthCheckupLog(date: '2026-10-18', canopyGreennessIndex: 0.91, stateAtLog: PlantHealthFSM.thriving, note: 'Stable chlorophyll density across upper canopy.'),
          HealthCheckupLog(date: '2026-10-04', canopyGreennessIndex: 0.85, stateAtLog: PlantHealthFSM.acclimating, note: 'Moved 1m closer to South window.'),
        ],
        diagnosticHistory: const [
          DiagnosticRecord(
            date: '2026-08-14',
            condition: 'Thrips (Early Instar Larvae)',
            cnnConfidence: 0.96,
            treatmentProtocol: '3-week Spinosad foliar spray + systemic granules applied.',
            resolved: true,
          ),
        ],
      ),
      PlantSpecimen(
        id: 'p2',
        commonName: 'Calathea Orbifolia',
        scientificName: 'Goeppertia orbifolia',
        isToxicToPetsOrKids: false,
        toxicityWarning: '100% Pet & Child Safe (ASPCA Verified Non-Toxic). Floor placement permitted.',
        minDLI: 3.0,
        maxDLI: 8.5,
        idealHumidityPercent: 75,
        wateringRule: 'Keep evenly moist with distilled/rain water',
        currentFSMState: PlantHealthFSM.recoveryMode,
        hoursUntilNextPhotoCheckup: 9,
        gridX: 4,
        gridY: 4,
        elevation: PlacementElevation.floor,
        checkupTimeline: const [
          HealthCheckupLog(date: '2026-11-11', canopyGreennessIndex: 0.68, stateAtLog: PlantHealthFSM.recoveryMode, note: 'Marginal leaf necrosis detected; FSM locked in 24h photo checkup cadence.'),
          HealthCheckupLog(date: '2026-11-05', canopyGreennessIndex: 0.74, stateAtLog: PlantHealthFSM.stressed, note: 'Drop in ambient humidity triggered crisp edges.'),
        ],
        diagnosticHistory: const [
          DiagnosticRecord(
            date: '2026-11-09',
            condition: 'Photo-oxidative Sunburn + Fluoride Tip Burn',
            cnnConfidence: 0.92,
            treatmentProtocol: 'Relocated away from direct afternoon beam; switched to distilled water + Neem oil wipe.',
            resolved: false,
          ),
        ],
      ),
      PlantSpecimen(
        id: 'p3',
        commonName: 'Fiddle Leaf Fig',
        scientificName: 'Ficus lyrata',
        isToxicToPetsOrKids: true,
        toxicityWarning: 'Toxic ficin & psoralen sap. Irritating to GI tract and skin for pets and children.',
        minDLI: 10.0,
        maxDLI: 22.0,
        idealHumidityPercent: 55,
        wateringRule: 'Deep drench every 10 days',
        currentFSMState: PlantHealthFSM.acclimating,
        hoursUntilNextPhotoCheckup: 42,
        gridX: 0,
        gridY: 5,
        elevation: PlacementElevation.highShelf,
        checkupTimeline: const [
          HealthCheckupLog(date: '2026-11-07', canopyGreennessIndex: 0.84, stateAtLog: PlantHealthFSM.acclimating, note: 'Adapting to winter solar azimuth shift.'),
        ],
        diagnosticHistory: const [
          DiagnosticRecord(
            date: '2026-06-21',
            condition: 'Botrytis Fungal Leaf Spot',
            cnnConfidence: 0.89,
            treatmentProtocol: 'Copper fungicide application (7-day cycle) + pruned lower affected leaves.',
            resolved: true,
          ),
        ],
      ),
    ];

    tasks = [
      CareTask(
        id: 't1',
        plantId: 'p1',
        plantName: 'Monstera Deliciosa',
        actionType: 'Watering (450ml)',
        standardSchedule: 'Originally due 2 days ago',
        weatherAdjustedRationale: 'Watering delayed by 2 days due to 84% local humidity and overcast forecast (OpenWeatherMap evapotranspiration drop of 38%).',
      ),
      CareTask(
        id: 't2',
        plantId: 'p2',
        plantName: 'Calathea Orbifolia',
        actionType: 'Medicine: Cold-Pressed Neem Oil + Humidifier Refill',
        standardSchedule: 'FSM Recovery Mode Protocol (Day 4 of 7)',
        weatherAdjustedRationale: 'Mandatory treatment step active. Indoor heating dropped ambient RH by 14% overnight.',
      ),
      CareTask(
        id: 't3',
        plantId: 'p3',
        plantName: 'Fiddle Leaf Fig',
        actionType: 'Nutrition: 3-1-2 Liquid NPK Fertilizer (Half-Strength)',
        standardSchedule: 'Monthly metabolic cycle',
        weatherAdjustedRationale: 'Dose reduced by 50% by SunCalc Engine: Solar photoperiod shortened to 10h 14m this week.',
      ),
    ];

    relocationQueue = const [
      RelocationAlert(
        id: 'r1',
        plantName: 'Fiddle Leaf Fig',
        reason: 'Seasonal solar declination dropped 4.2°. Current coordinate (0, 5) now receives 8.1 DLI (below 10.0 DLI threshold).',
        targetCoordinates: 'Move to Grid (0, 2) near South Window',
        severity: 'Seasonal Shift',
      ),
      RelocationAlert(
        id: 'r2',
        plantName: 'Monstera Deliciosa',
        reason: 'Cold draft warning: Nocturnal window glass temperature projected at 4°C tonight.',
        targetCoordinates: 'Shift 1 cell inland to Grid (2, 2)',
        severity: 'Severe Weather Alert',
      ),
    ];
  }

  /// Astronomical SunCalc + Skyline Obstruction + Sensor Calibration DLI simulator
  /// South Window is along X = 0 (Left edge), West Window is along Y = 0 (Top edge).
  double calculateSimulatedDLI(int x, int y) {
    // Distance attenuation from South (x=0) and West (y=0) windows
    final double southWindowContribution = 18.0 * math.exp(-0.38 * x);
    final double westWindowContribution = 12.0 * math.exp(-0.45 * y);

    // Time of day solar angle factor (peaks around 13:30)
    final double solarElevationFactor =
    math.max(0.15, math.sin(((timeOfDayHour - 6.0) / 12.0) * math.pi));

    // Apply external skyline obstruction & physical Lux sensor calibration
    final double rawDLI = (southWindowContribution + westWindowContribution) *
        solarElevationFactor *
        (1.0 - (externalObstructionFactor * 0.6)) *
        sensorCalibrationMultiplier;

    return double.parse(rawDLI.clamp(0.8, 28.0).toStringAsFixed(1));
  }

  void completeAuth(String provider, String email) {
    isAuthenticated = true;
    authProvider = provider;
    userEmail = email;
    notifyListeners();
  }

  void grantLocationPermission() {
    isLocationGranted = true;
    notifyListeners();
  }

  void updateHouseholdSafety({required bool pets, required bool children}) {
    hasPets = pets;
    hasYoungChildren = children;
    // Enforce floor block immediately if enabled
    if (safetyFilterActive) {
      for (final plant in plants) {
        if (plant.isToxicToPetsOrKids &&
            plant.elevation == PlacementElevation.floor) {
          plant.elevation = PlacementElevation.table;
        }
      }
    }
    notifyListeners();
  }

  void finishOnboarding() {
    onboardingComplete = true;
    notifyListeners();
  }

  /// Validates and relocates a plant on the Digital Twin Grid
  String? relocatePlant(
      PlantSpecimen plant,
      int newX,
      int newY,
      PlacementElevation newElevation,
      ) {
    if (safetyFilterActive &&
        plant.isToxicToPetsOrKids &&
        newElevation == PlacementElevation.floor) {
      return 'BLOCKED BY HOUSEHOLD SAFETY FILTER: ${plant.commonName} is toxic to ${hasPets ? "pets" : ""}${hasPets && hasYoungChildren ? " & " : ""}${hasYoungChildren ? "young children" : ""}. Floor-level placement is prohibited.';
    }
    plant.gridX = newX;
    plant.gridY = newY;
    plant.elevation = newElevation;
    notifyListeners();
    return null;
  }

  void toggleTask(String taskId) {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      tasks[idx].isCompleted = !tasks[idx].isCompleted;
      notifyListeners();
    }
  }

  void calibrateLuxSensor(double physicalLuxReading) {
    // Baseline expected noon indoor bright reading ~ 12,000 Lux
    sensorCalibrationMultiplier = (physicalLuxReading / 12000.0).clamp(0.4, 2.2);
    notifyListeners();
  }

  void triggerChange() => notifyListeners();
}

// ============================================================================
// ROOT ORCHESTRATOR (ONBOARDING VS MAIN SHELL)
// ============================================================================
class RootOrchestrator extends StatefulWidget {
  const RootOrchestrator({super.key});

  @override
  State<RootOrchestrator> createState() => _RootOrchestratorState();
}

class _RootOrchestratorState extends State<RootOrchestrator> {
  final AppStateController appState = AppStateController();
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.onboardingComplete) {
          return OnboardingFlowScreen(appState: appState);
        }

        final pages = [
          DigitalTwinMapScreen(appState: appState),
          TaskManagerCalendarScreen(appState: appState),
          PlantInventoryListScreen(appState: appState),
          SettingsPrivacyScreen(appState: appState),
        ];

        return Scaffold(
          body: pages[_currentTab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (idx) => setState(() => _currentTab = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.view_in_ar),
                label: 'Digital Twin',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.event_available),
                label: 'Care & Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco),
                label: 'Plant Profiles',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Settings & Sensors',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// FEATURE 1: AUTHENTICATION, GPS GATEWAY & HOUSEHOLD CONTEXT ONBOARDING
// ============================================================================
class OnboardingFlowScreen extends StatefulWidget {
  final AppStateController appState;
  const OnboardingFlowScreen({super.key, required this.appState});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final TextEditingController _emailController =
  TextEditingController(text: 'botanist@heliostwin.io');
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HeliosTwin Setup'),
        actions: [
          TextButton(
            onPressed: () {
              widget.appState.completeAuth('Quick Demo', 'demo@heliostwin.io');
              widget.appState.grantLocationPermission();
              widget.appState.finishOnboarding();
            },
            child: const Text('Skip to App Demo'),
          ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0 && !widget.appState.isAuthenticated) {
            widget.appState.completeAuth('Email', _emailController.text);
          }
          if (_step == 1 && !widget.appState.isLocationGranted) {
            widget.appState.grantLocationPermission();
          }
          if (_step < 2) {
            setState(() => _step++);
          } else {
            widget.appState.finishOnboarding();
          }
        },
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        steps: [
          // STEP 1: SSO & EMAIL AUTH
          Step(
            isActive: _step >= 0,
            state: widget.appState.isAuthenticated ? StepState.complete : StepState.indexed,
            title: const Text('1. Account & Cloud Twin Sync'),
            subtitle: const Text('Sync your 3D room meshes & plant FSM timelines'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                      onPressed: () {
                        widget.appState.completeAuth('Google SSO', 'alex.g@gmail.com');
                        setState(() => _step = 1);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.apple, size: 20),
                      label: const Text('Continue with Apple ID'),
                      onPressed: () {
                        widget.appState.completeAuth('Apple ID', 'alex@icloud.com');
                        setState(() => _step = 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // STEP 2: MANDATORY LOCATION PERMISSIONS GATEWAY
          Step(
            isActive: _step >= 1,
            state: widget.appState.isLocationGranted ? StepState.complete : StepState.indexed,
            title: const Text('2. Astronomical & Weather Gateway'),
            subtitle: const Text('Mandatory GPS opt-in for SunCalc & OpenWeatherMap'),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD8F3DC).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF40916C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: Color(0xFF1B4332)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Why Precise GPS is Required:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• SunCalc Astronomical Engine: Calculates exact solar azimuth, zenith, and seasonal window beam angles for your latitude/longitude.\n'
                        '• OpenWeatherMap API: Adjusts watering intervals dynamically using local cloud cover, humidity, and vapor pressure deficit (VPD).',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      widget.appState.grantLocationPermission();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GPS Locked: 37.7749° N, 122.4194° W (SunCalc Initialized)'),
                        ),
                      );
                    },
                    icon: Icon(widget.appState.isLocationGranted
                        ? Icons.check_circle
                        : Icons.my_location),
                    label: Text(widget.appState.isLocationGranted
                        ? 'GPS Telemetry Active (37.77° N, -122.41° W)'
                        : 'Authorize Precise Location Access'),
                  ),
                ],
              ),
            ),
          ),

          // STEP 3: HOUSEHOLD CONTEXT & TOXICITY FILTER
          Step(
            isActive: _step >= 2,
            title: const Text('3. Household Safety Context'),
            subtitle: const Text('Auto-configures floor-level toxicity blockers'),
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text('Curious Pets in Household (Cats / Dogs)'),
                  subtitle: const Text('Blocks floor placement of Calcium Oxalate / Saponin species'),
                  secondary: const Icon(Icons.pets),
                  value: widget.appState.hasPets,
                  onChanged: (val) => widget.appState.updateHouseholdSafety(
                    pets: val,
                    children: widget.appState.hasYoungChildren,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Young Children / Toddlers'),
                  subtitle: const Text('Enforces elevated placement (>= 0.8m) for toxic sap/foliage'),
                  secondary: const Icon(Icons.child_care),
                  value: widget.appState.hasYoungChildren,
                  onChanged: (val) => widget.appState.updateHouseholdSafety(
                    pets: widget.appState.hasPets,
                    children: val,
                  ),
                ),
                if (widget.appState.safetyFilterActive)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.amber),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Household Safety Shield Active: Floor-level (0.0m) drop targets are locked for toxic plant species.',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURE 2: THE DIGITAL TWIN MAP (2D/3D + DLI HEATMAP + DRAG & DROP)
// ============================================================================
class DigitalTwinMapScreen extends StatefulWidget {
  final AppStateController appState;
  const DigitalTwinMapScreen({super.key, required this.appState});

  @override
  State<DigitalTwinMapScreen> createState() => _DigitalTwinMapScreenState();
}

class _DigitalTwinMapScreenState extends State<DigitalTwinMapScreen> {
  PlantSpecimen? _selectedPlant;
  int? _previewX;
  int? _previewY;

  @override
  void initState() {
    super.initState();
    _selectedPlant = widget.appState.plants.first;
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room Digital Twin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('SunCalc Solar Raytracer • 8x8 Meter Grid', style: TextStyle(fontSize: 11.5)),
          ],
        ),
        actions: [
          // DLI Heatmap Toggle
          FilterChip(
            label: const Text('DLI Heatmap'),
            selected: app.showSolarHeatmap,
            avatar: const Icon(Icons.wb_iridescent_outlined, size: 16),
            onSelected: (v) {
              app.showSolarHeatmap = v;
              app.triggerChange();
            },
          ),
          const SizedBox(width: 8),
          // 2D / 3D Perspective Toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('2D'), icon: Icon(Icons.grid_on, size: 16)),
              ButtonSegment(value: true, label: Text('3D'), icon: Icon(Icons.view_in_ar, size: 16)),
            ],
            selected: {app.is3DView},
            onSelectionChanged: (set) {
              app.is3DView = set.first;
              app.triggerChange();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Top Solar Time & Safety Banner
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Simulated Solar Time: ${app.timeOfDayHour.toInt()}:${((app.timeOfDayHour % 1) * 60).toInt().toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Expanded(
                      child: Slider(
                        value: app.timeOfDayHour,
                        min: 6.0,
                        max: 19.5,
                        divisions: 27,
                        onChanged: (v) {
                          app.timeOfDayHour = v;
                          app.triggerChange();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'South Window: Left Edge (X=0)  |  West Window: Top Edge (Y=0)',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                    if (app.safetyFilterActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pet/Child Floor Lock: ON',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Interactive 2D Konva-Style Grid / 3D Perspective Space
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  transformAlignment: Alignment.center,
                  transform: app.is3DView
                      ? (Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(-0.62)
                    ..rotateZ(0.28)
                    ..scaleByDouble(0.88, 0.88, 0.88, 1.0))
                      : Matrix4.identity(),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF262A2C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: app.is3DView ? 0.35 : 0.12),
                            blurRadius: app.is3DView ? 28 : 12,
                            offset: Offset(0, app.is3DView ? 22 : 6),
                          ),
                        ],
                        border: Border.all(color: Colors.amber.shade400, width: 3),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(6),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: 36,
                        itemBuilder: (context, index) {
                          final int x = index % 6;
                          final int y = index ~/ 6;
                          final double cellDLI = app.calculateSimulatedDLI(x, y);
                          final PlantSpecimen? occupant = app.plants
                              .cast<PlantSpecimen?>()
                              .firstWhere(
                                (p) => p!.gridX == x && p.gridY == y,
                            orElse: () => null,
                          );

                          return DragTarget<PlantSpecimen>(
                            onWillAcceptWithDetails: (details) {
                              setState(() {
                                _previewX = x;
                                _previewY = y;
                              });
                              return true;
                            },
                            onLeave: (_) {
                              setState(() {
                                _previewX = null;
                                _previewY = null;
                              });
                            },
                            onAcceptWithDetails: (details) {
                              setState(() {
                                _previewX = null;
                                _previewY = null;
                              });
                              _handleDropRelocation(context, details.data, x, y);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final bool isHovered = _previewX == x && _previewY == y;
                              return GestureDetector(
                                onTap: () {
                                  if (occupant != null) {
                                    setState(() => _selectedPlant = occupant);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: app.showSolarHeatmap
                                        ? _dliToHeatmapColor(cellDLI)
                                        : const Color(0xFF343A40),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isHovered
                                          ? Colors.white
                                          : (occupant != null && occupant == _selectedPlant
                                          ? Colors.greenAccent
                                          : Colors.white24),
                                      width: isHovered || (occupant == _selectedPlant && occupant != null)
                                          ? 2.5
                                          : 0.8,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Coordinate & DLI readout
                                      Positioned(
                                        top: 3,
                                        left: 4,
                                        child: Text(
                                          '($x,$y)\n${cellDLI}dli',
                                          style: const TextStyle(
                                            fontSize: 8.5,
                                            height: 1.1,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      // Draggable Plant Token
                                      if (occupant != null)
                                        Center(
                                          child: Draggable<PlantSpecimen>(
                                            data: occupant,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: _buildPlantToken(occupant, isDragging: true),
                                            ),
                                            childWhenDragging: const Opacity(
                                              opacity: 0.3,
                                              child: Icon(Icons.yard, color: Colors.white),
                                            ),
                                            child: _buildPlantToken(occupant),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Inspector Panel: Thriving Compatibility & Elevation Controls
          if (_selectedPlant != null) _buildSelectedPlantCompatibilityBar(_selectedPlant!, app),
        ],
      ),
    );
  }

  Widget _buildPlantToken(PlantSpecimen plant, {bool isDragging = false}) {
    return Container(
      padding: EdgeInsets.all(isDragging ? 10 : 5),
      decoration: BoxDecoration(
        color: plant.currentFSMState.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            plant.isToxicToPetsOrKids ? Icons.warning_amber_rounded : Icons.local_florist,
            color: Colors.white,
            size: isDragging ? 24 : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlantCompatibilityBar(PlantSpecimen plant, AppStateController app) {
    final double currentDLI = app.calculateSimulatedDLI(plant.gridX, plant.gridY);
    final bool willThrive = currentDLI >= plant.minDLI && currentDLI <= plant.maxDLI;
    final String statusText = willThrive
        ? 'THRIVING ZONE: $currentDLI DLI is within ideal [${plant.minDLI}–${plant.maxDLI} mol/m²/d]'
        : (currentDLI < plant.minDLI
        ? 'LIGHT DEFICIT: $currentDLI DLI is below minimum ${plant.minDLI} DLI'
        : 'SUNBURN RISK: $currentDLI DLI exceeds maximum ${plant.maxDLI} DLI');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: plant.currentFSMState.color,
                radius: 16,
                child: const Icon(Icons.eco, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plant.commonName} @ Grid (${plant.gridX}, ${plant.gridY})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: willThrive ? Colors.green.shade800 : Colors.deepOrange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<PlacementElevation>(
                value: plant.elevation,
                underline: const SizedBox(),
                items: PlacementElevation.values
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.label, style: const TextStyle(fontSize: 12)),
                ))
                    .toList(),
                onChanged: (newElev) {
                  if (newElev != null) {
                    final err = app.relocatePlant(plant, plant.gridX, plant.gridY, newElev);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red.shade800, content: Text(err)),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tip: Drag and drop any plant icon across the grid to test solar compatibility before moving it physically.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _handleDropRelocation(BuildContext context, PlantSpecimen plant, int x, int y) {
    final String? error = widget.appState.relocatePlant(plant, x, y, plant.elevation);
    setState(() => _selectedPlant = plant);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade800, content: Text(error)),
      );
    } else {
      final dli = widget.appState.calculateSimulatedDLI(x, y);
      final ok = dli >= plant.minDLI && dli <= plant.maxDLI;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? const Color(0xFF1B4332) : Colors.orange.shade900,
          content: Text(
            ok
                ? 'Moved ${plant.commonName} to ($x, $y) — Optimal $dli DLI!'
                : 'Warning: ($x, $y) provides $dli DLI (Target: ${plant.minDLI}–${plant.maxDLI} DLI).',
          ),
        ),
      );
    }
  }

  Color _dliToHeatmapColor(double dli) {
    if (dli >= 16.0) return const Color(0xFFE63946).withValues(alpha: 0.85); // High sun
    if (dli >= 10.0) return const Color(0xFFF4A261).withValues(alpha: 0.85); // Bright indirect
    if (dli >= 5.5) return const Color(0xFFE9C46A).withValues(alpha: 0.80); // Medium
    return const Color(0xFF264653).withValues(alpha: 0.85); // Low shade
  }
}

// ============================================================================
// FEATURE 3: TASK MANAGER & CARE CALENDAR (WEATHER-ADJUSTED + RELOCATION QUEUE)
// ============================================================================
class TaskManagerCalendarScreen extends StatelessWidget {
  final AppStateController appState;
  const TaskManagerCalendarScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Operations & Relocation Queue'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // OpenWeatherMap Live Telemetry Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_sync, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Factor Rule Engine Active',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'OpenWeatherMap: 84% Humidity • Overcast • Solar Photoperiod: 10h 14m. Schedules auto-adjusted.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Actionable To-Do List
          const Text(
            'Daily Actionable Checklist (Watering, Nutrition, Medicine)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...appState.tasks.map((task) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: task.isCompleted,
                    onChanged: (_) => appState.toggleTask(task.id),
                    title: Text(
                      '${task.plantName} — ${task.actionType}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(task.standardSchedule),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 18, color: Color(0xFF1B4332)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Weather-Adjusted Rationale: ${task.weatherAdjustedRationale}',
                            style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),

          const SizedBox(height: 16),
          // Prioritized Relocation Queue
          const Text(
            'Spatial Relocation Queue (Sun Shifts & Weather Alerts)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...appState.relocationQueue.map((alert) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: alert.severity.contains('Severe')
                    ? Colors.red.shade100
                    : Colors.amber.shade100,
                child: Icon(
                  alert.severity.contains('Severe') ? Icons.storm : Icons.wb_twilight,
                  color: alert.severity.contains('Severe')
                      ? Colors.red.shade800
                      : Colors.amber.shade900,
                ),
              ),
              title: Text(
                '${alert.plantName} (${alert.severity})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${alert.reason}\nAction: ${alert.targetCoordinates}'),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURE 4: INDIVIDUAL PLANT DETAIL PROFILE (FSM + CNN DIAGNOSTICS + TOXICITY)
// ============================================================================
class PlantInventoryListScreen extends StatelessWidget {
  final AppStateController appState;
  const PlantInventoryListScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centralized Botanical Inventory')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.plants.length,
        itemBuilder: (context, index) {
          final plant = appState.plants[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: plant.currentFSMState.color,
                child: Icon(plant.currentFSMState.icon, color: Colors.white),
              ),
              title: Text(
                plant.commonName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.scientificName, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          'FSM: ${plant.currentFSMState.label}',
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                        backgroundColor: plant.currentFSMState.color,
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          plant.isToxicToPetsOrKids ? 'Toxic (Pets/Kids)' : 'Non-Toxic Safe',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: plant.isToxicToPetsOrKids
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlantDetailProfileScreen(plant: plant),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PlantDetailProfileScreen extends StatelessWidget {
  final PlantSpecimen plant;
  const PlantDetailProfileScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.commonName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Biological Needs & Pet/Child Toxicity Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.commonName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              plant.scientificName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: plant.isToxicToPetsOrKids
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: plant.isToxicToPetsOrKids ? Colors.red : Colors.green,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              plant.isToxicToPetsOrKids ? Icons.pets : Icons.verified_user,
                              size: 16,
                              color: plant.isToxicToPetsOrKids
                                  ? Colors.red.shade800
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              plant.isToxicToPetsOrKids ? 'TOXIC SPECIES' : 'PET/CHILD SAFE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: plant.isToxicToPetsOrKids
                                    ? Colors.red.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Auto-Populated Biological Requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• Ideal Solar DLI: ${plant.minDLI} – ${plant.maxDLI} mol/m²/day'),
                  Text('• Target Relative Humidity: ${plant.idealHumidityPercent}%'),
                  Text('• Hydration Rule: ${plant.wateringRule}'),
                  Text('• Current Twin Position: Grid (${plant.gridX}, ${plant.gridY}) • ${plant.elevation.label}'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: plant.isToxicToPetsOrKids
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plant.toxicityWarning,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: plant.isToxicToPetsOrKids
                            ? Colors.red.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Finite State Machine (FSM) Status & Photo Checkup Countdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Finite State Machine (FSM) & Checkup Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: plant.currentFSMState.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: plant.currentFSMState.color),
                    ),
                    child: Row(
                      children: [
                        Icon(plant.currentFSMState.icon, color: plant.currentFSMState.color, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current State: ${plant.currentFSMState.label}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: plant.currentFSMState.color,
                                ),
                              ),
                              Text(
                                'Next Required CNN Photo Checkup in: ${plant.hoursUntilNextPhotoCheckup} hours '
                                    '(Fragility Cadence: Every ${plant.currentFSMState.photoCheckupIntervalDays}d)',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Canopy Greenness & Visual Log:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  ...plant.checkupTimeline.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(
                            log.date,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: log.canopyGreennessIndex,
                                      minHeight: 7,
                                      backgroundColor: Colors.grey.shade200,
                                      color: log.stateAtLog.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(log.canopyGreennessIndex * 100).toInt()}% Green',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(log.note, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. CNN Diagnostic History (Pests, Diseases, Sunburn)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CNN Vision Diagnostic History & Treatments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...plant.diagnosticHistory.map((diag) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                diag.condition,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                diag.resolved ? 'Resolved' : 'Active Regimen',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: diag.resolved
                                  ? Colors.green.shade100
                                  : Colors.amber.shade100,
                            ),
                          ],
                        ),
                        Text(
                          'Detected: ${diag.date} • CNN Confidence: ${(diag.cnnConfidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Protocol: ${diag.treatmentProtocol}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEATURE 5: SETTINGS, PRIVACY, SPATIAL DATA & LUX SENSOR CALIBRATION
// ============================================================================
class SettingsPrivacyScreen extends StatefulWidget {
  final AppStateController appState;
  const SettingsPrivacyScreen({super.key, required this.appState});

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  double _simulatedPhoneLuxReading = 12000.0;

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings, Spatial Data & Calibration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Granular Notification Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Granular Notification Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mute Routine Watering Reminders'),
                    subtitle: const Text('Silences standard low-priority hydration pings'),
                    value: app.muteRoutineWatering,
                    onChanged: (v) {
                      app.muteRoutineWatering = v;
                      app.triggerChange();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Critical Seasonal Relocation Alerts'),
                    subtitle: const Text('Notify when solar declination shifts DLI out of bounds'),
                    value: app.enableSeasonalRelocationAlerts,
                    onChanged: (v) {
                      app.enableSeasonalRelocationAlerts = v;
                      app.triggerChange();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('FSM "Recovery Mode" Emergency Triggers'),
                    subtitle: const Text('High-priority alerts for CNN pathology or acute stress'),
                    value: app.enableRecoveryModeTriggers,
                    onChanged: (v) {
                      app.enableRecoveryModeTriggers = v;
                      app.triggerChange();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Spatial Data Management (AR Scanner & Obstruction Skyline)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spatial Data & AR Room Mesh Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'External Skyline Obstruction Mask: ${(app.externalObstructionFactor * 100).toInt()}% Blocked',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Slider(
                    value: app.externalObstructionFactor,
                    min: 0.0,
                    max: 0.85,
                    divisions: 17,
                    label: '${(app.externalObstructionFactor * 100).toInt()}%',
                    onChanged: (v) {
                      app.externalObstructionFactor = v;
                      app.triggerChange();
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.radar),
                        label: const Text('Rescan Room with AR Scanner'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ARCore/ARKit LiDAR Mesh Rescan initiated... Furniture anchors updated.'),
                            ),
                          );
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Delete 3D Room Mapping Data', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('3D Point-Cloud & Spatial Mesh purged from local & cloud storage.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Hardware Lux Sensor Calibration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Physical Lux Sensor Calibration Override',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Place your phone flat at window level to benchmark real-world ambient Lux against the simulated SunCalc DLI grid.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Photodiode Reading: ${_simulatedPhoneLuxReading.toInt()} Lux',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(
                          'Calibration Factor: ${app.sensorCalibrationMultiplier.toStringAsFixed(2)}x',
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _simulatedPhoneLuxReading,
                    min: 2000,
                    max: 25000,
                    divisions: 46,
                    onChanged: (v) {
                      setState(() => _simulatedPhoneLuxReading = v);
                    },
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.sensors),
                    label: const Text('Calibrate Simulated DLI Grid Now'),
                    onPressed: () {
                      app.calibrateLuxSensor(_simulatedPhoneLuxReading);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'DLI Grid recalibrated to ${app.sensorCalibrationMultiplier.toStringAsFixed(2)}x using ${_simulatedPhoneLuxReading.toInt()} Lux reference.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}