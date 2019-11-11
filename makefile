# -*- mode: Makefile -*-
#

# Bucket in us-east-1 (per lambda@edge requirements)
PACKAGE_OUTPUT_BUCKET = nod15c.lambda-edge
# TODO from folder name
STACK_NAME = FileShare
OUTPUT_TEMPLATE = .packaged.yaml
STAGE = dev
# Lambda edge must be in us-east-1
DEPLOY_REGION = us-east-1


# List of targets that are not files
.PHONY: \
	all \
	check \
	validate \
	compile \
	compile-clean \
	test \
	build \
	clean \
	package \
	deploy \
	errors \
	outputs

SHELL=/usr/bin/env bash -o pipefail

check-dependency = $(if $(shell command -v $(1)),,$(error Please install $(1)))

makefiles = $(shell find . -mindepth 2 -maxdepth 2 -type f -name 'makefile')
subdirs := $(foreach proj,$(makefiles),$(dir $(proj)))

check:
	@$(call check-dependency,aws)
	@$(call check-dependency,jq)
	@echo "Dirs: $(subdirs)"
	@echo "Try: make build, make test, make deploy"

compile:
	@for dir in $(subdirs); do \
		$(MAKE) -C $$dir ; \
	 done

compile-clean:
	@for dir in $(subdirs); do \
		$(MAKE) -C $$dir clean; \
	 done

test:
	@set -e; for dir in $(subdirs); do \
		cd $$dir; \
		npm run test; \
	 done

clean: compile-clean
	@rm -rf .aws-sam
	@rm -f $$OUTPUT_TEMPLATE

build: compile
	@sam build

validate:
	@sam validate

package: build
	@sam package \
		--output-template-file $(OUTPUT_TEMPLATE) \
	  --s3-bucket $(PACKAGE_OUTPUT_BUCKET) \
		--region $(DEPLOY_REGION)

$(OUTPUT_TEMPLATE): package

deploy: $(OUTPUT_TEMPLATE)
	@sam deploy \
		--template-file $(OUTPUT_TEMPLATE) \
		--stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_NAMED_IAM \
		--region $(DEPLOY_REGION)

# changeset: $(OUTPUT_TEMPLATE)
# 	@aws cloudformation deploy \
# 		--no-execute-changeset \
# 		--template-file $(OUTPUT_TEMPLATE) \
# 		--stack-name $(STACK_NAME) \
# 		--capabilities CAPABILITY_NAMED_IAM \
# 		--region $(DEPLOY_REGION)

output:
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query 'Stacks[].Outputs' \
		--output table

destroy:
	@aws cloudformation delete-stack \
			--stack-name $(STACK_NAME) \
			--region $(DEPLOY_REGION)

errors:
	@aws cloudformation describe-stack-events \
			--stack-name $(STACK_NAME) \
			--region $(DEPLOY_REGION) \
			| jq '.StackEvents[]|select(.ResourceStatus|index("FAILED"))'

outputs:
	@aws cloudformation describe-stacks \
			--stack-name $(STACK_NAME) \
		  --region $(DEPLOY_REGION) \
			| jq '.Stacks[].Outputs'
