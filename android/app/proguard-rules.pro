# Flutter and Dart FFI — the Dart VM and FFI dispatch are compiled to native
# code, so R8 does not touch them.  These rules protect the Java/Kotlin side
# of the Flutter embedding and JNI surface.

# Keep Flutter embedding classes (loaded reflectively by the Android system)
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all JNI-callable native methods (covers libflutter.so and libsweph.so
# indirect dispatch through the Flutter engine).
-keepclasseswithmembernames class * {
    native <methods>;
}

# path_provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# Prevent R8 from stripping annotation types used by Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Suppress warnings about classes referenced only from native code
-dontwarn io.flutter.**
