# -*- mode: Makefile -*-
#

PATH := node_modules/.bin:$(PATH)

source_files := $(wildcard src/*.ts)
build_files := $(source_files:src/%.ts=dist/%.js)
PACKAGE := .package/$(shell node -p 'const p=require("./package.json"); `$${p.name}-$${p.version}.tgz`')
.PHONY: \
	all \
	package \
	clean

all: $(build_files)

package: $(PACKAGE)

clean:
	npm run build:clean

package-lock.json: package.json
	npm i

node_modules: package-lock.json
	npm ci

$(build_files): $(source_files) package.json node_modules
	npm run build

$(PACKAGE): $(build_files)
	@mkdir -p "$(dir $@)"
	@cd $(dir $@) && npm pack $(CURDIR)

