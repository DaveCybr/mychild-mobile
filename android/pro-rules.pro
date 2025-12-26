# Keep Flutter classes
-keep class io.flutter.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }

# Keep model classes (jangan di-obfuscate)
-keep class com.example.couple_guard_child.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}