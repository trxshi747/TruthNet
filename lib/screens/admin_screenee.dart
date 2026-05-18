import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF0F4FF);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF7F9FF);
  static const primary    = Color(0xFF268AFF);
  static const primaryL   = Color(0xFFD6EAFF);
  static const indigo     = Color(0xFF3B5399);
  static const purple     = Color(0xFF7C3AED);
  static const teal       = Color(0xFF0D9488);
  static const tealL      = Color(0xFFCCFBF1);
  static const amber      = Color(0xFFD97706);
  static const amberL     = Color(0xFFFEF3C7);
  static const rose       = Color(0xFFE11D48);
  static const roseL      = Color(0xFFFFE4E6);
  static const green      = Color(0xFF16A34A);
  static const greenL     = Color(0xFFDCFCE7);
  static const tx         = Color(0xFF0F1D3A);
  static const txS        = Color(0xFF6B7A99);
  static const txM        = Color(0xFFB0BAD0);
  static const border     = Color(0xFFE4EAF8);
  static const sidebar    = Color(0xFF0F1D3A);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
BoxDecoration _card({Color? shadow}) => BoxDecoration(
  color: _C.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _C.border),
  boxShadow: [BoxShadow(
      color: (shadow ?? _C.primary).withOpacity(0.06),
      blurRadius: 16, offset: const Offset(0, 4))],
);

TextStyle _ts(double size, FontWeight w, Color c, {double ls = 0}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, letterSpacing: ls);

// ─── Screen ───────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    body: Row(children: [
      const _Sidebar(),
      Expanded(child: Column(children: [
        const _TopBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            _label('Overview'),        const SizedBox(height: 14),
            const _StatCards(),        const SizedBox(height: 20),
            _label('Performance'),     const SizedBox(height: 14),
            const _ChartsRow(),        const SizedBox(height: 20),
            _label('Distribution'),    const SizedBox(height: 14),
            const _BottomRow(),        const SizedBox(height: 20),
            _label('Recent Activity'), const SizedBox(height: 14),
            const _RecentTable(),
          ]),
        )),
      ])),
    ]),
  );

  Widget _label(String t) =>
      Text(t, style: _ts(13, FontWeight.w600, _C.txS, ls: 0.8));
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatefulWidget {
  const _Sidebar();
  @override State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  int _sel = 0;
  static const _items = [
    (Icons.dashboard_rounded,            'Dashboard'),
    (Icons.people_rounded,               'Users'),
    (Icons.admin_panel_settings_rounded, 'Moderators'),
    (Icons.bar_chart_rounded,            'Analytics'),
    (Icons.assignment_ind_rounded,       'Roles'),
    (Icons.gavel_rounded,                'Rules'),
    (Icons.tune_rounded,                 'Settings'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 200, color: _C.sidebar,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 28),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: _C.primary, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.directions_bus_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text('BusTrack', style: _ts(16, FontWeight.w800, Colors.white, ls: -0.3)),
        ]),
      ),
      const SizedBox(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('MAIN MENU', style: TextStyle(
            color: Colors.white.withOpacity(0.35), fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final active = _sel == i;
            return GestureDetector(
              onTap: () => setState(() => _sel = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? _C.primary.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(_items[i].$1, size: 18,
                      color: active ? _C.primary : Colors.white.withOpacity(0.45)),
                  const SizedBox(width: 10),
                  Text(_items[i].$2, style: TextStyle(
                      color: active ? Colors.white : Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  if (active) ...[
                    const Spacer(),
                    Container(width: 4, height: 4,
                        decoration: const BoxDecoration(
                            color: _C.primary, shape: BoxShape.circle)),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(radius: 16,
                backgroundColor: _C.primary.withOpacity(0.3),
                child: Text('A', style: _ts(13, FontWeight.w700, Colors.white))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', style: _ts(12, FontWeight.w600, Colors.white)),
                  Text('Super Admin', style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 10)),
                ])),
            Icon(Icons.more_horiz_rounded,
                color: Colors.white.withOpacity(0.4), size: 16),
          ]),
        ),
      ),
    ]),
  );
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border))),
    child: Row(children: [
      Text('Dashboard', style: _ts(20, FontWeight.w800, _C.tx, ls: -0.4)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _C.primaryL, borderRadius: BorderRadius.circular(6)),
        child: Text('Overview', style: _ts(11, FontWeight.w600, _C.primary)),
      ),
      const Spacer(),
      Container(
        width: 200, height: 36,
        decoration: BoxDecoration(
            color: _C.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border)),
        child: Row(children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, color: _C.txM, size: 16),
          const SizedBox(width: 6),
          Text('Search…',
              style: TextStyle(color: _C.txM.withOpacity(0.7), fontSize: 13)),
        ]),
      ),
      const SizedBox(width: 14),
      Stack(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _C.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border)),
          child: const Icon(Icons.notifications_none_rounded,
              color: _C.txS, size: 18),
        ),
        Positioned(top: 7, right: 7,
            child: Container(width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: _C.rose, shape: BoxShape.circle))),
      ]),
      const SizedBox(width: 10),
      CircleAvatar(radius: 17,
          backgroundColor: _C.primary.withOpacity(0.15),
          child: Text('A', style: _ts(13, FontWeight.w700, _C.primary))),
    ]),
  );
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────
class _StatCards extends StatelessWidget {
  const _StatCards();

