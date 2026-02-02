import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/person.dart';
import '../repositories/note_repository.dart';
import '../repositories/person_repository.dart';
import 'note_editor_screen.dart';
import 'person_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const NotesScreen({super.key, this.onMenuTap});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (widget.onMenuTap != null)
                    GestureDetector(
                      onTap: widget.onMenuTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.menu, size: 20, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Text(
                'Notes',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Notes',
                    isSelected: _currentTab == 0,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                  const SizedBox(width: 24),
                  _TabButton(
                    label: 'People',
                    isSelected: _currentTab == 1,
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _currentTab == 0
                  ? const _NotesTab()
                  : const _PeopleTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// Notes Tab
class _NotesTab extends StatefulWidget {
  const _NotesTab();

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final NoteRepository _repository = NoteRepository();
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _repository.getAll();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  void _openNote(Note? note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_outlined,
              size: 64,
              color: Color(0xFFD1D1D6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to create your first note',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _openNote(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Create Note',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return _NoteCard(
              note: note,
              onTap: () => _openNote(note),
            );
          },
        ),
        // FAB
        Positioned(
          right: 20,
          bottom: 24,
          child: GestureDetector(
            onTap: () => _openNote(null),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _formatDate(note.updatedAt),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFAEAEB2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// People Tab
class _PeopleTab extends StatefulWidget {
  const _PeopleTab();

  @override
  State<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<_PeopleTab> {
  final PersonRepository _repository = PersonRepository();
  List<Map<String, dynamic>> _peopleData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final data = await _repository.getAllWithBalances();
    setState(() {
      _peopleData = data;
      _isLoading = false;
    });
  }

  void _showAddPersonSheet() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Person',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: const TextStyle(color: Color(0xFFAEAEB2)),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      await _repository.getOrCreate(name);
                      if (context.mounted) Navigator.pop(context);
                      _loadPeople();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Add',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  void _openPerson(Person person, int balance, int totalCommerce) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          person: person,
          initialBalance: balance,
          initialTotalCommerce: totalCommerce,
        ),
      ),
    );
    if (result == true) {
      _loadPeople();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_peopleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFFD1D1D6),
            ),
            const SizedBox(height: 16),
            const Text(
              'No people yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track money with friends & family',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _showAddPersonSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Add Person',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: _peopleData.length,
          itemBuilder: (context, index) {
            final data = _peopleData[index];
            final person = data['person'] as Person;
            final balance = data['balance'] as int;
            final totalCommerce = data['totalCommerce'] as int;

            return _PersonCard(
              person: person,
              balance: balance,
              totalCommerce: totalCommerce,
              onTap: () => _openPerson(person, balance, totalCommerce),
            );
          },
        ),
        // FAB
        Positioned(
          right: 20,
          bottom: 24,
          child: GestureDetector(
            onTap: _showAddPersonSheet,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final int balance; // positive = they owe me
  final int totalCommerce;
  final VoidCallback onTap;

  const _PersonCard({
    required this.person,
    required this.balance,
    required this.totalCommerce,
    required this.onTap,
  });

  String _formatAmount(int paise) {
    final rupees = paise / 100;
    if (rupees == rupees.toInt()) {
      return rupees.toInt().toString();
    }
    return rupees.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = balance > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  person.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Name & commerce
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (totalCommerce > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Total: \u20B9${_formatAmount(totalCommerce)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFAEAEB2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Balance
            if (balance != 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\u20B9${_formatAmount(balance.abs())}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPositive ? 'owes you' : 'you owe',
                    style: TextStyle(
                      fontSize: 13,
                      color: isPositive
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF3B30),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Settled',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC7C7CC),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
