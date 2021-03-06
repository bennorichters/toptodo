import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:toptodo_data/toptodo_data.dart';
import 'package:toptodo_local_storage/toptodo_local_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('Credentials Provider', () {
    test('provide', () async {
      final mfss = MockFlutterSecureStorage();
      when(mfss.read(
        key: 'url',
      )).thenAnswer((_) => Future.value('the url'));
      when(mfss.read(
        key: 'loginName',
      )).thenAnswer((_) => Future.value('the login name'));
      when(mfss.read(
        key: 'password',
      )).thenAnswer((_) => Future.value('the password'));

      final ssc = SecureStorageCredentials(
        storage: mfss,
      );

      final credentials = await ssc.provide();
      expect(credentials.url, 'the url');
      expect(credentials.loginName, 'the login name');
      expect(credentials.password, 'the password');
    });

    test('save - write returns Future<void> on right calls', () async {
      final mfss = MockFlutterSecureStorage();
      final ssc = SecureStorageCredentials(
        storage: mfss,
      );

      when(mfss.write(
        key: 'url',
        value: 'a',
      )).thenAnswer((_) async => {});

      when(mfss.write(
        key: 'loginName',
        value: 'b',
      )).thenAnswer((_) async => {});

      when(mfss.write(
        key: 'password',
        value: 'c',
      )).thenAnswer((_) async => {});

      await ssc.save(
        Credentials(
          url: 'a',
          loginName: 'b',
          password: 'c',
        ),
      );
    });

    test('delete', () async {
      final mfss = MockFlutterSecureStorage();
      final ssc = SecureStorageCredentials(
        storage: mfss,
      );

      await ssc.delete();
      verify(mfss.deleteAll()).called(1);
    });
  });
}