  static const _data = [
    ('Total Users', '12,480', '+8.2%',  true,  _C.primary, _C.primaryL, Icons.people_rounded),
    ('Active Today','1,832',  '+3.7%',  true,  _C.teal,    _C.tealL,    Icons.online_prediction_rounded),
    ('Reports',     '247',    '-2.1%',  false, _C.rose,    _C.roseL,    Icons.flag_rounded),
    ('Revenue',     r'$48.2k','+12.5%', true,  _C.amber,   _C.amberL,   Icons.attach_money_rounded),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(_data.length, (i) {
      final d = _data[i];
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: i < _data.length - 1 ? 14 : 0),
        child: _StatCard(label: d.$1, value: d.$2, change: d.$3,
            positive: d.$4, color: d.$5, colorL: d.$6, icon: d.$7),
      ));
    }),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value, change;
  final bool positive;
  final Color color, colorL;
  final IconData icon;
  const _StatCard({required this.label, required this.value,
    required this.change, required this.positive,
    required this.color, required this.colorL, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _card(shadow: color),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: _ts(12, FontWeight.w500, _C.txS)),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: colorL, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
      ]),
      const SizedBox(height: 12),
      Text(value, style: _ts(26, FontWeight.w800, _C.tx, ls: -0.6)),
      const SizedBox(height: 8),
      Row(children: [
        Icon(positive
            ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: positive ? _C.green : _C.rose, size: 14),
        const SizedBox(width: 4),
        Text(change,
            style: _ts(12, FontWeight.w600, positive ? _C.green : _C.rose)),
        const SizedBox(width: 4),
        Text('vs last month', style: _ts(11, FontWeight.w400, _C.txM)),
      ]),
    ]),
  );
}

// ─── Charts Row ───────────────────────────────────────────────────────────────
class _ChartsRow extends StatelessWidget {
  const _ChartsRow();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 3, child: _AreaChartCard()),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: _BarChartCard()),
    ],
  );
}

// ── Area Chart ────────────────────────────────────────────────────────────────
class _AreaChartCard extends StatelessWidget {
  //static const _u = [30.0,55,40,68,52,78,62,90,74,95,80,110];
  static const List<double> _u = [
    30.0, 55.0, 40.0, 68.0, 52.0, 78.0,
    62.0, 90.0, 74.0, 95.0, 80.0, 110.0
  ];

  static const List<double> _r = [
    12.0, 20.0, 15.0, 28.0, 18.0, 35.0,
    25.0, 42.0, 30.0, 50.0, 38.0, 55.0
  ];
  //static const _r = [12.0,20,15,28,18,35,25,42,30,50,38,55];
  static const _m = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'User Growth', subtitle: 'Monthly new users vs reports',
    legend: Row(children: [
      _Dot('Users', _C.primary),
      const SizedBox(width: 14),
      _Dot('Reports', _C.rose),
    ]),
    child: SizedBox(height: 180,
      child: CustomPaint(
        painter: _AreaPainter(
            s1: _u, s2: _r, c1: _C.primary, c2: _C.rose),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _m
              .map((m) => Text(m, style: _ts(9, FontWeight.w500, _C.txM)))
              .toList(),
        ),
      ),
    ),
  );
}

