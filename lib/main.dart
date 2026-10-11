import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const VinzzxStudioApp());
}

const bg = Color(0xFF080D17), panel = Color(0xFF101827), panel2 = Color(0xFF172337);
const accent = Color(0xFF60A5FA), mint = Color(0xFF34D399), muted = Color(0xFF8EA2BE);

class VinzzxStudioApp extends StatelessWidget {
  const VinzzxStudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'VINZZX STUDIO', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark), useMaterial3: true),
    home: const StudioHome(),
  );
}

enum AssetRole { character, enemy, health, background, platform, bullet, effect, ui, other }
extension AssetRoleLabel on AssetRole {
  String get label => switch (this) {
    AssetRole.character => 'Karakter / Player', AssetRole.enemy => 'Musuh / Enemy',
    AssetRole.health => 'Nyawa / Health', AssetRole.background => 'Background',
    AssetRole.platform => 'Platform', AssetRole.bullet => 'Peluru / Projectile',
    AssetRole.effect => 'Efek / VFX', AssetRole.ui => 'UI / Icon', AssetRole.other => 'Lainnya',
  };
}

class SpriteAsset {
  SpriteAsset({required this.name, required this.bytes, required this.image, this.role = AssetRole.character,
    this.rows = 4, this.columns = 4, this.fps = 8, this.zoom = 2, this.script = defaultScript});
  final String name;
  final Uint8List bytes;
  final ui.Image image;
  AssetRole role;
  int rows, columns, fps;
  double zoom;
  String script;
  int cropX = 0, cropY = 0, frameWidthOverride = 0, frameHeightOverride = 0;
  int get frameWidth => math.max(1, frameWidthOverride > 0 ? frameWidthOverride : image.width ~/ columns);
  int get frameHeight => math.max(1, frameHeightOverride > 0 ? frameHeightOverride : image.height ~/ rows);
  int get frameCount => rows * columns;
  Map<String, dynamic> toJson({bool includeImage = true}) => {
    'name': name, 'role': role.name, 'rows': rows, 'columns': columns, 'fps': fps,
    'frameWidth': frameWidth, 'frameHeight': frameHeight, 'cropX': cropX, 'cropY': cropY, 'behaviorScript': script,
    if (includeImage) 'pngBase64': base64Encode(bytes),
  };
  static const defaultScript = '''// VINZZX 2D behavior script (template)
// role: character | enemy | health | background | platform | bullet
// events available in runtime: onStart(), onUpdate(dt), onTap(), onHit()
void onStart() {
  // Set nilai awal karakter di sini
}
void onUpdate(double dt) {
  // dt = waktu sejak frame sebelumnya
  // Contoh: position.x += speed * dt;
}
void onHit() {
  // Kurangi health / jalankan efek ketika terkena hit
}''';
}

