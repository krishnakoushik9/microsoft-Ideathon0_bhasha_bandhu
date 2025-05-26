import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ARCaseExplorerScreenImpl extends StatefulWidget {
  const ARCaseExplorerScreenMobile({Key? key}) : super(key: key);

  @override
  State<ARCaseExplorerScreenImpl> createState() => _ARCaseExplorerScreenImplState();
}

class _ARCaseExplorerScreenImplState extends State<ARCaseExplorerScreenImpl> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  @override
  void dispose() 
  {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Case Explorer'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              child: const Icon(Icons.gavel),
              tooltip: 'Place Court Model & Fetch AI content',
              onPressed: () async {
                // Place full AR courtroom environment
                await _addCourtModels();
                final aiText = await _fetchAIProceedings();
                _showAIOverlay(aiText);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: true,
      handleTaps: true,
    );
  }

  Future<void> _addCourtModels() async {
    await _addNode('assets/models/courtroom.glb', Vector3.zero(), Vector3(0.5, 0.5, 0.5));
    await _addNode('assets/models/judge_bench.glb', Vector3(0, 0, -1), Vector3(0.5, 0.5, 0.5));
    await _addNode('assets/models/witness_stand.glb', Vector3(-1, 0, -1), Vector3(0.5, 0.5, 0.5));
    await _addNode('assets/models/jury_box.glb', Vector3(1, 0, -1), Vector3(0.5, 0.5, 0.5));
    await _addNode('assets/models/defense_table.glb', Vector3(-1, 0, 0), Vector3(0.5, 0.5, 0.5));
    await _addNode('assets/models/prosecution_table.glb', Vector3(1, 0, 0), Vector3(0.5, 0.5, 0.5));
    for (double x = -1.5; x <= 1.5; x += 1.5) {
      await _addNode('assets/models/gallery_chair.glb', Vector3(x, 0, 1), Vector3(0.3, 0.3, 0.3));
    }
  }

  Future<void> _addNode(String uri, Vector3 position, Vector3 scale) async {
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: uri,
      scale: scale,
      position: position,
    );
    await arObjectManager?.addNode(node);
  }
}
