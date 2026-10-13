import 'package:arid/services/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ageOn', () {
    test('turns 15 on the birthday, not the day before', () {
      final birth = DateTime(2011, 10, 14);
      expect(AuthService.ageOn(birth, DateTime(2026, 10, 13)), 14);
      expect(AuthService.ageOn(birth, DateTime(2026, 10, 14)), 15);
    });

    test('counts a 29 February birthday in non-leap years', () {
      final birth = DateTime(2008, 2, 29);
      expect(AuthService.ageOn(birth, DateTime(2023, 2, 28)), 14);
      expect(AuthService.ageOn(birth, DateTime(2023, 3, 1)), 15);
    });
  });

  test('formatBirthDate pads to YYYY-MM-DD', () {
    expect(AuthService.formatBirthDate(DateTime(2005, 3, 7)), '2005-03-07');
  });

  test('displayNameFor abbreviates the middle name and skips it if empty', () {
    expect(
      AuthService.displayNameFor('Juan', 'dela Paz', 'Cruz'),
      'Juan D. Cruz',
    );
    expect(AuthService.displayNameFor(' Ana ', '  ', 'Reyes'), 'Ana Reyes');
  });

  test('usernameProblem accepts simple names and rejects bad ones', () {
    expect(AuthService.usernameProblem('juan.cruz_01'), isNull);
    expect(AuthService.usernameProblem('ab'), isNotNull);
    expect(AuthService.usernameProblem('juan cruz'), isNotNull);
  });
}
