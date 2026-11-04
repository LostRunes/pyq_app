import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const CampusPulseApp());
}

// ─── CONSTANTS ────────────────────────────────────────
const kCream = Color(0xFFF5F2EA);
const kPurple = Color(0xFF7C6FF7);
const kPurpleLight = Color(0xFFE2DDF8);
const kGreen = Color(0xFF4CAF50);
const kOrange = Color(0xFFFF9800);
const kRed = Color(0xFFF44336);
const kCard = Color(0xFFEDEAE0);

// ─── FAKE DATA ────────────────────────────────────────
final _rand = Random(42);
List<double> _fakeSparkline() => List.generate(6, (_) => 0.1 + _rand.nextDouble() * 0.85);

final List<Map<String, dynamic>> kLocations = [
  {
    'name': 'Central Mess',
    'status': 'Packed',
    'color': kRed,
    'floors': null,
    'spark': _fakeSparkline(),
    'bestTime': '7:30 AM – 8:30 AM',
    'worstTime': '12:00 PM – 2:00 PM',
  },
  {
    'name': 'Library',
    'status': 'Moderate',
    'color': kOrange,
    'floors': ['Floor 1 — Packed', 'Floor 2 — Moderate', 'Floor 3 — Empty'],
    'spark': _fakeSparkline(),
    'bestTime': '6:00 PM – 8:00 PM',
    'worstTime': '10:00 AM – 12:00 PM',
  },
  {
    'name': 'Canteen',
    'status': 'Packed',
    'color': kRed,
    'floors': null,
    'spark': _fakeSparkline(),
    'bestTime': '3:00 PM – 5:00 PM',
    'worstTime': '1:00 PM – 2:00 PM',
  },
  {
    'name': 'Gymnasium',
    'status': 'Empty',
    'color': kGreen,
    'floors': null,
    'spark': _fakeSparkline(),
    'bestTime': 'Anytime before 6 PM',
    'worstTime': '6:00 PM – 8:00 PM',
  },
  {
    'name': 'Hostel Common Room',
    'status': 'Moderate',
    'color': kOrange,
    'floors': null,
    'spark': _fakeSparkline(),
    'bestTime': '2:00 PM – 4:00 PM',
    'worstTime': '9:00 PM – 11:00 PM',
  },
];

final List<Map<String, String>> kPulseFeed = [
  {'user': 'Rahul M.', 'action': 'checked into Library Floor 2', 'time': '2m ago'},
  {'user': 'Priya S.', 'action': 'reported Central Mess as Packed', 'time': '5m ago'},
  {'user': 'Arjun K.', 'action': 'checked into Gymnasium', 'time': '8m ago'},
  {'user': 'Ananya R.', 'action': 'reported Canteen as Packed', 'time': '12m ago'},
  {'user': 'Dev P.', 'action': 'checked into Library Floor 3', 'time': '15m ago'},
  {'user': 'Sneha T.', 'action': 'reported Hostel Common Room', 'time': '18m ago'},
  {'user': 'Vikram L.', 'action': 'checked into Central Mess', 'time': '22m ago'},
  {'user': 'Ishita N.', 'action': 'reported Library Floor 1', 'time': '30m ago'},
];

// ─── APP ──────────────────────────────────────────────
class CampusPulseApp extends StatelessWidget {
  const CampusPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: kCream,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: kPurpleLight,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: const Color(0xFF1A1A1A),
          displayColor: const Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const OnboardingFlow(),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────
Widget badgeRow(String label) {
  return Row(children: [
    Container(width: 8, height: 8, decoration: const BoxDecoration(color: kPurple, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: Colors.black54)),
  ]);
}

class StatusCard extends StatelessWidget {
  final String title, status;
  final Color dotColor;
  final Color? bgColor;
  const StatusCard({super.key, required this.title, required this.status, required this.dotColor, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Expanded(child: Text(status, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87))),
        ]),
      ]),
    );
  }
}

