/// Conditional AR/3D Case Explorer Screen
/// On Web: uses 3D model viewer; on Mobile/Desktop: uses AR plugin screen.
import 'package:flutter/material.dart';
import 'ar_case_explorer_interface.dart';
// Conditional imports
import 'ar_case_explorer_stub.dart'
  if (dart.library.io) 'ar_case_explorer_mobile.dart';

/// Main entry point for the AR Case Explorer feature
/// This class manages platform-specific implementations using conditional imports
class ARCaseExplorerScreen extends StatelessWidget {
  const ARCaseExplorerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ARCaseExplorerScreenImpl();
  }
}
