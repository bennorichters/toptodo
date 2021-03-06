import 'package:test/test.dart';
import 'package:toptodo_data/src/td_exceptions/td_exceptions.dart';

void main() {
  group('topdesk exceptions', () {
    test('TdModelNotFoundException', () {
      expect(
        TdNotFoundException('test').toString(),
        'TdNotFoundException: test',
      );
    });

    test('TdNotAuthorizedException', () {
      expect(
        TdNotAuthorizedException('test').toString(),
        'TdNotAuthorizedException: test',
      );
    });

    test('TdBadRequestException', () {
      expect(
        TdBadRequestException('test').toString(),
        'TdBadRequestException: test',
      );
    });

    test('TdServerException', () {
      expect(
        TdServerException('test').toString(),
        'TdServerException: test',
      );
    });

    test('TdTimeOutException', () {
      expect(
        TdTimeOutException('test').toString(),
        'TdTimeOutException: test',
      );
    });

    test('TdCannotConnect', () {
      expect(
        TdCannotConnect('test').toString(),
        'TdCannotConnect: test',
      );
    });

    test('TdVersionNotSupported', () {
      expect(
        TdVersionNotSupported('test').toString(),
        'TdVersionNotSupported: test',
      );
    });
  });
}
