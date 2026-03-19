# 忽略 UCrop 依赖的 okhttp 缺失警告
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn java.nio.file.**

# 保护 UCrop 核心类不被过度混淆
-keep class com.yalantis.ucrop** { *; }
-keep class com.yalantis.ucrop.** { *; }