class StudioHome extends StatefulWidget {
  const StudioHome({super.key});
  @override State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> with SingleTickerProviderStateMixin {
  final picker = ImagePicker();
  final List<SpriteAsset> assets = [];
  final List<SceneObject> objects = []; // Project baru dimulai dengan scene kosong.
  int tab = 0, selectedAsset = -1, selectedObject = 0, frame = 0;
  String _dragAxis = '';
  Offset _lastDragPoint = Offset.zero;
  bool playing = false, showGrid = true;
  String status = 'Siap • Import PNG untuk mulai';
  late final AnimationController ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener(_tick);
  DateTime? lastTick;
  double gameTime = 0, playerX = 100, playerVX = 0;
  int health = 100;
  final TextEditingController rowsCtrl = TextEditingController(text: '4');
  final TextEditingController colsCtrl = TextEditingController(text: '4');
  final TextEditingController fpsCtrl = TextEditingController(text: '8');
  final TextEditingController scriptCtrl = TextEditingController(text: SpriteAsset.defaultScript);

  SpriteAsset? get activeAsset => selectedAsset >= 0 && selectedAsset < assets.length ? assets[selectedAsset] : null;
  SceneObject? get activeObject => objects.isEmpty ? null : objects[selectedObject.clamp(0, objects.length - 1).toInt()];

  @override void dispose() { ticker.dispose(); rowsCtrl.dispose(); colsCtrl.dispose(); fpsCtrl.dispose(); scriptCtrl.dispose(); super.dispose(); }

  void _tick() {
    final now = DateTime.now(); final double dt = lastTick == null ? 0.016 : (now.difference(lastTick!).inMilliseconds / 1000).clamp(0.001, 0.06).toDouble(); lastTick = now;
    if (!playing) return;
    gameTime += dt;
    final characterAssets = assets.where((asset) => asset.role == AssetRole.character).toList();
    final a = characterAssets.isNotEmpty ? characterAssets.first : activeAsset;
    if (a != null) frame = (gameTime * a.fps).floor() % a.frameCount;
    setState(() { playerX += playerVX * dt; playerX = playerX.clamp(20, 560).toDouble(); });
  }

  Future<void> importPng() async {
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, requestFullMetadata: false);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      final asset = SpriteAsset(name: file.name, bytes: bytes, image: image);
      setState(() { assets.add(asset); selectedAsset = assets.length - 1; tab = 1; frame = 0; rowsCtrl.text = '4'; colsCtrl.text = '4'; fpsCtrl.text = '8'; scriptCtrl.text = asset.script; status = 'Import ${file.name} • ${image.width}×${image.height}'; });
    } catch (e) { _message('Gagal import gambar: $e'); }
  }

  void applySheetSettings() {
    final a = activeAsset; if (a == null) return;
    final r = int.tryParse(rowsCtrl.text.trim()), c = int.tryParse(colsCtrl.text.trim()), f = int.tryParse(fpsCtrl.text.trim());
    if (r == null || c == null || f == null || r < 1 || c < 1 || r > 64 || c > 64 || f < 1 || f > 60) { _message('Baris/kolom 1–64 dan FPS 1–60.'); return; }
    if (a.image.width ~/ c < 1 || a.image.height ~/ r < 1) { _message('Ukuran frame tidak valid.'); return; }
    setState(() { a.rows = r; a.columns = c; a.fps = f; a.script = scriptCtrl.text; frame %= a.frameCount; status = 'Sprite sheet: ${c}×$r • ${a.frameWidth}×${a.frameHeight}px • $f FPS'; });
  }

  void addObject(AssetRole role) {
    setState(() { objects.add(SceneObject(name: '${role.name}_${objects.length + 1}', role: role, x: 180, y: 140, w: role == AssetRole.platform ? 150 : 48, h: role == AssetRole.platform ? 20 : 52, assetIndex: selectedAsset)); selectedObject = objects.length - 1; status = 'Objek ditambahkan: ${role.label}'; });
  }

  Future<void> saveProject() async {
    final project = <String, dynamic>{'engine': 'VINZZX STUDIO', 'version': '0.2.0', 'canvas': {'width': 640, 'height': 360},
      'assets': assets.map((a) => a.toJson()).toList(), 'objects': objects.map((o) => o.toJson()).toList()};
    final data = const JsonEncoder.withIndent('  ').convert(project);
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    setState(() => status = 'Project JSON + PNG base64 disalin ke clipboard');
    _message('Project JSON disalin. PNG ikut disertakan sebagai Base64; simpan ke file .json.');
  }

  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 3))); }

  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Column(children: [
    _topBar(), Expanded(child: Row(children: [SizedBox(width: 62, child: _rail()), Expanded(child: Column(children: [_tabBar(), Expanded(child: _content()), _statusBar()]))]))
  ])));

  Widget _topBar() => Container(height: 48, color: panel, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
    Container(width: 29, height: 29, decoration: BoxDecoration(gradient: const LinearGradient(colors: [accent, mint]), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.code, color: bg, size: 19)),
    const SizedBox(width: 8), const Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('VINZZX STUDIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)), Text('2D GAME ENGINE • MOBILE', style: TextStyle(fontSize: 8, color: muted, letterSpacing: .7))]),
    const Spacer(), _action(Icons.add_photo_alternate_outlined, 'IMPORT PNG', importPng), const SizedBox(width: 7), _action(Icons.save_outlined, 'SAVE PROJECT', saveProject), const SizedBox(width: 7),
    FilledButton.icon(onPressed: () => setState(() { playing = !playing; lastTick = DateTime.now(); if (playing) { gameTime = 0; frame = 0; playerX = 100; health = 100; ticker.repeat(); tab = 2; status = 'Preview game berjalan'; } else { ticker.stop(); status = 'Preview dihentikan'; } }), icon: Icon(playing ? Icons.stop : Icons.play_arrow, size: 17), label: Text(playing ? 'STOP' : 'TEST GAME', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)), style: FilledButton.styleFrom(backgroundColor: playing ? const Color(0xFFB45309) : const Color(0xFF059669), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
    const SizedBox(width: 5),
  ]));

  Widget _action(IconData icon, String label, VoidCallback tap) => OutlinedButton.icon(onPressed: tap, icon: Icon(icon, size: 14), label: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9), side: const BorderSide(color: Color(0xFF30415B)), foregroundColor: const Color(0xFFD3DEEE)));

  Widget _rail() => Container(color: panel, child: Column(children: [const SizedBox(height: 8), _railBtn(Icons.grid_view, 'SCENE', 0), _railBtn(Icons.animation, 'SPRITES', 1), _railBtn(Icons.gamepad, 'PREVIEW', 2), _railBtn(Icons.code, 'SCRIPT', 3), const Spacer(), const Icon(Icons.bolt, color: mint), const SizedBox(height: 10)]));
  Widget _railBtn(IconData icon, String label, int index) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: InkWell(onTap: () => setState(() => tab = index), child: Container(width: 52, height: 48, decoration: BoxDecoration(color: tab == index ? const Color(0xFF1D3553) : Colors.transparent, borderRadius: BorderRadius.circular(9)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 19, color: tab == index ? accent : muted), const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900))]))));
  Widget _tabBar() => Container(height: 34, color: const Color(0xFF0C1422), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Icon([Icons.grid_view, Icons.animation, Icons.gamepad, Icons.code][tab], size: 14, color: accent), const SizedBox(width: 7), Text(['SCENE EDITOR', 'SPRITE WORKSHOP', 'GAME PREVIEW', 'BEHAVIOR SCRIPT'][tab], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7)), const Spacer(), Text(tab == 1 ? '${assets.length} asset(s)' : '${objects.length} object(s)', style: const TextStyle(color: muted, fontSize: 9))]));
  Widget _content() => switch (tab) { 0 => _sceneTab(), 1 => _spriteTab(), 2 => _previewTab(), _ => _scriptTab() };
  Widget _statusBar() => Container(height: 23, padding: const EdgeInsets.symmetric(horizontal: 10), color: panel, child: Row(children: [const Icon(Icons.circle, color: mint, size: 7), const SizedBox(width: 6), Expanded(child: Text(status, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: muted))), const Text('PNG • SPRITESHEET • 2D', style: TextStyle(fontSize: 8, color: muted))]));

  Widget _sceneTab() => Row(children: [
    SizedBox(
      width: 145,
      child: _sidePanel('HIERARCHY', Column(children: [
        Expanded(child: ListView.builder(
          itemCount: objects.length,
          itemBuilder: (_, i) => ListTile(
            dense: true,
            selected: selectedObject == i,
            selectedTileColor: const Color(0xFF1D3553),
            leading: Icon(_roleIcon(objects[i].role), size: 16, color: accent),
            title: Text(objects[i].name, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
            onTap: () => setState(() => selectedObject = i),
          ),
        )),
        Wrap(spacing: 3, children: [
          IconButton(tooltip: 'Tambah objek', onPressed: _chooseRole, icon: const Icon(Icons.add_box_outlined, size: 18)),
          IconButton(tooltip: 'Hapus objek', onPressed: objects.isEmpty ? null : () => setState(() {
            objects.removeAt(selectedObject);
            selectedObject = (selectedObject - 1).clamp(0, math.max(0, objects.length - 1)).toInt();
          }), icon: const Icon(Icons.delete_outline, size: 18)),
        ]),
      ])),
    ),
    Expanded(child: Column(children: [
      Expanded(child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(builder: (_, c) => GestureDetector(
          onPanUpdate: (d) {
            final o = activeObject;
            if (o == null || playing) return;
            setState(() {
              o.x = (o.x + d.delta.dx / (c.maxWidth / 640)).clamp(0, 600).toDouble();
              o.y = (o.y + d.delta.dy / (c.maxHeight / 360)).clamp(0, 330).toDouble();
            });
          },
          child: CustomPaint(size: Size.infinite, painter: ScenePainter(objects, selectedObject, assets, showGrid)),
        )),
      )),
      Container(
        height: 34, color: panel, padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(children: [
          const Text('WORLD 640 × 360', style: TextStyle(fontSize: 9, color: muted)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => showGrid = !showGrid),
            icon: Icon(showGrid ? Icons.grid_4x4 : Icons.grid_off, size: 14),
            label: Text(showGrid ? 'GRID ON' : 'GRID OFF', style: const TextStyle(fontSize: 9)),
          ),
        ]),
      ),
    ])),
    SizedBox(width: 190, child: _sidePanel('INSPECTOR', _objectInspector())),
  ]);

  Widget _sidePanel(String title, Widget child) => Container(color: panel, padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: muted, letterSpacing: .8)), const Divider(height: 14), Expanded(child: child)]));
  Widget _objectInspector() { final o = activeObject; if (o == null) return const Text('Pilih objek'); return ListView(children: [Text(o.name, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), DropdownButtonFormField<AssetRole>(value: o.role, isDense: true, decoration: const InputDecoration(labelText: 'Jenis / Role', border: OutlineInputBorder()), items: AssetRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (v) => setState(() { if (v != null) o.role = v; })), const SizedBox(height: 8), _numberField('X', o.x, (v) => o.x = v), _numberField('Y', o.y, (v) => o.y = v), _numberField('Width', o.w, (v) => o.w = v), _numberField('Height', o.h, (v) => o.h = v), const SizedBox(height: 8), DropdownButtonFormField<int>(value: o.assetIndex >= 0 && o.assetIndex < assets.length ? o.assetIndex : -1, isExpanded: true, decoration: const InputDecoration(labelText: 'Sprite asset', border: OutlineInputBorder()), items: [const DropdownMenuItem(value: -1, child: Text('Auto / bentuk', style: TextStyle(fontSize: 10))), ...assets.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))))], onChanged: (v) => setState(() => o.assetIndex = v ?? -1)), const SizedBox(height: 8), const Text('Geser objek di canvas untuk mengatur posisi.', style: TextStyle(fontSize: 9, color: muted))]); }
  Widget _numberField(String label, double value, ValueChanged<double> update) => Padding(padding: const EdgeInsets.only(bottom: 7), child: TextFormField(key: ValueKey(label), initialValue: value.toStringAsFixed(0), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(9)), onChanged: (s) { final v = double.tryParse(s); if (v != null) setState(() => update(v)); }));
  void _chooseRole() { showModalBottomSheet(context: context, backgroundColor: panel2, builder: (ctx) => SafeArea(child: Wrap(children: [const ListTile(title: Text('Tambah objek', style: TextStyle(fontWeight: FontWeight.w900))), ...AssetRole.values.map((r) => ListTile(leading: Icon(_roleIcon(r), color: accent), title: Text(r.label), onTap: () { Navigator.pop(ctx); addObject(r); }))]))); }

  Widget _spriteTab() => Row(children: [
    SizedBox(width: 155, child: _sidePanel('ASSET LIBRARY', Column(children: [Expanded(child: assets.isEmpty ? const Center(child: Text('Belum ada PNG\nTekan IMPORT PNG', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11))) : ListView.builder(itemCount: assets.length, itemBuilder: (_, i) => ListTile(dense: true, selected: selectedAsset == i, selectedTileColor: const Color(0xFF1D3553), leading: SizedBox(width: 30, height: 30, child: Image.memory(assets[i].bytes, fit: BoxFit.contain)), title: Text(assets[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)), subtitle: Text(assets[i].role.label, style: const TextStyle(fontSize: 8, color: muted)), onTap: () => setState(() { selectedAsset = i; frame = 0; rowsCtrl.text = '${assets[i].rows}'; colsCtrl.text = '${assets[i].columns}'; fpsCtrl.text = '${assets[i].fps}'; scriptCtrl.text = assets[i].script; }))),), FilledButton.icon(onPressed: importPng, icon: const Icon(Icons.add_photo_alternate, size: 16), label: const Text('Import dari galeri', style: TextStyle(fontSize: 9))) ]))),
    Expanded(child: activeAsset == null ? Center(child: FilledButton.icon(onPressed: importPng, icon: const Icon(Icons.image), label: const Text('Pilih PNG transparan dari galeri'))) : _spriteWorkspace(activeAsset!)),
    SizedBox(width: 205, child: _sidePanel('FRAME SETTINGS', _frameSettings(activeAsset))),
  ]);

  Widget _spriteWorkspace(SpriteAsset a) => Column(children: [
    Expanded(child: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF0A1220), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF26364E))),
      child: Column(children: [
        Container(height: 29, padding: const EdgeInsets.symmetric(horizontal: 9), child: Row(children: [
          const Text('SPRITESHEET CUTTER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
          const Spacer(), Text('${a.image.width}×${a.image.height}px', style: const TextStyle(fontSize: 9, color: muted)),
        ])),
        Expanded(child: Center(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(child: GestureDetector(
            onTapDown: (d) {
              final px = d.localPosition.dx / a.zoom - a.cropX;
              final py = d.localPosition.dy / a.zoom - a.cropY;
              final col = (px / a.frameWidth).floor().clamp(0, a.columns - 1).toInt();
              final row = (py / a.frameHeight).floor().clamp(0, a.rows - 1).toInt();
              setState(() => frame = row * a.columns + col);
            },
            onPanStart: (d) {
              final px = d.localPosition.dx / a.zoom, py = d.localPosition.dy / a.zoom;
              final nearLeft = (px - a.cropX).abs() < 12;
              final nearTop = (py - a.cropY).abs() < 12;
              final nearVertical = (px - (a.cropX + a.columns * a.frameWidth)).abs() < 12 || ((px-a.cropX)/a.frameWidth - ((px-a.cropX)/a.frameWidth).round()).abs() < 0.15;
              final nearHorizontal = (py - (a.cropY + a.rows * a.frameHeight)).abs() < 12 || ((py-a.cropY)/a.frameHeight - ((py-a.cropY)/a.frameHeight).round()).abs() < 0.15;
              _dragAxis = nearLeft ? 'x' : nearTop ? 'y' : nearVertical ? 'w' : nearHorizontal ? 'h' : '';
              _lastDragPoint = d.localPosition;
            },
            onPanUpdate: (d) {
              if (_dragAxis.isEmpty) return;
              final dx = ((d.localPosition.dx - _lastDragPoint.dx) / a.zoom).round();
              final dy = ((d.localPosition.dy - _lastDragPoint.dy) / a.zoom).round();
              setState(() {
                if (_dragAxis == 'x') a.cropX = (a.cropX + dx).clamp(0, math.max(0, a.image.width - a.frameWidth * a.columns)).toInt();
                if (_dragAxis == 'y') a.cropY = (a.cropY + dy).clamp(0, math.max(0, a.image.height - a.frameHeight * a.rows)).toInt();
                if (_dragAxis == 'w') a.frameWidthOverride = (a.frameWidth + dx).clamp(1, math.max(1, (a.image.width-a.cropX) ~/ a.columns)).toInt();
                if (_dragAxis == 'h') a.frameHeightOverride = (a.frameHeight + dy).clamp(1, math.max(1, (a.image.height-a.cropY) ~/ a.rows)).toInt();
              });
              _lastDragPoint = d.localPosition;
            },
            onPanEnd: (_) { _dragAxis = ''; },
            child: CustomPaint(painter: SpriteSheetPainter(a, frame), size: Size(a.image.width * a.zoom, a.image.height * a.zoom)),
          )),
        ))),
      ]),
    )),
    Container(
      height: 100, margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('FRAME STRIP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)), const Spacer(), Text('Frame ${frame + 1}/${a.frameCount}', style: const TextStyle(fontSize: 9, color: muted))]),
        const SizedBox(height: 6),
        Expanded(child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: a.frameCount,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => frame = i),
            child: Container(
              width: 58, margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: frame == i ? const Color(0xFF1D3553) : panel, border: Border.all(color: frame == i ? accent : const Color(0xFF29374B)), borderRadius: BorderRadius.circular(6)),
              child: Column(children: [Expanded(child: CustomPaint(size: Size.infinite, painter: SingleFramePainter(a, i))), Text('${i + 1}', style: const TextStyle(fontSize: 8))]),
            ),
          ),
        )),
      ]),
    ),
  ]);

  Widget _frameSettings(SpriteAsset? a) { if (a == null) return const Text('Import PNG terlebih dahulu', style: TextStyle(color: muted, fontSize: 10)); return ListView(children: [Text(a.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8), DropdownButtonFormField<AssetRole>(value: a.role, isExpanded: true, decoration: const InputDecoration(labelText: 'Gambar ini sebagai', border: OutlineInputBorder(), isDense: true), items: AssetRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label, style: const TextStyle(fontSize: 10)))).toList(), onChanged: (v) => setState(() { if (v != null) a.role = v; })), const SizedBox(height: 10), Row(children: [Expanded(child: _smallTextField('Baris / Rows', rowsCtrl, onChanged: (_) => applySheetSettings())), const SizedBox(width: 6), Expanded(child: _smallTextField('Kolom / Cols', colsCtrl, onChanged: (_) => applySheetSettings()))]), const SizedBox(height: 7), _smallTextField('FPS (1–60)', fpsCtrl, onChanged: (_) => applySheetSettings()), const SizedBox(height: 8), Text('Frame: ${a.frameWidth} × ${a.frameHeight} px', style: const TextStyle(fontSize: 10, color: mint, fontWeight: FontWeight.w800)), Text('Total: ${a.frameCount} frame', style: const TextStyle(fontSize: 9, color: muted)), const SizedBox(height: 8), const Text('Zoom sheet', style: TextStyle(fontSize: 9, color: muted)), Slider(value: a.zoom, min: .5, max: 4, divisions: 14, onChanged: (v) => setState(() => a.zoom = v)), FilledButton.icon(onPressed: applySheetSettings, icon: const Icon(Icons.content_cut, size: 15), label: const Text('Potong / Apply', style: TextStyle(fontSize: 10))), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () { setState(() { scriptCtrl.text = a.script; tab = 3; }); }, icon: const Icon(Icons.code, size: 15), label: const Text('Edit behavior code', style: TextStyle(fontSize: 9))), const SizedBox(height: 8), const Text('Grid langsung berubah saat Rows/Cols diganti. Seret garis oranye untuk menggeser titik awal; seret garis grid untuk mengubah lebar/tinggi frame. Pastikan grid tidak melewati batas PNG.', style: TextStyle(fontSize: 9, color: muted, height: 1.4))]); }
  Widget _smallTextField(String label, TextEditingController ctrl, {ValueChanged<String>? onChanged}) => TextField(controller: ctrl, onChanged: onChanged, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(9)), style: const TextStyle(fontSize: 11));

  Widget _previewTab() => Column(children: [
    Expanded(child: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(builder: (_, c) => GestureDetector(
        onPanUpdate: (d) => setState(() {
          playerVX = 0;
          playerX = (playerX + d.delta.dx / (c.maxWidth / 640)).clamp(20, 570).toDouble();
        }),
        onPanEnd: (_) => setState(() => playerVX = 0),
        onTap: () => setState(() { health = math.max(0, health - 10); status = 'Player terkena damage • HP $health'; }),
        child: CustomPaint(size: Size.infinite, painter: PreviewPainter(assets: assets, objects: objects, frame: frame, playerX: playerX, health: health, time: gameTime)),
      )),
    )),
    Container(height: 50, color: panel, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
      const Icon(Icons.info_outline, size: 16, color: accent), const SizedBox(width: 8),
      const Expanded(child: Text('Geser area game untuk bergerak • Tap untuk tes damage/HP', style: TextStyle(fontSize: 10, color: muted))),
      OutlinedButton.icon(onPressed: () => setState(() { health = 100; playerX = 100; gameTime = 0; frame = 0; }), icon: const Icon(Icons.refresh, size: 15), label: const Text('RESET', style: TextStyle(fontSize: 9))),
    ])),
  ]);

  Widget _scriptTab() => Row(children: [SizedBox(width: 190, child: _sidePanel('SCRIPT TARGET', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [DropdownButtonFormField<int>(value: selectedAsset >= 0 ? selectedAsset : -1, isExpanded: true, decoration: const InputDecoration(labelText: 'Asset', border: OutlineInputBorder()), items: [const DropdownMenuItem(value: -1, child: Text('Template umum')), ...assets.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.name, overflow: TextOverflow.ellipsis)))], onChanged: (v) => setState(() { selectedAsset = v ?? -1; scriptCtrl.text = activeAsset?.script ?? SpriteAsset.defaultScript; })), const SizedBox(height: 10), const Text('Event tersedia', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('onStart()\nonUpdate(dt)\nonTap()\nonHit()', style: TextStyle(fontSize: 10, color: mint, height: 1.7)), const SizedBox(height: 10), const Text('Catatan: editor kode menyimpan template script ke project. Eksekusi Dart bebas belum diaktifkan demi keamanan.', style: TextStyle(fontSize: 9, color: muted, height: 1.4))]))), Expanded(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [const Text('BEHAVIOR SCRIPT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)), const Spacer(), FilledButton.icon(onPressed: () => setState(() { if (activeAsset != null) activeAsset!.script = scriptCtrl.text; status = 'Script disimpan ke asset'; }), icon: const Icon(Icons.check, size: 15), label: const Text('Apply script', style: TextStyle(fontSize: 10)))]), const SizedBox(height: 8), Expanded(child: TextField(controller: scriptCtrl, expands: true, maxLines: null, minLines: null, textAlignVertical: TextAlignVertical.top, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.35), decoration: const InputDecoration(hintText: '// Tulis behavior karakter di sini...', border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF0A1220), contentPadding: EdgeInsets.all(12)))), const SizedBox(height: 6), const Text('Script disimpan dalam JSON project bersama role asset dan pengaturan frame.', style: TextStyle(fontSize: 9, color: muted))])))]);
}

class SceneObject {
  SceneObject({required this.name, required this.role, required this.x, required this.y, required this.w, required this.h, this.assetIndex = -1});
  String name; AssetRole role; double x, y, w, h; int assetIndex;
  Map<String, dynamic> toJson() => {'name': name, 'role': role.name, 'x': x, 'y': y, 'width': w, 'height': h, 'assetIndex': assetIndex};
}

IconData _roleIcon(AssetRole r) => switch (r) { AssetRole.character => Icons.person, AssetRole.enemy => Icons.smart_toy, AssetRole.health => Icons.favorite, AssetRole.background => Icons.landscape, AssetRole.platform => Icons.view_agenda, AssetRole.bullet => Icons.circle, AssetRole.effect => Icons.auto_awesome, AssetRole.ui => Icons.widgets, AssetRole.other => Icons.image };

class ScenePainter extends CustomPainter {
  ScenePainter(this.objects, this.selected, this.assets, this.grid);
  final List<SceneObject> objects; final int selected; final List<SpriteAsset> assets; final bool grid;
  @override void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A1220));
    final sx = size.width / 640, sy = size.height / 360;
    if (grid) { final p = Paint()..color = const Color(0xFF1A2A40)..strokeWidth = .6; for (int x=0; x<=640; x+=32) canvas.drawLine(Offset(x*sx,0), Offset(x*sx,size.height),p); for (int y=0; y<=360; y+=32) canvas.drawLine(Offset(0,y*sy),Offset(size.width,y*sy),p); }
    for (int i=0; i<objects.length; i++) { final o=objects[i]; final rect=Rect.fromLTWH(o.x*sx,o.y*sy,o.w*sx,o.h*sy); final asset=o.assetIndex>=0&&o.assetIndex<assets.length?assets[o.assetIndex]:null;
      if (asset != null) { final src=_frameRect(asset,0); canvas.drawImageRect(asset.image,src,rect,Paint()..filterQuality=FilterQuality.medium); }
      else { final color = o.role==AssetRole.platform?const Color(0xFF53677F):o.role==AssetRole.enemy?const Color(0xFFF87171):o.role==AssetRole.health?const Color(0xFFF472B6):accent; canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),Paint()..color=color.withOpacity(.22)); canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1.5); }
      if (i==selected) canvas.drawRect(rect.inflate(4),Paint()..color=accent..style=PaintingStyle.stroke..strokeWidth=1.5);
      _drawText(canvas,o.name,Offset(rect.left,rect.bottom+3),9,muted);
    }
  }
  @override bool shouldRepaint(covariant ScenePainter old) => true;
}

