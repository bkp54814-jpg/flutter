import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const VinzzxStudioApp());
}

const bg = Color(0xFF080D17);
const panel = Color(0xFF101827);
const panel2 = Color(0xFF172337);
const accent = Color(0xFF60A5FA);
const mint = Color(0xFF34D399);

class VinzzxStudioApp extends StatelessWidget {
  const VinzzxStudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VINZZX STUDIO',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const StudioHome(),
  );
}

enum NodeKind { player, platform, enemy, spawn }

class SceneNode {
  SceneNode(this.name, this.kind, this.x, this.y, {this.width = 72, this.height = 28});
  String name;
  NodeKind kind;
  double x, y, width, height;
  bool visible = true;
  Map<String, dynamic> toJson() => {
    'name': name, 'type': kind.name, 'x': x, 'y': y,
    'width': width, 'height': height, 'visible': visible,
  };
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});
  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  final List<SceneNode> nodes = [
    SceneNode('Player', NodeKind.player, 170, 175, width: 34, height: 48),
    SceneNode('Platform_01', NodeKind.platform, 220, 250, width: 190, height: 18),
    SceneNode('Platform_02', NodeKind.platform, 465, 190, width: 150, height: 18),
    SceneNode('Enemy_01', NodeKind.enemy, 430, 145, width: 32, height: 42),
    SceneNode('PlayerSpawn', NodeKind.spawn, 80, 250, width: 22, height: 22),
  ];
  int selected = 0;
  bool playing = false;
  String tab = 'Scene';
  int serial = 1;
  String status = 'Ready • Scene: Main';

  SceneNode get active => nodes[selected.clamp(0, nodes.length - 1).toInt()];

  void addNode(NodeKind kind) {
    setState(() {
      serial++;
      final prefix = switch (kind) {
        NodeKind.player => 'Player',
        NodeKind.platform => 'Platform',
        NodeKind.enemy => 'Enemy',
        NodeKind.spawn => 'Spawn',
      };
      nodes.add(SceneNode('${prefix}_$serial', kind, 260 + (serial % 4) * 35,
        100 + (serial % 3) * 45,
        width: kind == NodeKind.platform ? 130 : 34,
        height: kind == NodeKind.platform ? 18 : 38));
      selected = nodes.length - 1;
      status = 'Added ${nodes.last.name}';
    });
  }

  Future<void> saveScene() async {
    final data = const JsonEncoder.withIndent('  ').convert({
      'engine': 'VINZZX STUDIO',
      'formatVersion': 1,
      'scene': 'Main',
      'nodes': nodes.map((e) => e.toJson()).toList(),
    });
    await Clipboard.setData(ClipboardData(text: data));
    setState(() => status = 'Scene JSON disalin ke clipboard');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Scene JSON disalin. Simpan sebagai file .json jika diperlukan.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        _topBar(),
        Expanded(child: Row(children: [
          SizedBox(width: 58, child: _toolRail()),
          Expanded(child: Column(children: [
            _workspaceBar(),
            Expanded(child: _sceneCanvas()),
            _bottomStatus(),
          ])),
          SizedBox(width: 205, child: _inspector()),
        ])),
      ])),
    );
  }

  Widget _topBar() => Container(
    height: 52, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: const BoxDecoration(color: panel, border: Border(bottom: BorderSide(color: Color(0xFF25334A)))),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [accent, mint]),
        borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.terminal, color: bg, size: 20)),
      const SizedBox(width: 9),
      const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VINZZX STUDIO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        Text('2D GAME ENGINE • MOBILE EDITION', style: TextStyle(fontSize: 8, color: Color(0xFF8EA2BE), letterSpacing: .8)),
      ]),
      const Spacer(),
      _topAction(Icons.folder_open, 'PROJECT'),
      const SizedBox(width: 7),
      _topAction(Icons.save_outlined, 'SAVE', onTap: saveScene),
      const SizedBox(width: 7),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: playing ? const Color(0xFFB45309) : const Color(0xFF059669),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
        onPressed: () => setState(() { playing = !playing; status = playing ? 'Play mode aktif' : 'Kembali ke Scene Editor'; }),
        icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 17),
        label: Text(playing ? 'STOP' : 'PLAY', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      ),
    ]),
  );

  Widget _topAction(IconData icon, String label, {VoidCallback? onTap}) => OutlinedButton.icon(
    onPressed: onTap ?? () => setState(() => status = '$label: fitur akan hadir pada versi berikutnya'),
    icon: Icon(icon, size: 15), label: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD3DEEE),
      side: const BorderSide(color: Color(0xFF30415B)),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
  );

  Widget _toolRail() => Container(
    decoration: const BoxDecoration(color: panel, border: Border(right: BorderSide(color: Color(0xFF25334A)))),
    child: Column(children: [
      const SizedBox(height: 8),
      _railButton(Icons.near_me, 'SELECT', selected: tab == 'Scene', onTap: () => setState(() => tab = 'Scene')),
      _railButton(Icons.widgets_outlined, 'OBJECTS', onTap: () => _showAddMenu()),
      _railButton(Icons.layers_outlined, 'LAYERS', onTap: () => setState(() => status = 'Layer panel dipilih')),
      _railButton(Icons.settings_outlined, 'SETTINGS', onTap: () => setState(() => status = 'Project settings akan ditambahkan')),
      const Spacer(),
      const Padding(padding: EdgeInsets.only(bottom: 10), child: Icon(Icons.bolt, color: mint, size: 20)),
    ]),
  );

  Widget _railButton(IconData icon, String label, {bool selected = false, VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9),
      child: Container(width: 48, height: 48, decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D3553) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: selected ? accent.withOpacity(.65) : Colors.transparent)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 19, color: selected ? accent : const Color(0xFF9AAEC8)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800)),
        ])),
    ),
  );

  void _showAddMenu() {
    showModalBottomSheet(context: context, backgroundColor: panel2, builder: (ctx) => SafeArea(
      child: Wrap(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('ADD OBJECT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
        for (final kind in NodeKind.values)
          ListTile(leading: Icon(_iconFor(kind), color: _colorFor(kind)),
            title: Text(_labelFor(kind)), onTap: () { Navigator.pop(ctx); addNode(kind); }),
      ]),
    ));
  }

  Widget _workspaceBar() => Container(height: 37, color: const Color(0xFF0C1422),
    padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
      const Icon(Icons.grid_4x4, size: 14, color: accent),
      const SizedBox(width: 7),
      const Text('MAIN.SCENE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8)),
      const SizedBox(width: 12),
      const Text('960 × 540', style: TextStyle(fontSize: 9, color: Color(0xFF8194AE))),
      const Spacer(),
      Text(playing ? 'GAME PREVIEW' : 'SCENE EDITOR', style: TextStyle(fontSize: 9, color: playing ? mint : accent, fontWeight: FontWeight.w900)),
    ]));

  Widget _sceneCanvas() => LayoutBuilder(builder: (context, box) {
    final sx = box.maxWidth / 640;
    final sy = box.maxHeight / 360;
    return GestureDetector(
      onTapDown: (d) {
        final p = Offset(d.localPosition.dx / sx, d.localPosition.dy / sy);
        for (int i = nodes.length - 1; i >= 0; i--) {
          final n = nodes[i];
          if (p.dx >= n.x && p.dx <= n.x + n.width && p.dy >= n.y && p.dy <= n.y + n.height) {
            setState(() { selected = i; status = 'Selected: ${n.name}'; }); return;
          }
        }
        setState(() => status = 'Canvas • 2D world');
      },
      onPanUpdate: (d) {
        if (playing || nodes.isEmpty) return;
        setState(() {
          active.x = (active.x + d.delta.dx / sx).clamp(0, 640 - active.width);
          active.y = (active.y + d.delta.dy / sy).clamp(0, 360 - active.height);
        });
      },
      child: CustomPaint(size: Size.infinite, painter: ScenePainter(nodes, selected, playing)),
    );
  });

  Widget _inspector() => Container(
    decoration: const BoxDecoration(color: panel, border: Border(left: BorderSide(color: Color(0xFF25334A)))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 37, padding: const EdgeInsets.symmetric(horizontal: 11), alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF25334A)))),
        child: const Text('HIERARCHY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
      Expanded(child: ListView.builder(itemCount: nodes.length, itemBuilder: (context, i) {
        final n = nodes[i];
        return InkWell(onTap: () => setState(() => selected = i), child: Container(
          color: i == selected ? const Color(0xFF1C304A) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(children: [
            Icon(_iconFor(n.kind), size: 14, color: _colorFor(n.kind)),
            const SizedBox(width: 6),
            Expanded(child: Text(n.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: i == selected ? Colors.white : const Color(0xFFB7C5D8)))),
            if (i == selected) const Icon(Icons.circle, size: 6, color: accent),
          ]),
        ));
      })),
      Container(height: 37, padding: const EdgeInsets.symmetric(horizontal: 11), alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF25334A)), bottom: BorderSide(color: Color(0xFF25334A)))),
        child: const Text('INSPECTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
      if (nodes.isNotEmpty) Expanded(flex: 2, child: ListView(padding: const EdgeInsets.all(10), children: [
        Text(active.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _numberField('Position X', active.x, (v) => setState(() => active.x = v.clamp(0, 640-active.width))),
        _numberField('Position Y', active.y, (v) => setState(() => active.y = v.clamp(0, 360-active.height))),
        _numberField('Width', active.width, (v) => setState(() => active.width = v.clamp(8, 640))),
        _numberField('Height', active.height, (v) => setState(() => active.height = v.clamp(8, 360))),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => setState(() { nodes.removeAt(selected); selected = (selected - 1).clamp(0, math.max(0, nodes.length - 1)).toInt(); status = 'Object deleted'; }),
          icon: const Icon(Icons.delete_outline, size: 15), label: const Text('DELETE OBJECT', style: TextStyle(fontSize: 9)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF87171))),
      ])),
    ]),
  );

  Widget _numberField(String label, double value, ValueChanged<double> onChanged) {
    final c = TextEditingController(text: value.toStringAsFixed(0));
    return Padding(padding: const EdgeInsets.only(top: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF91A4BE))),
      const SizedBox(height: 3),
      SizedBox(height: 34, child: TextField(controller: c, keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 11), decoration: const InputDecoration(
          filled: true, fillColor: Color(0xFF0B1320), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2B3B53)))),
        onSubmitted: (s) { final v = double.tryParse(s); if (v != null) onChanged(v); })),
    ]));
  }

  Widget _bottomStatus() => Container(height: 25, color: const Color(0xFF0C1422),
    padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
      const Icon(Icons.circle, size: 6, color: mint), const SizedBox(width: 6),
      Expanded(child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9, color: Color(0xFF9FB1C8)))),
      Text('${nodes.length} OBJECTS', style: const TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.w900)),
    ]));
}

