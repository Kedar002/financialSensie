import 'package:flutter/material.dart';
import '../../../core/models/needs_template.dart';
import '../../../core/repositories/needs_template_repository.dart';

class TemplateEditSheet extends StatefulWidget {
  final NeedsTemplate? template;
  final VoidCallback? onSaved;

  const TemplateEditSheet({
    super.key,
    this.template,
    this.onSaved,
  });

  @override
  State<TemplateEditSheet> createState() => _TemplateEditSheetState();
}

class _TemplateEditSheetState extends State<TemplateEditSheet> {
  final NeedsTemplateRepository _repository = NeedsTemplateRepository();
  late TextEditingController _nameController;
  late List<_ItemController> _items;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.template != null;
    _nameController = TextEditingController(text: widget.template?.name ?? '');

    if (widget.template != null && widget.template!.items.isNotEmpty) {
      _items = widget.template!.items.map((item) => _ItemController(
        id: item.id,
        nameController: TextEditingController(text: item.name),
        amountController: TextEditingController(text: item.amount.toString()),
      )).toList();
    } else {
      _items = [
        _ItemController(
          nameController: TextEditingController(),
          amountController: TextEditingController(),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemController(
        nameController: TextEditingController(),
        amountController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        // Update template
        final updated = widget.template!.copyWith(name: name);
        await _repository.update(updated);

        // Replace all items
        final items = _items
            .where((item) => item.nameController.text.trim().isNotEmpty)
            .map((item) => NeedsTemplateItem(
                  templateId: widget.template!.id!,
                  name: item.nameController.text.trim(),
                  amount: int.tryParse(item.amountController.text) ?? 0,
                ))
            .toList();
        await _repository.replaceItems(widget.template!.id!, items);
      } else {
        // Create new template
        final template = NeedsTemplate(name: name);
        final templateId = await _repository.insert(template);

        // Add items
        final items = _items
            .where((item) => item.nameController.text.trim().isNotEmpty)
            .map((item) => NeedsTemplateItem(
                  templateId: templateId,
                  name: item.nameController.text.trim(),
                  amount: int.tryParse(item.amountController.text) ?? 0,
                ))
            .toList();

        if (items.isNotEmpty) {
          await _repository.insertItems(templateId, items);
        }
      }

      widget.onSaved?.call();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Template updated' : 'Template created'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.template == null) return;

    await _repository.delete(widget.template!.id!);
    widget.onSaved?.call();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template deleted'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _isEditing ? 'Edit Template' : 'Create Template',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Template name',
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
                const SizedBox(height: 24),

                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: item.nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: 'Name',
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: item.amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              prefixText: '₹ ',
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
                        ),
                        if (_items.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeItem(index),
                            child: const Icon(
                              Icons.remove_circle_outline,
                              color: Color(0xFFFF3B30),
                              size: 24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _addItem,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: Color(0xFF007AFF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isSaving ? Colors.grey : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isSaving
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _delete,
                      child: const Text(
                        'Delete Template',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemController {
  final int? id;
  final TextEditingController nameController;
  final TextEditingController amountController;

  _ItemController({
    this.id,
    required this.nameController,
    required this.amountController,
  });

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}
