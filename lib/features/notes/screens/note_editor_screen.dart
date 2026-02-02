import 'package:flutter/material.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteRepository _repository = NoteRepository();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Don't save empty notes
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    final now = DateTime.now();

    if (widget.note != null) {
      // Update existing note
      final updated = widget.note!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        updatedAt: now,
      );
      await _repository.update(updated);
    } else {
      // Create new note
      final note = Note(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.insert(note);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    if (widget.note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Note',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This note will be permanently deleted.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.delete(widget.note!.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      await _save();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) Navigator.pop(context, true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF2F2F7),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (_hasChanges) await _save();
                        if (context.mounted) Navigator.pop(context, _hasChanges);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.note != null)
                      GestureDetector(
                        onTap: _delete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 24,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Editor
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Title
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            hintStyle: TextStyle(
                              color: Color(0xFFD1D1D6),
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                        ),
                        const SizedBox(height: 16),
                        // Content
                        TextField(
                          controller: _contentController,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF3A3A3C),
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Start writing...',
                            hintStyle: TextStyle(
                              color: Color(0xFFD1D1D6),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