IconData _iconFor(NodeKind k) => switch (k) {
  NodeKind.player => Icons.person,
  NodeKind.platform => Icons.view_week,
  NodeKind.enemy => Icons.smart_toy_outlined,
  NodeKind.spawn => Icons.flag_outlined,
};
Color _colorFor(NodeKind k) => switch (k) {
  NodeKind.player => accent,
  NodeKind.platform => const Color(0xFF94A3B8),
  NodeKind.enemy => const Color(0xFFF87171),
  NodeKind.spawn => mint,
};
String _labelFor(NodeKind k) => switch (k) {
  NodeKind.player => 'Player',
  NodeKind.platform => 'Platform',
  NodeKind.enemy => 'Enemy',
  NodeKind.spawn => 'Spawn Point',
};

class ScenePainter extends CustomPainter {
  ScenePainter(this.nodes, this.selected, this.playing);
  final List<SceneNode> nodes;
  final int selected;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 640, sy = size.height / 360;
    canvas.save();
    canvas.scale(sx, sy);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 360), Paint()..color = const Color(0xFF0A1321));
    final grid = Paint()..color = const Color(0xFF1B2A40)..strokeWidth = .6;
    for (int x = 0; x <= 640; x += 20) canvas.drawLine(Offset(x.toDouble(), 0), Offset(x.toDouble(), 360), grid);
    for (int y = 0; y <= 360; y += 20) canvas.drawLine(Offset(0, y.toDouble()), Offset(640, y.toDouble()), grid);
    canvas.drawRect(const Rect.fromLTWH(0, 330, 640, 30), Paint()..color = const Color(0xFF162B39));
    canvas.drawLine(const Offset(0, 330), const Offset(640, 330), Paint()..color = mint..strokeWidth = 2);
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      if (!n.visible) continue;
      final r = Rect.fromLTWH(n.x, n.y, n.width, n.height);
      final color = _colorFor(n.kind);
      if (n.kind == NodeKind.player || n.kind == NodeKind.enemy) {
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)), Paint()..color = color.withOpacity(.24));
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawCircle(Offset(n.x + n.width/2, n.y + 10), 6, Paint()..color = color);
        canvas.drawRect(Rect.fromLTWH(n.x + n.width/2 - 2, n.y + 20, 4, math.max(5, n.height-23)), Paint()..color = color);
      } else if (n.kind == NodeKind.platform) {
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = color);
        canvas.drawLine(Offset(n.x, n.y+2), Offset(n.x+n.width, n.y+2), Paint()..color = mint..strokeWidth = 2);
      } else {
        canvas.drawCircle(Offset(n.x+n.width/2, n.y+n.height/2), n.width/2, Paint()..color = mint.withOpacity(.18));
        canvas.drawCircle(Offset(n.x+n.width/2, n.y+n.height/2), n.width/2, Paint()..color = mint..style = PaintingStyle.stroke..strokeWidth = 2);
      }
      if (i == selected && !playing) {
        canvas.drawRect(r.inflate(5), Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 1.5);
        for (final p in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          canvas.drawRect(Rect.fromCenter(center: p, width: 5, height: 5), Paint()..color = Colors.white);
        }
      }
      final tp = TextPainter(text: TextSpan(text: n.name, style: const TextStyle(color: Color(0xFFCAD7E8), fontSize: 9, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout(maxWidth: 130);
      tp.paint(canvas, Offset(n.x, n.y - 13));
    }
    if (playing) {
      final tp = TextPainter(text: const TextSpan(text: 'PREVIEW MODE  •  PROTOTYPE', style: TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, const Offset(14, 14));
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) => true;
}
