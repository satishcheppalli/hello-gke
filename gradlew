#!/usr/bin/env sh

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

CLASSPATH=`dirname "$0"`/gradle/wrapper/gradle-wrapper.jar

if [ ! -f "$CLASSPATH" ]; then
    echo "Error: gradle-wrapper.jar not found"
    exit 1
fi

exec java -jar "$CLASSPATH" "$@"