class SpriteSheetPainter extends CustomPainter {
  SpriteSheetPainter(this.asset,this.selected); final SpriteAsset asset; final int selected;
  @override void paint(Canvas canvas, Size size) {
    _checker(canvas,size);
    canvas.drawImageRect(asset.image, Rect.fromLTWH(0,0,asset.image.width.toDouble(),asset.image.height.toDouble()), Offset.zero & size, Paint()..filterQuality=FilterQuality.none);
    final fw=asset.frameWidth*asset.zoom, fh=asset.frameHeight*asset.zoom, ox=asset.cropX*asset.zoom, oy=asset.cropY*asset.zoom;
    final p=Paint()..color=accent..style=PaintingStyle.stroke..strokeWidth=1;
    for(int c=0;c<=asset.columns;c++) { final x=ox+c*fw; canvas.drawLine(Offset(x,oy),Offset(x,oy+asset.rows*fh),p); }
    for(int r=0;r<=asset.rows;r++) { final y=oy+r*fh; canvas.drawLine(Offset(ox,y),Offset(ox+asset.columns*fw,y),p); }
    final row=selected~/asset.columns,col=selected%asset.columns;
    final rect=Rect.fromLTWH(ox+col*fw,oy+row*fh,fw,fh);
    canvas.drawRect(rect,Paint()..color=mint.withOpacity(.25));
    canvas.drawRect(rect,Paint()..color=mint..style=PaintingStyle.stroke..strokeWidth=3);
    final handle=Paint()..color=Colors.orange..strokeWidth=3;
    canvas.drawLine(Offset(ox,oy),Offset(ox,oy+asset.rows*fh),handle);
    canvas.drawLine(Offset(ox,oy),Offset(ox+asset.columns*fw,oy),handle);
  }
  @override bool shouldRepaint(covariant SpriteSheetPainter old)=>true;
}
class SingleFramePainter extends CustomPainter { SingleFramePainter(this.asset,this.index); final SpriteAsset asset; final int index; @override void paint(Canvas canvas,Size size){_checker(canvas,size); final src=_frameRect(asset,index); final fit=math.min(size.width/src.width,size.height/src.height); final dst=Rect.fromCenter(center: Offset(size.width/2,size.height/2),width:src.width*fit,height:src.height*fit); canvas.drawImageRect(asset.image,src,dst,Paint()..filterQuality=FilterQuality.none);} @override bool shouldRepaint(covariant SingleFramePainter old)=>true; }

