# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to rules specified
# in /usr/local/share/android-sdk/build-tools/36.0.0/proguard-android.txt
# You can edit this file and add your own rules here.

# Gson
-keep class com.google.gson.** { *; }
-keep class io.maestro.compose.** { *; }
-keepnames class io.maestro.compose.data.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * extends com.google.gson.reflect.TypeToken

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Coil
-dontwarn coil3.**