// Sparkline
class SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final linePaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.fill;
    final path = Path();
    final fill = Path();
    final dx = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = size.height - (values[i] * size.height);
      if (i == 0) { path.moveTo(x, y); fill.moveTo(x, size.height); fill.lineTo(x, y); }
      else { path.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(SparklinePainter old) => false;
}

// Expandable Location tile with floors, sparkline, best time
class LocationTileWidget extends StatefulWidget {
  final Map<String, dynamic> loc;
  const LocationTileWidget({super.key, required this.loc});
  @override
  State<LocationTileWidget> createState() => _LocationTileWidgetState();
}

class _LocationTileWidgetState extends State<LocationTileWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final List<String>? floors = loc['floors'] as List<String>?;
    final spark = loc['spark'] as List<double>;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(loc['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: loc['color'] as Color, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(loc['status'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: Colors.black38),
            ]),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            width: double.infinity,
            child: CustomPaint(painter: SparklinePainter(spark, loc['color'] as Color)),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('6h ago', style: GoogleFonts.inter(fontSize: 9, color: Colors.black26)),
            Text('now', style: GoogleFonts.inter(fontSize: 9, color: Colors.black26)),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 14),
            if (floors != null) ...[
              Text('Floors', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
              const SizedBox(height: 8),
              ...floors.map((f) {
                final parts = f.split(' — ');
                final fName = parts[0];
                final fStatus = parts.length > 1 ? parts[1] : '';
                final fColor = fStatus == 'Packed' ? kRed : fStatus == 'Moderate' ? kOrange : kGreen;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: fColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(fName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(fStatus, style: GoogleFonts.inter(fontSize: 12, color: fColor, fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
              Divider(height: 20, color: Colors.black.withOpacity(0.07)),
            ],
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Best Time', style: GoogleFonts.inter(fontSize: 11, color: kGreen, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(loc['bestTime'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Avoid', style: GoogleFonts.inter(fontSize: 11, color: kRed, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(loc['worstTime'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ])),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─── ONBOARDING ───────────────────────────────────────
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OBData(step: 'Step 01/03', badge: 'CAMPUS PULSE RADAR', title: 'Stop guessing.\nStart knowing.',
      desc: 'Real-time campus crowd radar, seat telemetry, and mess velocity delivered straight to your pocket.',
      c1Title: 'Main Library • Floor 2', c1Status: '18% Full', c1Green: true,
      c2Title: 'Dining Hall • Hub B', c2Status: 'Rush Hour', c2Green: false),
    _OBData(step: 'Step 02/03', badge: 'LIVE PULSE FEED', title: 'Community-\npowered data.',
      desc: 'Every check-in updates the radar instantly. See who went where, and when — in real time.',
      c1Title: 'Active reporters', c1Status: '24 online', c1Green: true,
      c2Title: 'Reports today', c2Status: '142 updates', c2Green: true),
    _OBData(step: 'Step 03/03', badge: 'EARN POINTS', title: 'Report.\nRank. Rise.',
      desc: 'Earn points for every crowd report. Climb the leaderboard. Unlock badges. Become campus legend.',
      c1Title: 'Your Rank', c1Status: '#12 This Week', c1Green: true,
      c2Title: 'Points Earned', c2Status: '340 pts', c2Green: true),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          itemCount: _pages.length,
          itemBuilder: (_, i) => _OBPage(data: _pages[i]),
        ),
        SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GestureDetector(
              onTap: _page > 0 ? () => _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
              child: Row(children: [
                Icon(Icons.arrow_back, size: 16, color: _page > 0 ? Colors.black87 : Colors.transparent),
                const SizedBox(width: 4),
                Text('ONBOARDING', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
              child: Text(_pages[_page].step, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
            ),
          ]),
        )),
        Positioned(left: 24, right: 24, bottom: 40,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 6),
              width: i == _page ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: i == _page ? Colors.black : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ))),
            GestureDetector(
              onTap: _next,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_page == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _OBData {
  final String step, badge, title, desc, c1Title, c1Status, c2Title, c2Status;
  final bool c1Green, c2Green;
  const _OBData({required this.step, required this.badge, required this.title, required this.desc,
    required this.c1Title, required this.c1Status, required this.c1Green,
    required this.c2Title, required this.c2Status, required this.c2Green});
}

class _OBPage extends StatefulWidget {
  final _OBData data;
  const _OBPage({required this.data});
  @override
  State<_OBPage> createState() => _OBPageState();
}

class _OBPageState extends State<_OBPage> with TickerProviderStateMixin {
  late AnimationController _rot, _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rot = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _rot.dispose(); _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(flex: 48, child: Center(
        child: ScaleTransition(scale: _pulseAnim,
          child: AnimatedBuilder(animation: _rot,
            builder: (_, __) => CustomPaint(size: const Size(260, 260), painter: _PetalPainter(_rot.value)))),
      )),
      Expanded(flex: 52, child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          badgeRow(widget.data.badge),
          const SizedBox(height: 14),
          Text(widget.data.title, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1.2)),
          const SizedBox(height: 14),
          Text(widget.data.desc, style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withOpacity(0.55), height: 1.55)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: StatusCard(title: widget.data.c1Title, status: widget.data.c1Status, dotColor: widget.data.c1Green ? kGreen : kRed)),
            const SizedBox(width: 12),
            Expanded(child: StatusCard(title: widget.data.c2Title, status: widget.data.c2Status, dotColor: widget.data.c2Green ? kGreen : kRed)),
          ]),
        ]),
      )),
    ]);
  }
}