class _AreaPainter extends CustomPainter {
  final List<double> s1, s2;
  final Color c1, c2;
  const _AreaPainter(
      {required this.s1, required this.s2,
        required this.c1, required this.c2});

  @override
  void paint(Canvas canvas, Size size) {
    final mx = [...s1, ...s2].reduce(math.max) * 1.1;
    final h  = size.height - 22;
    final gp = Paint()
      ..color = _C.border.withOpacity(0.6)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = h * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }
    _area(canvas, size, h, mx, s2, c2);
    _area(canvas, size, h, mx, s1, c1);
    _line(canvas, size, h, mx, s1, c1);
    _line(canvas, size, h, mx, s2, c2);
  }

  Path _path(Size sz, double h, double mx, List<double> d) {
    final p    = Path();
    final step = sz.width / (d.length - 1);
    for (int i = 0; i < d.length; i++) {
      final x = i * step, y = h * (1 - d[i] / mx);
      if (i == 0) { p.moveTo(x, y); continue; }
      final px = (i - 1) * step, py = h * (1 - d[i - 1] / mx);
      p.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
    }
    return p;
  }

  void _area(Canvas canvas, Size sz, double h, double mx,
      List<double> d, Color c) {
    final ap = Path.from(_path(sz, h, mx, d))
      ..lineTo(sz.width, h)..lineTo(0, h)..close();
    canvas.drawPath(ap, Paint()
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [c.withOpacity(0.18), c.withOpacity(0)])
          .createShader(Rect.fromLTWH(0, 0, sz.width, h))
      ..style = PaintingStyle.fill);
  }

  void _line(Canvas canvas, Size sz, double h, double mx,
      List<double> d, Color c) {
    canvas.drawPath(_path(sz, h, mx, d), Paint()
      ..color = c..strokeWidth = 2.2
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final step = sz.width / (d.length - 1);
    final dp = Paint()..color = c;
    final wp = Paint()..color = Colors.white;
    for (int i = 0; i < d.length; i++) {
      final o = Offset(i * step, h * (1 - d[i] / mx));
      canvas.drawCircle(o, 4, dp);
      canvas.drawCircle(o, 2, wp);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────
class _BarChartCard extends StatelessWidget {
  static const _d = [
    ('Mon', 0.4, 0.6), ('Tue', 0.7, 0.5), ('Wed', 0.5, 0.8),
    ('Thu', 0.9, 0.4), ('Fri', 0.6, 0.7),
    ('Sat', 0.3, 0.5), ('Sun', 0.5, 0.3),
  ];

  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'Daily Activity', subtitle: 'Logins vs feedback submitted',
    legend: Row(children: [
      _Dot('Logins', _C.indigo),
      const SizedBox(width: 14),
      _Dot('Feedback', _C.teal),
    ]),
    child: SizedBox(height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _d.map((d) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _Rect(h: d.$2 * 150, c: _C.indigo),
              const SizedBox(width: 4),
              _Rect(h: d.$3 * 150, c: _C.teal),
            ]),
            const SizedBox(height: 6),
            Text(d.$1, style: _ts(9, FontWeight.w500, _C.txM)),
          ],
        )).toList(),
      ),
    ),
  );
}

class _Rect extends StatelessWidget {
  final double h; final Color c;
  const _Rect({required this.h, required this.c});
  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: h,
    decoration: BoxDecoration(
        color: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
  );
}

// ─── Bottom Row ───────────────────────────────────────────────────────────────
class _BottomRow extends StatelessWidget {
  const _BottomRow();
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _DonutCard()),
      const SizedBox(width: 16),
      Expanded(child: _SparkCard()),
      const SizedBox(width: 16),
      Expanded(child: _HBarCard()),
    ],
  );
}

