class AuthRoleHelper {
  static const List<String> defaultAdminEmails = [
    'admin@so.com',
    'admin@huliot.com',
    'admin@gmail.com',
  ];

  static const List<String> defaultDispatchEmails = [
    'dispatch@gmail.com',
    'dispatch@so.com',
    'dispatch@huliot.com',
  ];

  static const List<String> defaultBackOfficeEmails = [
    'backoffice@gmail.com',
    'backoffice@so.com',
    'backoffice@huliot.com',
  ];

  static const List<String> trustedDomains = [
    'so.com',
    'huliot.com',
    'gmail.com',
  ];

  /// Validates whether the email belongs to an authorized company or developer domain
  static bool isAllowedCompanyDomain(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final lower = email.trim().toLowerCase();
    for (final domain in trustedDomains) {
      if (lower.endsWith('@$domain')) return true;
    }
    return false;
  }

  static bool isAdmin(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final lower = email.trim().toLowerCase();
    if (defaultAdminEmails.contains(lower)) return true;

    // Strict validation: Must have exact username 'admin' under trusted domains
    for (final domain in trustedDomains) {
      if (lower == 'admin@$domain') return true;
    }
    return false;
  }

  static bool isBackOffice(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final lower = email.trim().toLowerCase();
    if (defaultBackOfficeEmails.contains(lower)) return true;

    // Strict validation: Must have exact username 'backoffice' under trusted domains
    for (final domain in trustedDomains) {
      if (lower == 'backoffice@$domain') return true;
    }
    return false;
  }

  static bool isDispatch(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final lower = email.trim().toLowerCase();
    if (defaultDispatchEmails.contains(lower)) return true;

    // Strict validation: Must have exact username 'dispatch' under trusted domains
    for (final domain in trustedDomains) {
      if (lower == 'dispatch@$domain') return true;
    }
    return false;
  }
}
