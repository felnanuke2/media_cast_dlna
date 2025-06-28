# ProGuard rules for JUPnP (Cling) and Seamless
-keep class org.jupnp.** { *; }
-keep class org.seamless.** { *; }
-keep class org.fourthline.cling.** { *; }
-keep class org.fourthline.seamless.** { *; }
-keep class org.eclipse.jetty.** { *; }
-dontwarn org.jupnp.**
-dontwarn org.seamless.**
-dontwarn org.fourthline.cling.**
-dontwarn org.fourthline.seamless.**
-dontwarn org.eclipse.jetty.**

# Handle MethodHandle compatibility issues
-dontwarn java.lang.invoke.MethodHandle
-dontwarn java.lang.invoke.MethodHandles
-dontwarn java.lang.invoke.MethodType
-dontwarn java.lang.invoke.VarHandle

# Keep reflection-related classes that might be used by Jetty
-keep class java.lang.invoke.** { *; }
-keepclassmembers class ** {
    public <init>(...);
}

# Additional Jetty-specific rules
-keep class org.eclipse.jetty.servlet.** { *; }
-keep class org.eclipse.jetty.util.** { *; }
-dontwarn org.eclipse.jetty.servlet.DecoratingListener$*