class _PetalPainter extends CustomPainter {
  final double rotation;
  _PetalPainter(this.rotation);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    for (int ring = 2; ring >= 0; ring--) {
      for (int i = 0; i < 6; i++) {
        final angle = (2 * pi / 6) * i + rotation * 2 * pi + (ring * pi / 6);
        final r = size.width * 0.19 * (1 + ring * 0.35);
        paint.color = const Color(0xFFB8B0E8).withOpacity(0.18 + ring * 0.08);
        canvas.drawCircle(Offset(cx + r * cos(angle), cy + r * sin(angle)), size.width * 0.30 * (0.85 - ring * 0.1), paint);
      }
    }
    paint.color = Colors.black;
    canvas.drawCircle(Offset(cx, cy), 16, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 5, paint);
  }
  @override
  bool shouldRepaint(_PetalPainter old) => old.rotation != rotation;
}

// ─── MAIN SCREEN ─────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  final List<Widget> _screens = const [HomeScreen(), MapScreen(), CheckInScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _screens[_idx]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: Colors.black.withOpacity(0.07),
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar), label: 'Radar'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Report'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─── HOME SCREEN ─────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          badgeRow('CAMPUS PULSE RADAR'),
          const SizedBox(height: 14),
          Text('Stop guessing.\nStart knowing.', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -1.2)),
          const SizedBox(height: 12),
          Text('Real-time campus crowd radar, seat telemetry, and mess velocity delivered straight to your pocket.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black.withOpacity(0.55), height: 1.5)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: StatusCard(title: 'Main Library • Floor 2', status: '18% Full', dotColor: kGreen, bgColor: kCard)),
            const SizedBox(width: 12),
            Expanded(child: StatusCard(title: 'Dining Hall • Hub B', status: 'Rush Hour', dotColor: kRed, bgColor: kCard)),
          ]),
          const SizedBox(height: 28),
          // Live Pulse Feed
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.06))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE PULSE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: Colors.black54)),
                const Spacer(),
                Text('live', style: GoogleFonts.inter(fontSize: 11, color: kRed, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              ...kPulseFeed.take(4).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: kPurpleLight,
                    child: Text(e['user']![0], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87))),
                  const SizedBox(width: 10),
                  Expanded(child: RichText(text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(text: '${e['user']!} ', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: e['action']),
                    ],
                  ))),
                  const SizedBox(width: 8),
                  Text(e['time']!, style: GoogleFonts.inter(fontSize: 11, color: Colors.black38)),
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 24),
          Text('All Locations', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          Text('Tap to see floors, trends & best times', style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 12),
          ...kLocations.map((loc) => LocationTileWidget(loc: loc)),
        ],
      )),
    );
  }
}

