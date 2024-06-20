// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:test/test.dart';
import 'package:vin_decoder/src/nhtsa_model.dart';

void main() {
  test('NHTSA.getAllMakes', () async {
    final makes = await NHTSA.getAllMakes();
    expect(makes?.isNotEmpty, isTrue);
  });

  test('NHTSA.isMakeValid', () async {
    final nhtsa = NHTSA();
    final valid = await nhtsa.isMakeValid('ZOOK\'S WELDING');
    expect(valid, isTrue);

    expect(await nhtsa.isMakeValid('honda'), isTrue);
    expect(await nhtsa.isMakeValid('Polestar'), isTrue);
    expect(await nhtsa.isMakeValid('Tesla'), isTrue);
  });
}
