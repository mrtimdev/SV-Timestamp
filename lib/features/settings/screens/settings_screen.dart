import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants/app_colors.dart';
import '../../../models/app_settings.dart';
import '../../../core/utils/app_strings.dart';
import '../../camera/providers/camera_provider.dart';
import '../../camera/widgets/timestamp_overlay.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final s = provider.settings;
    final camera = context.watch<CameraProvider>();
    final strings = AppStrings(s.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.text('Settings', 'ការកំណត់'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Live Watermark Interactive Preview Banner ───────────────────────
          _Header(
            strings.text('Live Preview', 'ការមើលផ្ទាល់'),
            Icons.preview_rounded,
            color: AppColors.cyanAccent,
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.text(
                        'Real-time watermark preview',
                        'ការមើលគំរូត្រាផ្ទាល់',
                      ),
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TimestampOverlay(
                    settings: s,
                    location: camera.location,
                    device: camera.device,
                    maxWidth: 320,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Language ────────────────────────────────────────────────────────
          _Header(strings.text('Language', 'ភាសា'), Icons.translate_rounded),
          _Card(
            children: [
              SegmentedButton<AppLanguage>(
                segments: const [
                  ButtonSegment(
                    value: AppLanguage.khmer,
                    label: Text('ខ្មែរ 🇰🇭'),
                  ),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text('English 🇺🇸'),
                  ),
                ],
                selected: {s.language},
                onSelectionChanged: (value) async {
                  await provider.update(s.copyWith(language: value.first));
                  if (context.mounted) {
                    await context.read<CameraProvider>().refreshLocation();
                  }
                },
              ),
            ],
          ),

          // ── Watermark Template & Theme ──────────────────────────────────────
          _Header(
            strings.text('Theme & Template', 'រូបរាង & គំរូ'),
            Icons.style_rounded,
          ),
          _Card(
            children: [
              DropdownButtonFormField<WatermarkTemplate>(
                key: ValueKey(s.template),
                isExpanded: true,
                initialValue: s.template,
                decoration: InputDecoration(
                  labelText: strings.text('Watermark Template', 'គំរូត្រា'),
                  prefixIcon: const Icon(
                    Icons.dashboard_customize_rounded,
                    size: 20,
                  ),
                ),
                items: WatermarkTemplate.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_templateName(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.update(s.withTemplate(value));
                  }
                },
              ),
              const SizedBox(height: 14),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(strings.text('System', 'ស្វ័យប្រវត្តិ')),
                    icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(strings.text('Light', 'ពន្លឺ')),
                    icon: const Icon(Icons.light_mode_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(strings.text('Dark', 'ងងឹត')),
                    icon: const Icon(Icons.dark_mode_rounded, size: 16),
                  ),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (value) =>
                    provider.update(s.copyWith(themeMode: value.first)),
              ),
            ],
          ),

          // ── Timestamp Field Toggles ─────────────────────────────────────────
          _Header(
            strings.text('Timestamp Elements', 'ព័ត៌មានត្រាពេលវេលា'),
            Icons.tune_rounded,
          ),
          _Card(
            children: [
              _toggleTile(
                icon: Icons.calendar_today_rounded,
                title: strings.text('Show Date', 'បង្ហាញកាលបរិច្ឆេទ'),
                value: s.showDate,
                onChanged: (v) => provider.update(s.copyWith(showDate: v)),
              ),
              _toggleTile(
                icon: Icons.access_time_rounded,
                title: strings.text('Show Time', 'បង្ហាញម៉ោង'),
                value: s.showTime,
                onChanged: (v) => provider.update(s.copyWith(showTime: v)),
              ),
              _toggleTile(
                icon: Icons.explore_rounded,
                title: strings.text(
                  'Show GPS Coordinates',
                  'បង្ហាញកូអរដោនេ GPS',
                ),
                value: s.showGps,
                onChanged: (v) => provider.update(s.copyWith(showGps: v)),
              ),
              _toggleTile(
                icon: Icons.gps_fixed_rounded,
                title: strings.text(
                  'Show GPS Accuracy',
                  'បង្ហាញភាពត្រឹមត្រូវ GPS',
                ),
                value: s.showGpsAccuracy,
                onChanged: (v) =>
                    provider.update(s.copyWith(showGpsAccuracy: v)),
              ),
              _toggleTile(
                icon: Icons.pin_drop_rounded,
                title: strings.text('Show Address', 'បង្ហាញអាសយដ្ឋាន'),
                value: s.showAddress,
                onChanged: (v) => provider.update(s.copyWith(showAddress: v)),
              ),
              _toggleTile(
                icon: Icons.smartphone_rounded,
                title: strings.text('Show Device Name', 'បង្ហាញឈ្មោះឧបករណ៍'),
                value: s.showDevice,
                onChanged: (v) => provider.update(s.copyWith(showDevice: v)),
              ),
              _toggleTile(
                icon: Icons.edit_note_rounded,
                title: strings.text('Show Custom Note', 'បង្ហាញកំណត់ចំណាំ'),
                value: s.showNote,
                onChanged: (v) => provider.update(s.copyWith(showNote: v)),
              ),
            ],
          ),

          // ── Address Breakdown Details ───────────────────────────────────────
          if (s.showAddress) ...[
            _Header(
              strings.text('Address Breakdown', 'ព័ត៌មានលម្អិតអាសយដ្ឋាន'),
              Icons.location_city_rounded,
            ),
            _Card(
              children: [
                Text(
                  strings.text(
                    'Customize which reverse-geocoded address segments appear.',
                    'ជ្រើសរើសព័ត៌មានអាសយដ្ឋានដែលត្រូវបង្ហាញលើរូបថត។',
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                _toggleTile(
                  icon: Icons.signpost_rounded,
                  title: strings.text('Street', 'ផ្លូវ'),
                  value: s.showStreet,
                  onChanged: (v) => provider.update(s.copyWith(showStreet: v)),
                ),
                _toggleTile(
                  icon: Icons.map_rounded,
                  title: strings.text('Province / State', 'ខេត្ត'),
                  value: s.showProvince,
                  onChanged: (v) =>
                      provider.update(s.copyWith(showProvince: v)),
                ),
                _toggleTile(
                  icon: Icons.location_on_outlined,
                  title: strings.text('Commune', 'ឃុំ/សង្កាត់'),
                  value: s.showCommune,
                  onChanged: (v) => provider.update(s.copyWith(showCommune: v)),
                ),
                _toggleTile(
                  icon: Icons.holiday_village_rounded,
                  title: strings.text('District', 'ស្រុក/ខណ្ឌ'),
                  value: s.showDistrict,
                  onChanged: (v) =>
                      provider.update(s.copyWith(showDistrict: v)),
                ),
                _toggleTile(
                  icon: Icons.home_work_rounded,
                  title: strings.text('Village', 'ភូមិ'),
                  value: s.showVillage,
                  onChanged: (v) => provider.update(s.copyWith(showVillage: v)),
                ),
                _toggleTile(
                  icon: Icons.apartment_rounded,
                  title: strings.text('City', 'ក្រុង'),
                  value: s.showCity,
                  onChanged: (v) => provider.update(s.copyWith(showCity: v)),
                ),
                _toggleTile(
                  icon: Icons.public_rounded,
                  title: strings.text('Country', 'ប្រទេស'),
                  value: s.showCountry,
                  onChanged: (v) => provider.update(s.copyWith(showCountry: v)),
                ),
              ],
            ),
          ],

          // ── Brand & Watermark Customization ─────────────────────────────────
          _Header(
            strings.text('Brand & Watermark', 'ម៉ាកយីហោ & សញ្ញាសម្គាល់'),
            Icons.verified_rounded,
          ),
          _Card(
            children: [
              _field(
                label: strings.text('Company Name', 'ឈ្មោះក្រុមហ៊ុន'),
                icon: Icons.business_rounded,
                value: s.companyName,
                onChanged: (v) => provider.update(s.copyWith(companyName: v)),
              ),
              _field(
                label: strings.text('Custom Note', 'កំណត់ចំណាំផ្ទាល់ខ្លួន'),
                icon: Icons.notes_rounded,
                value: s.customNote,
                onChanged: provider.updateNote,
              ),
              _field(
                label: strings.text(
                  'Watermark Footer Text',
                  'អត្ថបទសញ្ញាសម្គាល់',
                ),
                icon: Icons.short_text_rounded,
                value: s.watermarkText,
                onChanged: (v) => provider.update(s.copyWith(watermarkText: v)),
              ),
              const SizedBox(height: 8),

              // Logo Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          s.logoPath != null && File(s.logoPath!).existsSync()
                          ? Image.file(
                              File(s.logoPath!),
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/sv_app_icon.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.text('Company Logo', 'ឡូហ្គោក្រុមហ៊ុន'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            s.logoPath == null
                                ? strings.text(
                                    'Default SV Logo',
                                    'ឡូហ្គោ SV ដើម',
                                  )
                                : strings.text(
                                    'Custom uploaded logo',
                                    'ឡូហ្គោផ្ទាល់ខ្លួន',
                                  ),
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: provider.pickLogo,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(strings.text('Change', 'ប្តូរ')),
                    ),
                  ],
                ),
              ),
              if (s.logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: provider.useDefaultLogo,
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: Text(
                        strings.text('Restore default logo', 'ប្រើឡូហ្គោដើម'),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              _toggleTile(
                icon: Icons.image_rounded,
                title: strings.text('Show Company Logo', 'បង្ហាញឡូហ្គោ'),
                value: s.showLogo,
                onChanged: (v) => provider.update(s.copyWith(showLogo: v)),
              ),
              if (s.showLogo) ...[
                _modernSlider(
                  label: strings.text('Logo Size', 'ទំហំឡូហ្គោ'),
                  value: s.logoSize,
                  min: 32,
                  max: 140,
                  unit: 'px',
                  onChanged: (v) => provider.update(s.copyWith(logoSize: v)),
                ),
                _modernSlider(
                  label: strings.text('Logo Corner Radius', 'កាំជ្រុងឡូហ្គោ'),
                  value: s.logoRadius,
                  min: 0,
                  max: 36,
                  unit: 'px',
                  onChanged: (v) => provider.update(s.copyWith(logoRadius: v)),
                ),
              ],
            ],
          ),

          // ── Position & Layout ───────────────────────────────────────────────
          _Header(
            strings.text('Default Position', 'ទីតាំងលំនាំដើម'),
            Icons.open_with_rounded,
          ),
          _Card(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: OverlayPosition.values
                    .map(
                      (position) => ChoiceChip(
                        selected: s.position == position,
                        label: Text(_positionName(position)),
                        onSelected: (_) {
                          final normalized = switch (position) {
                            OverlayPosition.topLeft => (0.0, 0.0),
                            OverlayPosition.topRight => (1.0, 0.0),
                            OverlayPosition.bottomLeft => (0.0, 1.0),
                            OverlayPosition.bottomRight => (1.0, 1.0),
                            OverlayPosition.bottomCenter => (0.5, 1.0),
                          };
                          provider.update(
                            s.copyWith(
                              position: position,
                              normalizedX: normalized.$1,
                              normalizedY: normalized.$2,
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          // ── Fine-tuning & Visual Styling Sliders ───────────────────────────
          _Header(
            strings.text('Styling & Scale', 'ទំហំ & ភាពស្រអាប់'),
            Icons.brush_rounded,
          ),
          _Card(
            children: [
              _modernSlider(
                label: strings.text('Font Size', 'ទំហំពុម្ពអក្សរ'),
                value: s.fontSize,
                min: 10,
                max: 20,
                unit: 'pt',
                onChanged: (v) => provider.update(s.copyWith(fontSize: v)),
              ),
              _modernSlider(
                label: strings.text('Background Opacity', 'ភាពស្រអាប់ផ្ទៃ'),
                value: s.backgroundOpacity,
                min: 0.3,
                max: 0.95,
                unit: '',
                onChanged: (v) =>
                    provider.update(s.copyWith(backgroundOpacity: v)),
              ),
              _modernSlider(
                label: strings.text('Card Border Radius', 'កាំជ្រុងផ្ទាំងត្រា'),
                value: s.borderRadius,
                min: 0,
                max: 30,
                unit: 'px',
                onChanged: (v) => provider.update(s.copyWith(borderRadius: v)),
              ),
              _modernSlider(
                label: strings.text(
                  'Overall Watermark Scale',
                  'មាត្រដ្ឋានសរុប',
                ),
                value: s.watermarkScale,
                min: 0.65,
                max: 1.35,
                unit: 'x',
                onChanged: (v) =>
                    provider.update(s.copyWith(watermarkScale: v)),
              ),
              _modernSlider(
                label: strings.text('Row Spacing', 'គម្លាតរវាងជួរដេក'),
                value: s.watermarkRowSpacing,
                min: 0,
                max: 24,
                unit: 'px',
                onChanged: (v) =>
                    provider.update(s.copyWith(watermarkRowSpacing: v)),
              ),
              _modernSlider(
                label: strings.text('Photo Margin', 'គែមសុវត្ថិភាព'),
                value: s.watermarkMargin,
                min: 4,
                max: 28,
                unit: 'px',
                onChanged: (v) =>
                    provider.update(s.copyWith(watermarkMargin: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _toggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: value ? AppColors.primary : Colors.white60,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );

  static Widget _field({
    required String label,
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      onChanged: onChanged,
    ),
  );

  static Widget _modernSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit'.trim(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    ),
  );

  static String _positionName(OverlayPosition p) => p.name
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .replaceFirstMapped(RegExp('^.'), (m) => m.group(0)!.toUpperCase());

  static String _templateName(WatermarkTemplate value) => switch (value) {
    WatermarkTemplate.fieldReport => 'SV Field Report (default)',
    WatermarkTemplate.classic => 'Classic timestamp',
    WatermarkTemplate.gpsAddress => 'GPS and address',
    WatermarkTemplate.siteInspection => 'Site inspection',
    WatermarkTemplate.minimal => 'Minimal date and time',
    WatermarkTemplate.business => 'Business / company',
    WatermarkTemplate.custom => 'Custom template',
  };
}

class _Header extends StatelessWidget {
  const _Header(this.label, this.icon, {this.color});
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (color ?? Theme.of(context).colorScheme.primary).withValues(
              alpha: 0.14,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}