// ─── MAP SCREEN ──────────────────────────────────────
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: badgeRow('AURA HEATMAP')),
        Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(40), decoration: const BoxDecoration(shape: BoxShape.circle, color: kPurpleLight),
            child: const Icon(Icons.map, size: 60, color: Colors.black87)),
          const SizedBox(height: 24),
          Text('Interactive Map', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Google Maps SDK will render here.', style: GoogleFonts.inter(color: Colors.black45, fontSize: 14)),
        ]))),
      ])),
    );
  }
}

// ─── CHECK-IN SCREEN ─────────────────────────────────
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? selectedLocation;
  String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          badgeRow('TACTILE TELEMETRY'),
          const SizedBox(height: 20),
          Text('Where are you\nright now?', style: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.05)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.07))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select Location...', style: GoogleFonts.inter(color: Colors.black38)),
              value: selectedLocation,
              items: kLocations.map((l) => DropdownMenuItem(value: l['name'] as String, child: Text(l['name'] as String))).toList(),
              onChanged: (val) => setState(() => selectedLocation = val),
            )),
          ),
          const SizedBox(height: 32),
          Text('How crowded is it?', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _statusBtn('Empty', kGreen)),
            const SizedBox(width: 10),
            Expanded(child: _statusBtn('Moderate', kOrange)),
            const SizedBox(width: 10),
            Expanded(child: _statusBtn('Packed', kRed)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: (selectedLocation != null && selectedStatus != null)
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Intel received. +15 Points! 🎯', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                    setState(() { selectedLocation = null; selectedStatus = null; });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: (selectedLocation != null && selectedStatus != null) ? Colors.black : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(child: Text('Submit Report', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }

  Widget _statusBtn(String text, Color color) {
    final sel = selectedStatus == text;
    return GestureDetector(
      onTap: () => setState(() => selectedStatus = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? color : Colors.black.withOpacity(0.07), width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 8),
          Text(text, style: GoogleFonts.inter(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── PROFILE SCREEN ──────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          badgeRow('YOUR PROFILE'),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 64, height: 64, decoration: const BoxDecoration(shape: BoxShape.circle, color: kPurpleLight),
              child: const Icon(Icons.person, size: 36, color: Colors.black54)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Campus Scout', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('Active reporter since Oct 2026', style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
            ]),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            _StatBox('340', 'Total Points'),
            const SizedBox(width: 12),
            _StatBox('#12', 'Rank'),
            const SizedBox(width: 12),
            _StatBox('23', 'Reports'),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: kPurpleLight, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('7 Day Streak', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text('Keep reporting to maintain your streak!', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          Text('Badges', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: const [
            _Badge('🎯', 'First Report'),
            _Badge('🔥', '7-Day Streak'),
            _Badge('📡', 'Radar Pro'),
            _Badge('👑', 'Top 15'),
            _Badge('🌙', 'Night Owl'),
          ]),
          const SizedBox(height: 24),
          Text('Recent Activity', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          ...kPulseFeed.take(5).map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withOpacity(0.05))),
            child: Row(children: [
              const Text('📍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text('You ${e['action']!}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
              Text(e['time']!, style: GoogleFonts.inter(fontSize: 11, color: Colors.black38)),
            ]),
          )),
        ],
      )),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.06))),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
      ]),
    ));
  }
}

class _Badge extends StatelessWidget {
  final String emoji, label;
  const _Badge(this.emoji, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.black.withOpacity(0.07))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
