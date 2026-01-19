import 'package:flutter/material.dart';
import 'package:laundry_lens/pages/admin_dashboard.dart';
import 'package:laundry_lens/pages/dormitory_dashboard.dart';
import 'package:laundry_lens/pages/index.dart';
import 'package:laundry_lens/pages/university_dashboard.dart';

void navigateByRole(
  BuildContext context,
  String? role, {
  String? universityId,
  String? dormId,
}) {
  Widget targetPage;

  switch (role) {
    case 'super_admin':
      targetPage = const AdminDashboard();
      break;

    case 'university_admin':
      if (universityId != null && universityId.isNotEmpty) {
        targetPage = UniversityDashboard(universityId: universityId);
      } else {
        // fallback sûr
        targetPage = IndexPage();
        debugPrint(
          'Warning: universityId manquant pour role university_admin, fallback vers IndexPage',
        );
      }
      break;

    case 'dorm_admin':
      if (dormId != null && dormId.isNotEmpty) {
        targetPage = DormitoryDashboard(dormId: dormId);
      } else {
        targetPage = IndexPage();
        debugPrint(
          'Warning: dormId manquant pour role dorm_admin, fallback vers IndexPage',
        );
      }
      break;

    default:
      targetPage = IndexPage();
  }

  // Protection contre double navigation
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Navigator.canPop(context)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
        (_) => false,
      );
    }
  });
}
