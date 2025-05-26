// aprs-legal-assistant/frontend/flutter_app/lib/widgets/ar_viewing_modes.dart
import 'package:flutter/material.dart';

/// Widget that provides AR and autorotate toggle controls
class ARViewingControls extends StatelessWidget {
  final bool arEnabled;
  final bool autoRotateEnabled;
  final Function(bool) onARToggled;
  final Function(bool) onAutoRotateToggled;

  const ARViewingControls({
    Key? key,
    required this.arEnabled,
    required this.autoRotateEnabled,
    required this.onARToggled,
    required this.onAutoRotateToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('View Options', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            const SizedBox(height: 8),
            _buildToggleRow(
              icon: Icons.view_in_ar,
              label: 'AR Mode',
              value: arEnabled,
              onChanged: onARToggled,
            ),
            const SizedBox(height: 4),
            _buildToggleRow(
              icon: Icons.rotate_right,
              label: 'Auto-Rotate',
              value: autoRotateEnabled,
              onChanged: onAutoRotateToggled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: Colors.lightBlueAccent,
        ),
      ],
    );
  }
}
