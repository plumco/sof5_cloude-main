import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/services/auth_role_helper.dart';

void main() {
  group('AuthRoleHelper - Role Authorization & Security Tests', () {
    test('Valid admin emails should have admin access', () {
      expect(AuthRoleHelper.isAdmin('admin@so.com'), isTrue);
      expect(AuthRoleHelper.isAdmin('admin@huliot.com'), isTrue);
      expect(AuthRoleHelper.isAdmin('admin@gmail.com'), isTrue);
      expect(AuthRoleHelper.isAdmin('ADMIN@GMAIL.COM'), isTrue, reason: 'Case-insensitive');
      expect(AuthRoleHelper.isAdmin('  admin@gmail.com  '), isTrue, reason: 'Trims whitespace');
    });

    test('Valid dispatch emails should have dispatch access', () {
      expect(AuthRoleHelper.isDispatch('dispatch@gmail.com'), isTrue);
      expect(AuthRoleHelper.isDispatch('dispatch@so.com'), isTrue);
      expect(AuthRoleHelper.isDispatch('dispatch@huliot.com'), isTrue);
      expect(AuthRoleHelper.isDispatch('DISPATCH@GMAIL.COM'), isTrue, reason: 'Case-insensitive');
    });

    test('Valid back office emails should have back office access', () {
      expect(AuthRoleHelper.isBackOffice('backoffice@gmail.com'), isTrue);
      expect(AuthRoleHelper.isBackOffice('backoffice@so.com'), isTrue);
      expect(AuthRoleHelper.isBackOffice('backoffice@huliot.com'), isTrue);
      expect(AuthRoleHelper.isBackOffice('BACKOFFICE@GMAIL.COM'), isTrue, reason: 'Case-insensitive');
      expect(AuthRoleHelper.isBackOffice('  backoffice@gmail.com  '), isTrue, reason: 'Trims whitespace');
    });

    test('Null, empty, or whitespace email should fail safely', () {
      expect(AuthRoleHelper.isAdmin(null), isFalse);
      expect(AuthRoleHelper.isAdmin(''), isFalse);
      expect(AuthRoleHelper.isAdmin('   '), isFalse);
      expect(AuthRoleHelper.isBackOffice(null), isFalse);
      expect(AuthRoleHelper.isBackOffice(''), isFalse);
      expect(AuthRoleHelper.isDispatch(null), isFalse);
      expect(AuthRoleHelper.isDispatch(''), isFalse);
      expect(AuthRoleHelper.isDispatch('   '), isFalse);
    });

    test('Regular sales rep email should NOT get admin, backoffice, or dispatch access', () {
      expect(AuthRoleHelper.isAdmin('sales1@huliot.com'), isFalse);
      expect(AuthRoleHelper.isBackOffice('sales1@huliot.com'), isFalse);
      expect(AuthRoleHelper.isDispatch('sales1@huliot.com'), isFalse);
    });

    // SECURITY EXPLOIT DEMONSTRATION:
    // Any attacker with an email containing "admin" or "dispatch" should NOT be granted privileges!
    test('SECURITY CHECK: Substring injection in email should NOT grant admin role', () {
      const maliciousEmails = [
        'badadmin@attacker.com',
        'padmind@gmail.com',
        'attacker.admin@example.org',
        'not_an_admin_user@gmail.com',
      ];

      for (final email in maliciousEmails) {
        expect(
          AuthRoleHelper.isAdmin(email),
          isFalse,
          reason: 'Exploit detected: $email gained unauthorized admin privileges!',
        );
      }
    });

    test('SECURITY CHECK: Substring injection in email should NOT grant dispatch role', () {
      const maliciousEmails = [
        'attacker_dispatch@evil.com',
        'redispatch@fake.net',
        'fastdispatching@gmail.com',
      ];

      for (final email in maliciousEmails) {
        expect(
          AuthRoleHelper.isDispatch(email),
          isFalse,
          reason: 'Exploit detected: $email gained unauthorized dispatch privileges!',
        );
      }
    });

    test('SECURITY CHECK: isAllowedCompanyDomain should allow company domains and reject unauthorized ones', () {
      // Authorized domains
      expect(AuthRoleHelper.isAllowedCompanyDomain('giriraj@so.com'), isTrue);
      expect(AuthRoleHelper.isAllowedCompanyDomain('manager@huliot.com'), isTrue);
      expect(AuthRoleHelper.isAllowedCompanyDomain('admin@so.com'), isTrue);
      expect(AuthRoleHelper.isAllowedCompanyDomain('test@gmail.com'), isTrue);

      // Malicious or unauthorized external domains
      expect(AuthRoleHelper.isAllowedCompanyDomain('hacker@evil.com'), isFalse);
      expect(AuthRoleHelper.isAllowedCompanyDomain('attacker@yahoo.com'), isFalse);
      expect(AuthRoleHelper.isAllowedCompanyDomain('phish@outlook.com'), isFalse);
      expect(AuthRoleHelper.isAllowedCompanyDomain('admin@so.com.fake.org'), isFalse);
      expect(AuthRoleHelper.isAllowedCompanyDomain(''), isFalse);
      expect(AuthRoleHelper.isAllowedCompanyDomain(null), isFalse);
    });
  });
}
