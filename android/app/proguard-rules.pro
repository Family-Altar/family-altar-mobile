# flutter_local_notifications: prevent R8 from stripping serialization classes
# used by the scheduled notification receiver at alarm-fire time.
-keep class com.dexterous.** { *; }
