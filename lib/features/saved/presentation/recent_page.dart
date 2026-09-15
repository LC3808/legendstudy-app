import 'package:flutter/material.dart';
import '../../personal/personal_list_providers.dart';
import '../../personal/presentation/personal_material_list.dart';

class RecentPage extends StatelessWidget {
  const RecentPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PersonalMaterialListPage(kind: PersonalListKind.recentViews);
}
