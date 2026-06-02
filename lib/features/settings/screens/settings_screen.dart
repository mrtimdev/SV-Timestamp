import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../core/utils/app_strings.dart';
import '../../camera/providers/camera_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final s = provider.settings;
    final strings = AppStrings(s.language);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(strings.text('Language', 'ភាសា'), Icons.language_rounded),
          _Card(
            children: [
              SegmentedButton<AppLanguage>(
                segments: const [
                  ButtonSegment(value: AppLanguage.khmer, label: Text('ខ្មែរ')),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text('English'),
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
          _Header(
            strings.text('Timestamp settings', 'ការកំណត់ត្រាពេលវេលា'),
            Icons.schedule_rounded,
          ),
          _Card(
            children: [
              _toggle(
                strings.text('Show date', 'បង្ហាញកាលបរិច្ឆេទ'),
                s.showDate,
                (v) => provider.update(s.copyWith(showDate: v)),
              ),
              _toggle(
                strings.text('Show time', 'បង្ហាញម៉ោង'),
                s.showTime,
                (v) => provider.update(s.copyWith(showTime: v)),
              ),
              _toggle(
                strings.text('Show GPS coordinates', 'បង្ហាញកូអរដោនេ GPS'),
                s.showGps,
                (v) => provider.update(s.copyWith(showGps: v)),
              ),
              _toggle(
                strings.text('Show address', 'បង្ហាញអាសយដ្ឋាន'),
                s.showAddress,
                (v) => provider.update(s.copyWith(showAddress: v)),
              ),
              _toggle(
                strings.text('Show device name', 'បង្ហាញឈ្មោះឧបករណ៍'),
                s.showDevice,
                (v) => provider.update(s.copyWith(showDevice: v)),
              ),
              _toggle(
                strings.text('Show custom note', 'បង្ហាញកំណត់ចំណាំ'),
                s.showNote,
                (v) => provider.update(s.copyWith(showNote: v)),
              ),
            ],
          ),
          if (s.showAddress) ...[
            _Header(
              strings.text('Address details', 'ព័ត៌មានលម្អិតអាសយដ្ឋាន'),
              Icons.location_on_outlined,
            ),
            _Card(
              children: [
                Text(
                  strings.text(
                    'Choose which reverse-geocoded address parts appear on photos.',
                    'ជ្រើសរើសព័ត៌មានអាសយដ្ឋានដែលត្រូវបង្ហាញលើរូបថត។',
                  ),
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _toggle(
                  strings.text('Street', 'ផ្លូវ'),
                  s.showStreet,
                  (v) => provider.update(s.copyWith(showStreet: v)),
                ),
                _toggle(
                  strings.text('Province', 'ខេត្ត'),
                  s.showProvince,
                  (v) => provider.update(s.copyWith(showProvince: v)),
                ),
                _toggle(
                  strings.text('Commune', 'ឃុំ/សង្កាត់'),
                  s.showCommune,
                  (v) => provider.update(s.copyWith(showCommune: v)),
                ),
                _toggle(
                  strings.text('District', 'ស្រុក/ខណ្ឌ'),
                  s.showDistrict,
                  (v) => provider.update(s.copyWith(showDistrict: v)),
                ),
                _toggle(
                  strings.text('Village', 'ភូមិ'),
                  s.showVillage,
                  (v) => provider.update(s.copyWith(showVillage: v)),
                ),
                _toggle(
                  strings.text('City', 'ក្រុង'),
                  s.showCity,
                  (v) => provider.update(s.copyWith(showCity: v)),
                ),
                _toggle(
                  strings.text('Country', 'ប្រទេស'),
                  s.showCountry,
                  (v) => provider.update(s.copyWith(showCountry: v)),
                ),
              ],
            ),
          ],
          _Header(strings.text('Appearance', 'រូបរាង'), Icons.palette_outlined),
          _Card(
            children: [
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (value) =>
                    provider.update(s.copyWith(themeMode: value.first)),
              ),
            ],
          ),
          _Header(
            strings.text('Watermark', 'សញ្ញាសម្គាល់'),
            Icons.verified_outlined,
          ),
          _Card(
            children: [
              _field(
                'Company name',
                s.companyName,
                (v) => provider.update(s.copyWith(companyName: v)),
              ),
              _field(
                'Custom note',
                s.customNote,
                (v) => provider.update(s.copyWith(customNote: v)),
              ),
              _field(
                'Custom text',
                s.watermarkText,
                (v) => provider.update(s.copyWith(watermarkText: v)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: s.logoPath != null && File(s.logoPath!).existsSync()
                      ? Image.file(
                          File(s.logoPath!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/sv_timestamp_logo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                ),
                title: Text(strings.text('Company logo', 'ឡូហ្គោក្រុមហ៊ុន')),
                subtitle: Text(
                  s.logoPath == null
                      ? 'Default SV Timestamp logo'
                      : 'Custom logo',
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: provider.pickLogo,
              ),
              _toggle(
                strings.text('Show company logo', 'បង្ហាញឡូហ្គោក្រុមហ៊ុន'),
                s.showLogo,
                (v) => provider.update(s.copyWith(showLogo: v)),
              ),
              if (s.showLogo)
                _slider(
                  strings.text('Logo size', 'ទំហំឡូហ្គោ'),
                  s.logoSize,
                  32,
                  140,
                  (v) => provider.update(s.copyWith(logoSize: v)),
                ),
              if (s.showLogo)
                _slider(
                  strings.text('Logo radius', 'កាំជ្រុងឡូហ្គោ'),
                  s.logoRadius,
                  0,
                  36,
                  (v) => provider.update(s.copyWith(logoRadius: v)),
                ),
              if (s.logoPath != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: provider.useDefaultLogo,
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(
                      strings.text('Restore default logo', 'ប្រើឡូហ្គោដើម'),
                    ),
                  ),
                ),
            ],
          ),
          const _Header('Timestamp position', Icons.open_with_rounded),
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
                        onSelected: (_) =>
                            provider.update(s.copyWith(position: position)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const _Header('Timestamp style', Icons.tune_rounded),
          _Card(
            children: [
              _slider(
                'Font size',
                s.fontSize,
                10,
                20,
                (v) => provider.update(s.copyWith(fontSize: v)),
              ),
              _slider(
                'Background opacity',
                s.backgroundOpacity,
                .3,
                .9,
                (v) => provider.update(s.copyWith(backgroundOpacity: v)),
              ),
              _slider(
                'Border radius',
                s.borderRadius,
                0,
                30,
                (v) => provider.update(s.copyWith(borderRadius: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _toggle(String label, bool value, ValueChanged<bool> changed) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: changed,
      );
  static Widget _field(
    String label,
    String value,
    ValueChanged<String> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: changed,
    ),
  );
  static Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> changed,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$label  ${value.toStringAsFixed(1)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      Slider(value: value, min: min, max: max, onChanged: changed),
    ],
  );
  static String _positionName(OverlayPosition p) => p.name
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .replaceFirstMapped(RegExp('^.'), (m) => m.group(0)!.toUpperCase());
}

class _Header extends StatelessWidget {
  const _Header(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
