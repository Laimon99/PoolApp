class FormValidators {
  static String? requiredField(dynamic v) =>
      (v == null || (v is String && v.trim().isEmpty))
          ? 'Campo obbligatorio'
          : null;
}
