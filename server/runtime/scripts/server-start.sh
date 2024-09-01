#!/bin/sh

# Minecraft server start script
# NOTE: The source for almost all these decisions on JVM args is https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks

: "${JAR_NAME:?}"
: "${MEMORY_AMOUNT:?}"

# TODO: refactor so that you can easily override JVM args as a user of the container
#: "${JVM_ARGS:?}"

set_base_args() {
	base_args='-XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1'
}

set_gc_args() {
	# Using ZGC
	gc_args='-XX:+UseZGC -XX:+ZGenerational -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:-ZProactive -XX:-ZUncommit'

	# NOTE:
	# According to source linked at the top of this file, set ConcGCThreads = 2 on CPUs with 2c/4t and [# cores - 2] on most other CPUs.
	# So I'm just gonna use the "core count - 2" formula but make sure the result is always >= 2
	core_count=$(getconf _NPROCESSORS_ONLN)
	conc_gc_threads=$((core_count - 2))
	if [ "${conc_gc_threads}" -lt 2 ]; then
		conc_gc_threads=2
	fi

	gc_args="${gc_args} -XX:ConcGCThreads=${conc_gc_threads}"
}

set_extra_args() {
	# See "Large Pages" section of the source linked above
	extra_args='-XX:+UseTransparentHugePages'
}

main() {
	set_base_args

	set_gc_args

	set_extra_args

	# adds module for better performance on (I think) papermc servers and their forks
	module_args="--add-modules=jdk.incubator.vector"

	jvm_args="${module_args} ${base_args} ${gc_args} ${extra_args}"

	# start server
	# shellcheck disable=SC2086 # ${jvm_args} word-splitting is intentional
	exec java "-Xms${MEMORY_AMOUNT}" "-Xmx${MEMORY_AMOUNT}" ${jvm_args} -jar "${JAR_NAME}" nogui
}

main "$@"