class PreviewPainter extends CustomPainter {
  PreviewPainter({required this.assets,required this.objects,required this.frame,required this.playerX,required this.health,required this.time}); final List<SpriteAsset> assets; final List<SceneObject> objects; final int frame,health; final double playerX,time;
  @override void paint(Canvas canvas,Size size){ final sx=size.width/640,sy=size.height/360; canvas.drawRect(Offset.zero&size,Paint()..color=const Color(0xFF14283E)); final sky=Paint()..shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF12223A),Color(0xFF263E50)]).createShader(Offset.zero&size); canvas.drawRect(Offset.zero&size,sky); for(int i=0;i<8;i++){ final x=((i*100-time*9)%760)*sx; canvas.drawCircle(Offset(x, (50+(i%3)*25)*sy), (15+(i%4)*4)*sx,Paint()..color=Colors.white.withOpacity(.035)); }
    final ground=Rect.fromLTWH(0,300*sy,size.width,60*sy); canvas.drawRect(ground,Paint()..color=const Color(0xFF26394A)); canvas.drawRect(Rect.fromLTWH(0,300*sy,size.width,3*sy),Paint()..color=mint);
    for(final o in objects.where((e)=>e.role==AssetRole.platform&&e.name!='Ground')) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.x*sx,o.y*sy,o.w*sx,o.h*sy),const Radius.circular(4)),Paint()..color=const Color(0xFF62768A));
    final player=assets.indexWhere((a)=>a.role==AssetRole.character); if(player>=0){final a=assets[player]; final src=_frameRect(a,frame%a.frameCount); final dst=Rect.fromLTWH(playerX*sx,205*sy,48*sx,65*sy); canvas.drawImageRect(a.image,src,dst,Paint()..filterQuality=FilterQuality.medium);}else{canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(playerX*sx,218*sy,38*sx,52*sy),const Radius.circular(7)),Paint()..color=accent); canvas.drawCircle(Offset((playerX+19)*sx,226*sy),7*sx,Paint()..color=const Color(0xFFFFD7B0));}
    final enemyIndex=assets.indexWhere((a)=>a.role==AssetRole.enemy); if(enemyIndex>=0){final a=assets[enemyIndex];canvas.drawImageRect(a.image,_frameRect(a,frame%a.frameCount),Rect.fromLTWH(440*sx,218*sy,40*sx,52*sy),Paint()..filterQuality=FilterQuality.medium);}else{canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(440*sx,225*sy,35*sx,45*sy),const Radius.circular(5)),Paint()..color=const Color(0xFFF87171));}
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(12*sx,12*sy,150*sx,18*sy),const Radius.circular(5)),Paint()..color=Colors.black.withOpacity(.5)); canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(16*sx,16*sy,math.max(0,health)*1.35*sx,10*sy),const Radius.circular(3)),Paint()..color=health>30?mint:const Color(0xFFF87171)); _drawText(canvas,'HP $health',Offset(16*sx,34*sy),10,Colors.white); _drawText(canvas,'VINZZX TEST ARENA',Offset(size.width-140*sx,15*sy),10,Colors.white);
  }
  @override bool shouldRepaint(covariant PreviewPainter old)=>true;
}
Rect _frameRect(SpriteAsset a,int index){final i=index.clamp(0,a.frameCount-1);final col=i%a.columns,row=i~/a.columns;return Rect.fromLTWH((a.cropX+col*a.frameWidth).toDouble(),(a.cropY+row*a.frameHeight).toDouble(),a.frameWidth.toDouble(),a.frameHeight.toDouble());}
void _checker(Canvas canvas,Size size){canvas.drawRect(Offset.zero&size,Paint()..color=const Color(0xFF111B2A)); final p=Paint()..color=const Color(0xFF1B293B); const s=12.0;for(double y=0;y<size.height;y+=s){for(double x=0;x<size.width;x+=s){if(((x/s).floor()+(y/s).floor()).isEven)canvas.drawRect(Rect.fromLTWH(x,y,s,s),p);}}}
void _drawText(Canvas canvas,String text,Offset offset,double size,Color color){final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(fontSize:size,color:color,fontWeight:FontWeight.w600)),textDirection:TextDirection.ltr,maxLines:1,ellipsis:'…')..layout(maxWidth:180);tp.paint(canvas,offset);}
