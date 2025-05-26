import 'package:flutter/material.dart';

/// Represents an interactive hotspot in the 3D courtroom model
class CourtroomHotspot {
  final String id;
  final String name;
  final String description;
  final String position;
  final String normal;
  final IconData icon;
  final Color color;
  
  const CourtroomHotspot({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.normal,
    required this.icon,
    this.color = Colors.blue,
  });
}

/// Predefined hotspots for the courtroom model
final List<CourtroomHotspot> courtroomHotspots = [
  CourtroomHotspot(
    id: 'judge-bench',
    name: 'Judge\'s Bench',
    description: 'The elevated platform where the judge presides over court proceedings. The judge maintains order, makes rulings on objections, and ensures proper legal procedure.',
    position: '0m 2m -3m',
    normal: '0m 0m 1m',
    icon: Icons.gavel,
    color: Colors.purple,
  ),
  CourtroomHotspot(
    id: 'witness-stand',
    name: 'Witness Stand',
    description: 'Where witnesses testify under oath. Witnesses are questioned by attorneys from both sides through direct and cross-examination.',
    position: '-2m 1.5m -2m',
    normal: '0.5m 0m 0.5m',
    icon: Icons.record_voice_over,
    color: Colors.orange,
  ),
  CourtroomHotspot(
    id: 'jury-box',
    name: 'Jury Box',
    description: 'Seating area for jurors who listen to evidence and determine the verdict. In Indian courts, jury trials are rare, but this feature is included for educational purposes.',
    position: '-3m 1.5m 0m',
    normal: '1m 0m 0m',
    icon: Icons.people,
    color: Colors.teal,
  ),
  CourtroomHotspot(
    id: 'prosecution-table',
    name: 'Prosecution Table',
    description: 'Where the prosecutor sits and organizes case materials. The prosecutor represents the government and presents evidence against the defendant.',
    position: '2m 1m 0m',
    normal: '-0.5m 0m 0.5m',
    icon: Icons.person,
    color: Colors.red,
  ),
  CourtroomHotspot(
    id: 'defense-table',
    name: 'Defense Table',
    description: 'Where the defendant and defense attorney sit. The defense attorney advocates for the defendant and challenges the prosecution\'s evidence.',
    position: '2m 1m 2m',
    normal: '-0.5m 0m -0.5m',
    icon: Icons.people,
    color: Colors.blue,
  ),
  CourtroomHotspot(
    id: 'gallery',
    name: 'Gallery',
    description: 'Public seating area where spectators, media, and interested parties can observe court proceedings.',
    position: '0m 1m 5m',
    normal: '0m 0m -1m',
    icon: Icons.weekend,
    color: Colors.green,
  ),
  CourtroomHotspot(
    id: 'evidence-table',
    name: 'Evidence Table',
    description: 'Where physical evidence is displayed for the court. Evidence must be properly authenticated before being admitted.',
    position: '-1m 1m -1m',
    normal: '0m 1m 0m',
    icon: Icons.inventory_2,
    color: Colors.amber,
  ),
];

/// Widget that displays information about a selected hotspot
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
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: hotspot.color.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: hotspot.color.withOpacity(0.2),
                  child: Icon(hotspot.icon, color: hotspot.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hotspot.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                hotspot.description,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
