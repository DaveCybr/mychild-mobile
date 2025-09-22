
// core/utils/validators.dart
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }
  
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    
    if (value != originalPassword) {
      return 'Password tidak cocok';
    }
    
    return null;
  }
  
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    
    return null;
  }
  
  static String? familyCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode keluarga tidak boleh kosong';
    }
    
    if (value.length != 6) {
      return 'Kode keluarga harus 6 digit';
    }
    
    final codeRegExp = RegExp(r'^[A-Z0-9]{6}$');
    if (!codeRegExp.hasMatch(value)) {
      return 'Kode keluarga hanya boleh huruf kapital dan angka';
    }
    
    return null;
  }
  
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} tidak boleh kosong';
    }
    return null;
  }
}