// ── Donut ─────────────────────────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  static const _slices = [
    ('Excellent', 0.40, _C.primary),
    ('Good',      0.28, _C.teal),
    ('Average',   0.20, _C.amber),
    ('Poor',      0.12, _C.rose),
  ];

  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'Feedback Ratings',
    subtitle: 'User satisfaction breakdown',
    legend: null,
    child: SizedBox(height: 150,
      child: Row(children: [
        Expanded(child: CustomPaint(
            painter: _DonutPainter(slices: _slices))),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _slices.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: s.$3, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(s.$1, style: _ts(11, FontWeight.w400, _C.txS)),
              const SizedBox(width: 4),
              Text('${(s.$2 * 100).round()}%',
                  style: _ts(11, FontWeight.w700, _C.tx)),
            ]),
          )).toList(),
        ),
      ]),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  final List<(String, double, Color)> slices;
  const _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(size.width * .1, size.height * .1,
        size.width * .8, size.height * .8);
    double a = -math.pi / 2;
    for (final s in slices) {
      final sw = 2 * math.pi * s.$2;
      canvas.drawArc(r, a, sw, false, Paint()
        ..color = s.$3..strokeWidth = 22
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.butt);
      a += sw;
    }
    void draw(String t, TextStyle st, double dy) {
      final tp = TextPainter(
          text: TextSpan(text: t, style: st),
          textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(
          size.width / 2 - tp.width / 2,
          size.height / 2 + dy));
    }
    draw('40%', const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: _C.tx), -10);
    draw('Excellent',
        const TextStyle(fontSize: 9, color: _C.txS), 10);
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Sparkline ─────────────────────────────────────────────────────────────────
class _SparkCard extends StatelessWidget {
  //static const _d = [20.0,45,30,60,40,80,55,70,50,90,65,100];
  static const List<double> _d = [
    20.0, 45.0, 30.0, 60.0, 40.0, 80.0,
    55.0, 70.0, 50.0, 90.0, 65.0, 100.0
  ];

  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'Revenue Trend', subtitle: 'Last 12 weeks', legend: null,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(r'$48.2k',
            style: _ts(22, FontWeight.w800, _C.tx, ls: -0.5)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: _C.greenL, borderRadius: BorderRadius.circular(6)),
          child: Text('+12.5%', style: _ts(11, FontWeight.w600, _C.green)),
        ),
      ]),
      const SizedBox(height: 16),
      SizedBox(height: 90,
          child: CustomPaint(
              painter: _SparkPainter(data: _d, color: _C.purple),
              size: Size.infinite)),
    ]),
  );
}

