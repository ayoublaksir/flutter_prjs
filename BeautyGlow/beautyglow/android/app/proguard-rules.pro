# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Enhanced ExoPlayer and MediaCodec preservation
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class android.media.MediaCodec { *; }
-keep class android.media.MediaCodec$* { *; }
-keep class android.media.MediaCodec$CodecException { *; }

# Enhanced AdMob classes preservation
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-keep class com.google.android.gms.ads.rewarded.** { *; }
-keep class com.google.android.gms.ads.interstitial.** { *; }

# Enhanced video codec related classes
-keep class * implements android.media.MediaCodec$* { *; }
-keep class * extends android.media.MediaCodec { *; }
-keep class * implements android.media.MediaCodec$Callback { *; }

# Keep native methods for video processing
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enhanced video decoder classes
-keep class c2.** { *; }
-keep class android.media.** { *; }
-keep class android.view.** { *; }

# Enhanced ExoPlayer renderers
-keep class * extends androidx.media3.exoplayer.Renderer { *; }
-keep class * extends androidx.media3.exoplayer.RendererCapabilities { *; }
-keep class * extends androidx.media3.exoplayer.mediacodec.MediaCodecRenderer { *; }

# Enhanced MediaCodec renderers
-keep class * extends androidx.media3.exoplayer.mediacodec.MediaCodecRenderer { *; }
-keep class * extends androidx.media3.exoplayer.mediacodec.MediaCodecSelector { *; }
-keep class * extends androidx.media3.exoplayer.mediacodec.MediaCodecAdapter { *; }

# Enhanced video format classes
-keep class androidx.media3.common.Format { *; }
-keep class androidx.media3.common.MediaItem { *; }
-keep class androidx.media3.common.C { *; }

# Enhanced AdMob video player classes
-keep class com.google.android.gms.ads.AdView { *; }
-keep class com.google.android.gms.ads.rewarded.RewardedAd { *; }
-keep class com.google.android.gms.ads.interstitial.InterstitialAd { *; }
-keep class com.google.android.gms.ads.nativead.NativeAd { *; }

# Enhanced video player interfaces
-keep interface * extends androidx.media3.common.Player { *; }
-keep interface * extends androidx.media3.exoplayer.ExoPlayer { *; }

# Keep VP9 decoder classes specifically
-keep class c2.qti.vp9.decoder { *; }
-keep class c2.android.vp9.decoder { *; }

# Keep hardware acceleration classes
-keep class * implements android.view.HardwareRenderer { *; }
-keep class * extends android.view.HardwareRenderer { *; }

# Keep video surface classes
-keep class android.view.Surface { *; }
-keep class android.view.SurfaceHolder { *; }
-keep class android.view.SurfaceView { *; } 