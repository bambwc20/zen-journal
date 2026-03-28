import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_boilerplate/core/ads/ad_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/ad_placements.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/journal_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/mood_record.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/use_cases/save_journal_entry.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/journal_providers.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/providers/premium_provider.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/widgets/mood_selector.dart';
import 'package:flutter_boilerplate/features/zen_journal/presentation/theme/zen_journal_theme.dart';
import 'package:flutter_boilerplate/features/zen_journal/data/repositories/tag_repository.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/tag.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Journal editor screen with flutter_quill rich text editor,
/// photo attachments, mood/tag selection, and auto-save.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({
    super.key,
    this.entryId,
    this.initialMood,
    this.initialPrompt,
  });

  final int? entryId;
  final int? initialMood;
  final String? initialPrompt;

  @override
  ConsumerState<JournalEditorScreen> createState() =>
      _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  int _moodLevel = 3;
  List<String> _photos = [];
  List<int> _selectedTagIds = [];
  int? _entryId;
  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _moodLevel = widget.initialMood ?? 3;
    _quillController = QuillController.basic();
    _initEditor();
    _initSpeech();
    // Preload interstitial ad for showing after save
    InterstitialAdManager.preload();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initEditor() async {
    if (widget.entryId != null) {
      // Load existing entry
      await _loadEntry(widget.entryId!);
    } else if (widget.initialPrompt != null) {
      // Pre-populate with prompt text
      final doc = Document()..insert(0, '${widget.initialPrompt}\n\n');
      _quillController = QuillController(
        document: doc,
        selection: TextSelection.collapsed(
          offset: widget.initialPrompt!.length + 2,
        ),
      );
    }

    // Set up auto-save listener
    _quillController.document.changes.listen((_) {
      _triggerAutoSave();
    });

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadEntry(int id) async {
    final repo = ref.read(journalRepositoryProvider);
    final entry = await repo.getEntry(id);
    if (entry != null && mounted) {
      setState(() {
        _entryId = entry.id;
        _moodLevel = entry.moodLevel;
        _photos = List.from(entry.photos);
      });

      // Load rich text content from Delta JSON
      try {
        final json = jsonDecode(entry.content);
        if (json is List) {
          final doc = Document.fromJson(json);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (_) {
        // Fallback: treat content as plain text
        if (entry.content.isNotEmpty) {
          final doc = Document()..insert(0, entry.content);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }

      // Load tags for entry
      if (_entryId != null) {
        final tagRepo = ref.read(tagRepositoryProvider);
        final tags = await tagRepo.getTagsForEntry(_entryId!);
        if (mounted) {
          setState(() {
            _selectedTagIds = tags.where((t) => t.id != null).map((t) => t.id!).toList();
          });
        }
      }
    }
  }

  void _triggerAutoSave() {
    final saveUseCase = ref.read(saveJournalEntryProvider);
    final plainText = _quillController.document.toPlainText().trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final now = DateTime.now();

    final entry = JournalEntry(
      id: _entryId,
      content: content,
      plainText: plainText,
      moodLevel: _moodLevel,
      photos: _photos,
      createdAt: _entryId == null ? now : now, // Will be set properly on first save
      updatedAt: now,
      wordCount: plainText.trim().isEmpty
          ? 0
          : plainText.trim().split(RegExp(r'\s+')).length,
    );

    final mood = MoodRecord(
      level: _moodLevel,
      tags: [],
      date: now,
      entryId: _entryId,
    );

    saveUseCase.autoSave(
      entry,
      mood: mood,
      onSaved: (id) {
        if (mounted && _entryId == null) {
          setState(() => _entryId = id);
        }
      },
    );
  }

  Future<void> _saveNow() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final saveUseCase = ref.read(saveJournalEntryProvider);
      final plainText = _quillController.document.toPlainText().trim();
      final content = jsonEncode(_quillController.document.toDelta().toJson());
      final now = DateTime.now();

      // Check free user limits
      final isPremiumUser = ref.read(isPremiumProvider);
      if (!isPremiumUser) {
        // Check character limit
        final limitError = saveUseCase.validateFreeUserLimit(plainText);
        if (limitError != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(limitError),
              action: SnackBarAction(
                label: 'Upgrade',
                onPressed: () => context.push('/paywall'),
              ),
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        // Check daily entry limit (only for new entries)
        if (_entryId == null) {
          final dailyLimitError = await saveUseCase.validateDailyEntryLimit();
          if (dailyLimitError != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(dailyLimitError),
                action: SnackBarAction(
                  label: 'Upgrade',
                  onPressed: () => context.push('/paywall'),
                ),
              ),
            );
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final entry = JournalEntry(
        id: _entryId,
        content: content,
        plainText: plainText,
        moodLevel: _moodLevel,
        photos: _photos,
        createdAt: now,
        updatedAt: now,
      );

      final mood = MoodRecord(
        level: _moodLevel,
        tags: [],
        date: now,
        entryId: _entryId,
      );

      final id = await saveUseCase.saveNow(entry, mood: mood);

      if (_entryId == null) {
        _entryId = id;
      }

      // Save tags
      if (_selectedTagIds.isNotEmpty && _entryId != null) {
        final tagRepo = ref.read(tagRepositoryProvider);
        await tagRepo.setTagsForEntry(_entryId!, _selectedTagIds);
      }

      // Invalidate providers to refresh data
      ref.invalidate(journalEntriesStreamProvider);
      ref.invalidate(allJournalEntriesProvider);

      // Show interstitial ad every 3rd save (free users only)
      InterstitialAdManager.onJournalSaved(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos per entry')),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      setState(() {
        _photos.add(image.path);
      });
      _triggerAutoSave();
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            // Insert recognized text at current cursor position
            final doc = _quillController.document;
            final offset = _quillController.selection.baseOffset;
            final text = result.recognizedWords;
            doc.insert(offset, text);
            _quillController.updateSelection(
              TextSelection.collapsed(offset: offset + text.length),
              ChangeSource.local,
            );
            _triggerAutoSave();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    }
  }

  Future<void> _showTagSelector() async {
    final tagRepo = ref.read(tagRepositoryProvider);
    await tagRepo.seedDefaultTags();
    final allTags = await tagRepo.getAllTags();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Tags',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(tag.name),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected && tag.id != null) {
                              _selectedTagIds.add(tag.id!);
                            } else if (tag.id != null) {
                              _selectedTagIds.remove(tag.id!);
                            }
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    final saveUseCase = ref.read(saveJournalEntryProvider);
    saveUseCase.cancelAutoSave();
    _speech.stop();
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showAds = ref.watch(showAdsProvider);
    final isPremiumUser = ref.watch(isPremiumProvider);
    final plainText = _isInitialized
        ? _quillController.document.toPlainText().trim()
        : '';
    final wordCount = plainText.isEmpty
        ? 0
        : plainText.split(RegExp(r'\s+')).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId != null ? 'Edit Entry' : 'New Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveNow().then((_) {
              if (mounted) context.pop();
            });
          },
        ),
        actions: [
          if (_entryId != null)
            IconButton(
              icon: const Icon(Icons.insights_rounded),
              tooltip: 'AI Reflection',
              onPressed: () => context.push('/reflection/$_entryId'),
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveNow,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          // Mood selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MoodSelector(
              selectedLevel: _moodLevel,
              onMoodSelected: (level) {
                setState(() => _moodLevel = level);
                _triggerAutoSave();
              },
              size: MoodSelectorSize.small,
            ),
          ),

          const Divider(height: 1),

          // Toolbar
          if (_isInitialized)
            QuillSimpleToolbar(
              controller: _quillController,
              config: QuillSimpleToolbarConfig(
                showAlignmentButtons: false,
                showCodeBlock: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showSearchButton: false,
                showFontFamily: false,
                showFontSize: false,
                showStrikeThrough: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showHeaderStyle: false,
                showDividers: false,
                multiRowsDisplay: false,
              ),
            ),

          const Divider(height: 1),

          // Editor
          Expanded(
            child: _isInitialized
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuillEditor.basic(
                      controller: _quillController,
                      config: QuillEditorConfig(
                        placeholder: 'Start writing your thoughts...',
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        scrollable: true,
                        autoFocus: widget.entryId == null,
                        expands: true,
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          // Photo previews
          if (_photos.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 72,
                            height: 72,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _photos.removeAt(index));
                              _triggerAutoSave();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: colorScheme.onError,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Bottom bar with actions and word count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: _pickImage,
                  tooltip: 'Add photo',
                ),
                IconButton(
                  icon: const Icon(Icons.tag),
                  onPressed: _showTagSelector,
                  tooltip: 'Add tags',
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_outlined,
                    color: _isListening ? colorScheme.error : null,
                  ),
                  onPressed: _speechAvailable ? _toggleListening : null,
                  tooltip: _isListening ? 'Stop dictation' : 'Voice input',
                ),
                if (_selectedTagIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '${_selectedTagIds.length} tags',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                if (!isPremiumUser)
                  Text(
                    '${plainText.length}/500',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: plainText.length > 500
                          ? colorScheme.error
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '$wordCount words',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