class _SparkPainter extends CustomPainter {
  final List<double> data; final Color color;
  const _SparkPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size sz) {
    final mx   = data.reduce(math.max);
    final step = sz.width / (data.length - 1);
    final p    = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * step, y = sz.height * (1 - data[i] / mx * 0.9);
      if (i == 0) { p.moveTo(x, y); continue; }
      final px = (i - 1) * step;
      final py = sz.height * (1 - data[i - 1] / mx * 0.9);
      p.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
    }
    final area = Path.from(p)
      ..lineTo(sz.width, sz.height)..lineTo(0, sz.height)..close();
    canvas.drawPath(area, Paint()
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.2), color.withOpacity(0)])
          .createShader(Rect.fromLTWH(0, 0, sz.width, sz.height))
      ..style = PaintingStyle.fill);
    canvas.drawPath(p, Paint()
      ..color = color..strokeWidth = 2.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Horizontal Bars ───────────────────────────────────────────────────────────
class _HBarCard extends StatelessWidget {
  static const _d = [
    ('Route 42', 0.85, _C.primary),
    ('Route 17', 0.72, _C.teal),
    ('Route 08', 0.60, _C.purple),
    ('Route 31', 0.45, _C.amber),
    ('Route 05', 0.28, _C.rose),
  ];

  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'Top Routes', subtitle: 'By feedback volume', legend: null,
    child: SizedBox(height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _d.map((d) => Row(children: [
          SizedBox(width: 56,
              child: Text(d.$1, style: _ts(11, FontWeight.w500, _C.txS))),
          Expanded(child: Stack(children: [
            Container(height: 8, decoration: BoxDecoration(
                color: _C.border, borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(widthFactor: d.$2,
                child: Container(height: 8, decoration: BoxDecoration(
                    color: d.$3, borderRadius: BorderRadius.circular(4)))),
          ])),
          const SizedBox(width: 8),
          SizedBox(width: 30,
              child: Text('${(d.$2 * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: _ts(11, FontWeight.w700, d.$3))),
        ])).toList(),
      ),
    ),
  );
}

// ─── Recent Table ─────────────────────────────────────────────────────────────
class _RecentTable extends StatelessWidget {
  const _RecentTable();

  static const _rows = [
    ('user_2947','Feedback Submitted','Route 42','Excellent','2 min ago', _C.green,  true),
    ('user_1103','Account Created',   '—',       '—',        '15 min ago',_C.primary,true),
    ('user_0831','Report Filed',      'Route 08','Poor',     '1 hr ago',  _C.rose,   false),
    ('user_3356','Feedback Submitted','Route 17','Good',     '2 hr ago',  _C.teal,   true),
    ('user_2201','Role Changed',      '—',       'Moderator','3 hr ago',  _C.purple, true),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border)),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Text('Recent Activity', style: _ts(14, FontWeight.w700, _C.tx)),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                backgroundColor: _C.primaryL,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text('View All',
                style: _ts(12, FontWeight.w600, _C.primary)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: const [
          Expanded(flex: 2, child: _CH('USER')),
          Expanded(flex: 3, child: _CH('ACTION')),
          Expanded(flex: 2, child: _CH('ROUTE')),
          Expanded(flex: 2, child: _CH('RATING')),
          Expanded(flex: 2, child: _CH('TIME')),
          Expanded(flex: 1, child: _CH('STATUS')),
        ]),
      ),
      const Divider(height: 1, color: _C.border),
      ..._rows.map((r) => _TR(r: r)),
      const SizedBox(height: 8),
    ]),
  );
}

class _CH extends StatelessWidget {
  final String t; const _CH(this.t);
  @override
  Widget build(BuildContext context) =>
      Text(t, style: _ts(10, FontWeight.w700, _C.txM, ls: 0.8));
}

class _TR extends StatelessWidget {
  final (String,String,String,String,String,Color,bool) r;
  const _TR({required this.r});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border, width: 0.5))),
    child: Row(children: [
      Expanded(flex: 2, child: Row(children: [
        CircleAvatar(radius: 13,
            backgroundColor: r.$6.withOpacity(0.15),
            child: Text(r.$1[5].toUpperCase(),
                style: _ts(10, FontWeight.w700, r.$6))),
        const SizedBox(width: 8),
        Flexible(child: Text(r.$1, overflow: TextOverflow.ellipsis,
            style: _ts(12, FontWeight.w600, _C.tx))),
      ])),
      Expanded(flex: 3,
          child: Text(r.$2, style: _ts(12, FontWeight.w400, _C.txS))),
      Expanded(flex: 2,
          child: Text(r.$3, style: _ts(12, FontWeight.w400, _C.txS))),
      Expanded(flex: 2, child: r.$4 == '—'
          ? Text('—', style: _ts(12, FontWeight.w400, _C.txM))
          : Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: r.$6.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text(r.$4, style: _ts(11, FontWeight.w600, r.$6)))),
      Expanded(flex: 2,
          child: Text(r.$5, style: _ts(11, FontWeight.w400, _C.txM))),
      Expanded(flex: 1, child: Container(width: 8, height: 8,
          decoration: BoxDecoration(
              color: r.$7 ? _C.green : _C.rose,
              shape: BoxShape.circle))),
    ]),
  );
}

// ─── Shared Card Shell ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final Widget? legend;
  final Widget child;
  const _ChartCard({required this.title, required this.subtitle,
    required this.legend, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _card(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: _ts(14, FontWeight.w700, _C.tx)),
          const SizedBox(height: 2),
          Text(subtitle, style: _ts(11, FontWeight.w400, _C.txS)),
        ]),
        if (legend != null) legend!,
      ]),
      const SizedBox(height: 18),
      child,
    ]),
  );
}

// ─── Legend Dot ───────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final String label; final Color color;
  const _Dot(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: _ts(11, FontWeight.w500, _C.txS)),
  ]);
}