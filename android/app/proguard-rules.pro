# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit / scanner
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.**
