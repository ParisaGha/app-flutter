
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  test(
    'PROVE IT! verwendet das richtige App-Widget',
    () {
      const app = ProveItApp();

      expect(app, isA<StatefulWidget>());
    },
  );
}
