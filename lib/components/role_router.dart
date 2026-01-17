import 'package:flutter/material.dart';
import 'package:laundry_lens/pages/admin_dashboard.dart';
import 'package:laundry_lens/pages/dormitory_dashboard.dart';
import 'package:laundry_lens/pages/university_dashboard.dart';

void navigateByRole(
    BuildContext context,
    String role, {
      String? universityId,
      String? dormId,
    }) {
  switch (role) {
    case 'super_admin':
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
      break;

    case 'university_admin':
      if (universityId == null) {
        throw Exception('universityId manquant pour university_admin');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UniversityDashboard(
            universityId: universityId,
          ),
        ),
      );
      break;

    case 'dorm_admin':
      if (dormId == null) {
        throw Exception('dormId manquant pour dorm_admin');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DormitoryDashboard(
            dormId: dormId,
          ),
        ),
      );
      break;

    default:
      throw Exception('Rôle inconnu : $role');
  }
}

