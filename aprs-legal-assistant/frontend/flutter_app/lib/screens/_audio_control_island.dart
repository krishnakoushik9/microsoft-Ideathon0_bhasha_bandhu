import 'package:flutter/material.dart';

/// A floating island for controlling TTS settings (speed, pitch, volume)
/// Now works with browser TTS (SpeechSynthesis), updates settings for next utterance.
class AudioControlIsland extends StatefulWidget {
  final double ttsSpeed;
  final double ttsPitch;
  final double ttsVolume;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<double> onVolumeChanged;

  const AudioControlIsland({
    Key? key,
    required this.ttsSpeed,
    required this.ttsPitch,
    required this.ttsVolume,
    required this.onSpeedChanged,
    required this.onPitchChanged,
    required this.onVolumeChanged,
  }) : super(key: key);

  @override
  State<AudioControlIsland> createState() => _AudioControlIslandState();
}

class _AudioControlIslandState extends State<AudioControlIsland> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _hovered = !_hovered),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: _hovered ? 320 : 56,
          height: _hovered ? 180 : 56,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(_hovered ? 32 : 28),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: _hovered
              ? Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSlider(
                        label: 'Speed',
                        value: widget.ttsSpeed,
                        min: 0.3,
                        max: 1.2,
                        divisions: 9,
  
                        onChanged: widget.onSpeedChanged,
                        color: Colors.amber,
                      ),
                      _buildSlider(
                        label: 'Pitch',
                        value: widget.ttsPitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        onChanged: widget.onPitchChanged,
                        color: Colors.purpleAccent,
                      ),
                      _buildSlider(
                        label: 'Volume',
                        value: widget.ttsVolume,
                        min: 0.2,
                        max: 1.0,
                        divisions: 8,
                        onChanged: widget.onVolumeChanged,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Icon(Icons.graphic_eq, color: Colors.amber, size: 32),
                ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(width: 54, child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: color,
            label: value.toStringAsFixed(2),
          ),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
