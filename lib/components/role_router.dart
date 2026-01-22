import 'package:equip_sight/pages/admin_dashboard.dart';
import 'package:equip_sight/pages/dormitory_dashboard.dart';
import 'package:equip_sight/pages/index.dart';
import 'package:equip_sight/pages/university_dashboard.dart';
import 'package:flutter/material.dart';

void navigateByRole(
  BuildContext context,
  String? role, {
  String? universityId,
  String? countryId,
  String? cityId,
  String? dormId,
}) {
  Widget targetPage;

  switch (role) {
    case 'super_admin':
      targetPage = const AdminDashboard();
      break;

    case 'university_admin':
      targetPage = UniversityDashboard(
        universityId: universityId,
        countryId: countryId,
        cityId: cityId,
      );
      break;

    case 'dorm_admin':
      targetPage = DormitoryDashboard(
        countryId: countryId,
        cityId: cityId,
        universityId: universityId,
        dormId: dormId,
      );
      break;

    default:
      targetPage = IndexPage();
  }

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
