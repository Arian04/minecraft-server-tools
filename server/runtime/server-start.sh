#!/bin/sh

# Minecraft server start script

# ----- Arguments -----

: "${JAR_NAME:?}"
: "${MEMORY_AMOUNT:?}"

# TODO: refactor so that you can easily override JVM args as a user of the container

# JVM args
# Source: https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks
base_args='-XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3'

# ConcGCThreads = 2 on CPUs with 2c/4t and [# cores - 2] on most other CPUs
gc_args='-XX:+UseG1GC -XX:MaxGCPauseMillis=130 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=28 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1MixedGCCountTarget=3 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:ConcGCThreads=2'

# args that I added because I personally think they help
extra_args='-XX:+UseTransparentHugePages'

jvm_args="${base_args} ${gc_args} ${extra_args}"
# ----------------

# start server
# shellcheck disable=SC2086 # jvm_args word-splitting is intentional
exec java "-Xms${MEMORY_AMOUNT}" "-Xmx${MEMORY_AMOUNT}" ${jvm_args} --add-modules=jdk.incubator.vector -jar "${JAR_NAME}" nogui
