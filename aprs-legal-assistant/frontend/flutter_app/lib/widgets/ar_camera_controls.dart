import 'package:flutter/material.dart';

/// Camera control mode for the AR viewer
enum ARCameraMode {
  orbit,
  firstPerson,
  topDown,
  frontView,
  sideView
}

/// Widget that provides camera control buttons for the AR viewer
class ARCameraControls extends StatelessWidget {
  final ARCameraMode currentMode;
  final Function(ARCameraMode) onModeChanged;
  final VoidCallback onReset;
  final double scale;
  
  const ARCameraControls({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    required this.onReset,
    this.scale = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCameraButton(
            ARCameraMode.orbit,
            Icons.threed_rotation,
            'Orbit View',
          ),
          _buildCameraButton(
            ARCameraMode.firstPerson,
            Icons.person,
            'First Person',
          ),
          _buildCameraButton(
            ARCameraMode.topDown,
            Icons.arrow_downward,
            'Top Down',
          ),
          _buildCameraButton(
            ARCameraMode.frontView,
            Icons.view_agenda,
            'Front View',
          ),
          _buildCameraButton(
            ARCameraMode.sideView,
            Icons.view_sidebar,
            'Side View',
          ),
          const Divider(color: Colors.white30, height: 16),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white),
            tooltip: 'Reset Camera',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraButton(ARCameraMode mode, IconData icon, String tooltip) {
    final isSelected = currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onModeChanged(mode),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24 * scale,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget that provides AR viewing mode options
class ARViewingModes extends StatelessWidget {
  final bool arEnabled;
  final bool autoRotateEnabled;
  final Function(bool) onARToggled;
  final Function(bool) onAutoRotateToggled;
  
  const ARViewingModes({
    Key? key,
    required this.arEnabled,
    required this.autoRotateEnabled,
    required this.onARToggled,
    required this.onAutoRotateToggled,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            'AR Mode',
            Icons.view_in_ar,
            arEnabled,
            onARToggled,
          ),
          const SizedBox(height: 8),
          _buildToggleButton(
            'Auto Rotate',
            Icons.sync,
            autoRotateEnabled,
            onAutoRotateToggled,
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleButton(
    String label,
    IconData icon,
    bool isEnabled,
    Function(bool) onToggled,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Switch(
          value: isEnabled,
          onChanged: onToggled,
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue.withOpacity(0.5),
        ),
        Icon(
          icon,
          color: isEnabled ? Colors.blue : Colors.white54,
          size: 20,
        ),
      ],
    );
  }
}
