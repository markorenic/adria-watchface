JAVA_HOME ?= /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk
export JAVA_HOME
PATH := /opt/homebrew/opt/openjdk@17/bin:/opt/homebrew/bin:$(PATH)
export PATH

.PHONY: build package

build:
	mkdir -p bin
	monkeyc -f monkey.jungle -d fenix7x -y bin/developer_key.der -o bin/Adria.prg -w

package:
	mkdir -p bin
	monkeyc -e -r -f monkey.jungle -y bin/developer_key.der -o bin/Adria.iq -w
