// aprs-legal-assistant/frontend/flutter_app/lib/widgets/hotspot_info_card.dart
import 'package:flutter/material.dart';
import '../models/courtroom_hotspots.dart';

/// Displays detailed information about a selected hotspot
class HotspotInfoCard extends StatelessWidget {
  final CourtroomHotspot hotspot;
  final VoidCallback onClose;

  const HotspotInfoCard({
    Key? key,
    required this.hotspot,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.8),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(hotspot.icon, color: hotspot.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hotspot.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Text(
              hotspot.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (hotspot.additionalInfo != null && hotspot.additionalInfo!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hotspot.additionalInfo!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
