import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArMeasurementScreen extends StatefulWidget {
  const ArMeasurementScreen({super.key});

  @override
  State<ArMeasurementScreen> createState() => _ArMeasurementScreenState();
}

class _ArMeasurementScreenState extends State<ArMeasurementScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  String distance = "Tap to place start point";
  bool showGrid = true;

  String status = "Initializing...";

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure'),
        actions: [
          IconButton(
            icon: Icon(showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () {
              setState(() {
                showGrid = !showGrid;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRemoveEverything,
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    distance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.touch_app),
                label: const Text('Tap on dotted plane to place point'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          // customPlaneTexturePath: "Images/triangle.png", // Optional: use custom texture if needed
          showWorldOrigin: false,
          handleTaps: true,
        );
    this.arObjectManager!.onInitialize();

    // Assign callback
    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;

    // Explicitly update status after init
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        status = "AR Initialized. Scan for planes.";
      });
    });
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    // Debug print to console as well
    print("AR Debug: Tap received. Count: ${hitTestResults.length}");

    setState(() {
      status = "Tap received. Hits: ${hitTestResults.length}";
    });

    if (hitTestResults.isEmpty) {
      // Sometimes just tapping the screen without a plane hit still triggers with empty list
      setState(() {
        status = "No plane detected at tap location. Try finding more planes.";
      });
      return;
    }

    // Limit to 2 points for simple distance measurement
    if (nodes.length >= 2) {
      await onRemoveEverything();
    }

    final ARHitTestResult singleHitTestResult = hitTestResults.first;

    // Add an anchor
    var newAnchor = ARPlaneAnchor(
      transformation: singleHitTestResult.worldTransform,
    );
    bool? added = await arAnchorManager!.addAnchor(newAnchor);
    if (added == true) {
      anchors.add(newAnchor);

      // Add a node (box) to the anchor
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: "assets/models/Box.glb",
        scale:
            vector.Vector3(0.01, 0.01, 0.01), // Smaller 1cm box for precision
        position: vector.Vector3(0, 0, 0),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? nodeAdded =
          await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (nodeAdded == true) {
        nodes.add(newNode);
        setState(() {
          status = "Point placed!";
        });

        if (nodes.length == 2) {
          calculateDistance();
        } else {
          setState(() {
            distance = "Tap to place second point";
          });
        }
      } else {
        setState(() {
          status = "Failed to add node (download failed?)";
        });
      }
    } else {
      setState(() {
        status = "Failed to add anchor";
      });
    }
  }

  void calculateDistance() {
    if (anchors.length < 2) return;

    var pos1 = anchors[0].transformation.getTranslation();
    var pos2 = anchors[1].transformation.getTranslation();

    double dist = pos1.distanceTo(pos2);

    setState(() {
      distance = "Distance: ${dist.toStringAsFixed(2)} meters";
      status = "Measurement complete";
    });
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors = [];
    nodes = [];
    setState(() {
      distance = "Tap to place start point";
      status = "Cleared. Scan for planes.";
    });
  }
}
