import 'package:flutter/material.dart';
import '../models/courtroom_hotspots.dart';

/// Widget that displays interactive annotations for the 3D model
class ARAnnotations extends StatelessWidget {
  final List<CourtroomHotspot> hotspots;
  final CourtroomHotspot? selectedHotspot;
  final Function(CourtroomHotspot) onHotspotSelected;
  
  const ARAnnotations({
    Key? key,
    required this.hotspots,
    this.selectedHotspot,
    required this.onHotspotSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Interactive Courtroom Guide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3.0,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hotspots.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final hotspot = hotspots[index];
              final isSelected = selectedHotspot?.id == hotspot.id;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => onHotspotSelected(hotspot),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? hotspot.color.withOpacity(0.8) 
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? hotspot.color 
                            : Colors.white.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hotspot.icon,
                          color: isSelected ? Colors.white : hotspot.color,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hotspot.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget that displays a floating annotation marker on the 3D model
class ARAnnotationMarker extends StatefulWidget {
  final CourtroomHotspot hotspot;
  final bool isSelected;
  final VoidCallback onTap;
  
  const ARAnnotationMarker({
    Key? key,
    required this.hotspot,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);
  
  @override
  _ARAnnotationMarkerState createState() => _ARAnnotationMarkerState();
}

class _ARAnnotationMarkerState extends State<ARAnnotationMarker> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: widget.isSelected 
                ? 1.0 
                : _opacityAnimation.value,
            child: Transform.scale(
              scale: widget.isSelected 
                  ? 1.3 
                  : _scaleAnimation.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.hotspot.color.withOpacity(0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.hotspot.color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.hotspot.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
