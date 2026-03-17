import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

enum WidgetStyle { bold, circular, minimal, ticker }

class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  bool _isPinSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    if (Platform.isAndroid) {
      try {
        final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
        setState(() {
          _isPinSupported = supported;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isPinSupported = false;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isPinSupported = false;
        _isLoading = false;
      });
    }
  }

  String _providerName(WidgetStyle style) {
    switch (style) {
      case WidgetStyle.bold:
        return 'BoldWidgetProvider';
      case WidgetStyle.circular:
        return 'CircularWidgetProvider';
      case WidgetStyle.minimal:
        return 'MinimalWidgetProvider';
      case WidgetStyle.ticker:
        return 'TickerWidgetProvider';
    }
  }

  Future<void> _addWidget(WidgetStyle style) async {
    if (!_isPinSupported) {
      _showManualInstructions();
      return;
    }

    final providerName = _providerName(style);
    try {
      await HomeWidget.requestPinWidget(
        androidName: providerName,
        qualifiedAndroidName: 'com.sun2.chessclock.$providerName',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Widget added to home screen!'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add widget: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showManualInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Add Widget Manually'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionStep(1, 'Long press on your home screen'),
            const SizedBox(height: 8),
            _buildInstructionStep(2, "Tap 'Widgets' or 'Widget drawer'"),
            const SizedBox(height: 8),
            _buildInstructionStep(3, 'Find Deadline Dash in the widget list'),
            const SizedBox(height: 8),
            _buildInstructionStep(4, 'Select and drag the widget to your home screen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Widget Gallery',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a widget style to add to your home screen',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildWidgetCard(
                    style: WidgetStyle.bold,
                    title: 'Bold',
                    description: 'Vibrant colored background with circular countdown',
                  ),
                  const SizedBox(height: 16),
                  _buildWidgetCard(
                    style: WidgetStyle.circular,
                    title: 'Circular',
                    description: 'Dark background with a large circular day counter',
                  ),
                  const SizedBox(height: 16),
                  _buildWidgetCard(
                    style: WidgetStyle.minimal,
                    title: 'Minimal',
                    description: 'Clean dark layout with prominent day count',
                  ),
                  const SizedBox(height: 16),
                  _buildWidgetCard(
                    style: WidgetStyle.ticker,
                    title: 'Ticker',
                    description: 'Dark background with a pill-style countdown display',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Widget not appearing?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "If the widget doesn't appear automatically, you can add it manually:",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionStep(1, 'Long press on your home screen'),
                        const SizedBox(height: 6),
                        _buildInstructionStep(2, "Tap 'Widgets' or 'Widget drawer'"),
                        const SizedBox(height: 6),
                        _buildInstructionStep(3, 'Find your app in the widget list'),
                        const SizedBox(height: 6),
                        _buildInstructionStep(4, 'Select and drag the widget to your home screen'),
                        const SizedBox(height: 12),
                        Text(
                          'Note: Different launchers may have slightly different steps',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!Platform.isAndroid)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'One-tap widget adding is only available on Android. On iOS, please add widgets through the widget gallery.',
                              style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildWidgetCard({
    required WidgetStyle style,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              width: double.infinity,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFFF0F0F5),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
              child: Center(child: _buildPreview(style)),
            ),
          ),
          // Info + button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          InkWell(
            onTap: () => _addWidget(style),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Widget',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(WidgetStyle style) {
    switch (style) {
      case WidgetStyle.bold:
        return _BoldWidgetPreview();
      case WidgetStyle.circular:
        return _CircularWidgetPreview();
      case WidgetStyle.minimal:
        return _MinimalWidgetPreview();
      case WidgetStyle.ticker:
        return _TickerWidgetPreview();
    }
  }
}

// ─── Style 1: Bold ───────────────────────────────────────────────────────────

class _BoldWidgetPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF2D78);
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Project Alpha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large circle
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '22',
                      style: TextStyle(
                        color: accent,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'days',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Pills column
              Column(
                children: [
                  _pill('4h'),
                  const SizedBox(height: 8),
                  _pill('21m'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFF2D78),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Style 2: Circular ───────────────────────────────────────────────────────

class _CircularWidgetPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1C1C2E);
    const accent = Color(0xFF9B7FF0);
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  '22',
                  style: TextStyle(
                    color: accent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Project Alpha',
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Style 3: Minimal ────────────────────────────────────────────────────────

class _MinimalWidgetPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF12172B);
    const accent = Color(0xFF4FC3F7);
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Project Alpha',
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                '22',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'days',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '4 hrs  21 mins',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Style 4: Ticker ─────────────────────────────────────────────────────────

class _TickerWidgetPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF12172B);
    const pillColor = Color(0xFF3A5A8A);
    const accent = Color(0xFF4FC3F7);
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Project Alpha',
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _TickerNumber('22'),
                    _TickerDot(),
                    _TickerNumber('04'),
                    _TickerDot(),
                    _TickerNumber('21'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _TickerLabel('days'),
                    SizedBox(width: 28),
                    _TickerLabel('hours'),
                    SizedBox(width: 24),
                    _TickerLabel('min'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerNumber extends StatelessWidget {
  final String value;
  const _TickerNumber(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}

class _TickerDot extends StatelessWidget {
  const _TickerDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text('.', style: TextStyle(color: Colors.white54, fontSize: 20, height: 0.8)),
          Text('.', style: TextStyle(color: Colors.white54, fontSize: 20, height: 0.8)),
        ],
      ),
    );
  }
}

class _TickerLabel extends StatelessWidget {
  final String text;
  const _TickerLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
      ),
    );
  }
}
