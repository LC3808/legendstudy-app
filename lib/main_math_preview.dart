import 'package:flutter/material.dart';

import 'features/essay/math_mobile/math_mobile_preview.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
    home: const MathMobilePreview(),
  ),
);
