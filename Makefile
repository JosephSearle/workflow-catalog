# Tool versions. Keep in sync with .pre-commit-config.yaml and _lint.yml.
ACTIONLINT_VERSION       := 1.7.12
YAMLLINT_VERSION         := 1.38.0
CHECK_JSONSCHEMA_VERSION := 0.38.2
ZIZMOR_VERSION           := 1.31.1

ACTION_FILES   := $(wildcard actions/*/action.yml actions/*/action.yaml templates/action/action.yml)
TEMPLATE_FILES := $(wildcard templates/*.yml)

.DEFAULT_GOAL := help

.PHONY: help
help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-14s %s\n", $$1, $$2}'

.PHONY: lint
lint: lint-ci zizmor ## Run every linter (same as CI)

.PHONY: lint-ci
lint-ci: actionlint yamllint schema ## Linters run by the _lint Lint job

.PHONY: actionlint
actionlint: ## Lint workflows and workflow templates
	docker run --rm -v "$(CURDIR):/repo" -w /repo rhysd/actionlint:$(ACTIONLINT_VERSION) -color $(wildcard .github/workflows/*.yml) $(TEMPLATE_FILES)

.PHONY: yamllint
yamllint: ## Lint YAML style
	uvx yamllint==$(YAMLLINT_VERSION) --strict .

.PHONY: schema
schema: ## Validate action.yml, workflow and Dependabot files against their schemas
	uvx check-jsonschema==$(CHECK_JSONSCHEMA_VERSION) --builtin-schema vendor.github-workflows .github/workflows/*.yml $(TEMPLATE_FILES)
	uvx check-jsonschema==$(CHECK_JSONSCHEMA_VERSION) --builtin-schema vendor.dependabot .github/dependabot.yml
	$(if $(ACTION_FILES),uvx check-jsonschema==$(CHECK_JSONSCHEMA_VERSION) --builtin-schema vendor.github-actions $(ACTION_FILES))

.PHONY: zizmor
zizmor: ## Audit workflows and actions for security issues
	uvx zizmor==$(ZIZMOR_VERSION) --offline .

.PHONY: new-action
new-action: ## Scaffold an action: make new-action NAME=setup-node-cached
	@test -n "$(NAME)" || { echo "NAME is required. Run: make new-action NAME=<kebab-case-name>"; exit 1; }
	@test ! -e actions/$(NAME) || { echo "actions/$(NAME) already exists. Pick another NAME."; exit 1; }
	mkdir -p actions/$(NAME)
	sed 's/__NAME__/$(NAME)/g' templates/action/action.yml > actions/$(NAME)/action.yml
	sed 's/__NAME__/$(NAME)/g' templates/action/README.md > actions/$(NAME)/README.md
	sed 's/__NAME__/$(NAME)/g' templates/test-action.yml > .github/workflows/_test-action-$(NAME).yml
	@echo "Created actions/$(NAME) and .github/workflows/_test-action-$(NAME).yml."
	@echo "Next: register action-$(NAME) in .github/workflows/_ci.yml."

.PHONY: new-workflow
new-workflow: ## Scaffold a reusable workflow: make new-workflow NAME=node-ci
	@test -n "$(NAME)" || { echo "NAME is required. Run: make new-workflow NAME=<domain>-<purpose>"; exit 1; }
	@test ! -e .github/workflows/$(NAME).yml || { echo ".github/workflows/$(NAME).yml already exists. Pick another NAME."; exit 1; }
	sed 's/__NAME__/$(NAME)/g' templates/reusable-workflow.yml > .github/workflows/$(NAME).yml
	sed 's/__NAME__/$(NAME)/g' templates/test-workflow.yml > .github/workflows/_test-wf-$(NAME).yml
	sed 's/__NAME__/$(NAME)/g' templates/caller.yml > examples/callers/$(NAME).yml
	@echo "Created .github/workflows/$(NAME).yml, its test and examples/callers/$(NAME).yml."
	@echo "Next: add a fixture under tests/fixtures/ and register wf-$(NAME) in .github/workflows/_ci.yml."
