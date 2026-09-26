import 'package:flutter/material.dart';

import '../../../core/utils/app_strings.dart';

class CameraNoteEditor extends StatefulWidget {
  const CameraNoteEditor({
    super.key,
    required this.note,
    required this.strings,
  });
  final String note;
  final AppStrings strings;
  @override
  State<CameraNoteEditor> createState() => _CameraNoteEditorState();
}

class _CameraNoteEditorState extends State<CameraNoteEditor> {
  late final _controller = TextEditingController(text: widget.note);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.strings.text('Edit custom note', 'កែសម្រួលកំណត់ចំណាំ'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('camera-note-field'),
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.strings.text(
                'Custom Note',
                'កំណត់ចំណាំផ្ទាល់ខ្លួន',
              ),
              hintText: widget.strings.text(
                'Add a note to your photo',
                'បន្ថែមកំណត់ចំណាំក្នុងរូបថត',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.strings.text('Cancel', 'បោះបង់')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('save-camera-note'),
                onPressed: () =>
                    Navigator.pop(context, _controller.text.trim()),
                child: Text(widget.strings.text('Save note', 'រក្សាទុកចំណាំ')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
