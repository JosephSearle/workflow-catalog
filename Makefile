# Tool versions. Keep in sync with .pre-commit-config.yaml, _lint.yml and _ci.yml.
ACTIONLINT_VERSION       := 1.7.12
YAMLLINT_VERSION         := 1.38.0
CHECK_JSONSCHEMA_VERSION := 0.38.2
ZIZMOR_VERSION           := 1.31.1

ACTION_FILES   := $(wildcard actions/*/action.yml actions/*/action.yaml templates/action/action.yml)
TEMPLATE_FILES := $(wildcard templates/*.yml)

.DEFAULT_GOAL := help

# Take NAME literally, so make never expands a $(...) inside it. Only a command-line
# NAME counts, so a NAME exported by the environment can't pass check-name.
override NAME := $(if $(filter command line,$(origin NAME)),$(value NAME))

# Fails unless NAME is a single kebab-case line, so it's safe to splice into shell and sed.
# NAME stays single-quoted (any ' becomes !) until it has passed. A newline would split
# the recipe line, so make rejects it before the shell sees it.
define newline


endef

define check-name
	$(if $(findstring $(newline),$(NAME)),$(error NAME must be kebab-case, e.g. setup-node-cached))
	@printf '%s\n' '$(subst ',!,$(NAME))' | awk 'NR == 1 { ok = /^[a-z0-9]+(-[a-z0-9]+)*$$/ } END { exit !(NR == 1 && ok) }' || { echo "NAME must be kebab-case. Run: make $@ NAME=<kebab-case-name>, e.g. setup-node-cached."; exit 1; }
endef

# Fails if any of the given paths already exist.
define check-absent
	@for f in $(1); do test ! -e "$$f" || { echo "$$f already exists. Pick another NAME or remove it."; exit 1; }; done
endef

.PHONY: help
help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-20s %s\n", $$1, $$2}'

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

# Take FILES literally, like NAME. Only a command-line FILES counts.
override FILES := $(if $(filter command line,$(origin FILES)),$(value FILES))

LINT_ACTIONS   := $(filter actions/% templates/action/%,$(FILES))
LINT_WORKFLOWS := $(filter-out $(LINT_ACTIONS),$(FILES))

# Fails unless FILES is one line of workflow, action or template paths, so it's safe to
# splice into shell. The pattern admits no quotes, `$`, `..` or spaces inside a path.
define check-files
	$(if $(findstring $(newline),$(FILES)),$(error FILES must be workflow, action or template paths))
	@printf '%s\n' '$(subst ',!,$(FILES))' | awk '{ n = NF; for (i = 1; i <= NF; i++) if ($$i !~ /^(\.github\/workflows\/[A-Za-z0-9_-]+|actions\/[a-z0-9-]+\/action|templates\/([a-z0-9-]+\/)?[a-z0-9-]+)\.ya?ml$$/) bad = 1 } END { exit !(NR == 1 && n > 0 && !bad) }' || { echo "FILES must be workflow, action or template paths, e.g. make $@ FILES=.github/workflows/node-ci.yml."; exit 1; }
endef

# Used by the Claude Code hook in .claude/hooks/. Runs every linter before failing, so
# one run reports every finding. zizmor runs offline to keep it fast.
.PHONY: lint-files
lint-files: ## Lint given workflow, action or template files: make lint-files FILES=.github/workflows/node-ci.yml
	$(check-files)
	@rc=0; \
	uvx yamllint==$(YAMLLINT_VERSION) --strict $(FILES) || rc=1; \
	$(if $(LINT_WORKFLOWS),if docker info >/dev/null 2>&1; then \
	  docker run --rm -v "$(CURDIR):/repo" -w /repo rhysd/actionlint:$(ACTIONLINT_VERSION) $(LINT_WORKFLOWS) || rc=1; \
	else echo "Docker isn't running. Skipping actionlint."; fi; \
	uvx check-jsonschema==$(CHECK_JSONSCHEMA_VERSION) --builtin-schema vendor.github-workflows $(LINT_WORKFLOWS) || rc=1;) \
	$(if $(LINT_ACTIONS),uvx check-jsonschema==$(CHECK_JSONSCHEMA_VERSION) --builtin-schema vendor.github-actions $(LINT_ACTIONS) || rc=1;) \
	uvx zizmor==$(ZIZMOR_VERSION) --offline --config .github/zizmor.yml $(FILES) || rc=1; \
	exit $$rc

# Dependabot doesn't scan templates/, so their pins drift. new-action and new-workflow
# sync what they generate, so this isn't a CI gate: these targets just tidy templates/.
.PHONY: template-pins
template-pins: ## Check template action pins match those in .github/workflows or actions/
	@scripts/template-pins.sh --check

.PHONY: sync-template-pins
sync-template-pins: ## Update template action pins to those in .github/workflows and actions/
	@scripts/template-pins.sh --sync

# CI runs zizmor's online audits too, so do the same whenever a GitHub token is available.
.PHONY: zizmor
zizmor: ## Audit workflows and actions for security issues
	@token="$${GH_TOKEN:-$${GITHUB_TOKEN:-$$(gh auth token 2>/dev/null || true)}}"; \
	if [ -n "$$token" ]; then \
	  GH_TOKEN="$$token" uvx zizmor==$(ZIZMOR_VERSION) .; \
	else \
	  echo "No GH_TOKEN or gh login, so skipping the online audits CI runs."; \
	  uvx zizmor==$(ZIZMOR_VERSION) --offline .; \
	fi

.PHONY: new-action
new-action: ## Scaffold an action: make new-action NAME=setup-node-cached
	$(check-name)
	$(call check-absent,actions/$(NAME) .github/workflows/_test-action-$(NAME).yml)
	mkdir -p actions/$(NAME)
	sed 's/__NAME__/$(NAME)/g' templates/action/action.yml > actions/$(NAME)/action.yml
	sed 's/__NAME__/$(NAME)/g' templates/action/README.md > actions/$(NAME)/README.md
	sed 's/__NAME__/$(NAME)/g' templates/test-action.yml > .github/workflows/_test-action-$(NAME).yml
	@scripts/template-pins.sh --sync actions/$(NAME)/action.yml .github/workflows/_test-action-$(NAME).yml
	@echo "Created actions/$(NAME) and .github/workflows/_test-action-$(NAME).yml."
	@echo "Next: register action-$(NAME) in .github/workflows/_ci.yml."

.PHONY: new-workflow
new-workflow: ## Scaffold a reusable workflow: make new-workflow NAME=node-ci
	$(check-name)
	$(call check-absent,.github/workflows/$(NAME).yml .github/workflows/_test-wf-$(NAME).yml examples/callers/$(NAME).yml)
	sed 's/__NAME__/$(NAME)/g' templates/reusable-workflow.yml > .github/workflows/$(NAME).yml
	sed 's/__NAME__/$(NAME)/g' templates/test-workflow.yml > .github/workflows/_test-wf-$(NAME).yml
	sed 's/__NAME__/$(NAME)/g' templates/caller.yml > examples/callers/$(NAME).yml
	@scripts/template-pins.sh --sync .github/workflows/$(NAME).yml .github/workflows/_test-wf-$(NAME).yml examples/callers/$(NAME).yml
	@echo "Created .github/workflows/$(NAME).yml, its test and examples/callers/$(NAME).yml."
	@echo "Next: add fixtures under tests/fixtures/$(NAME)/ (and $(NAME)-failing/) and register wf-$(NAME) in .github/workflows/_ci.yml."
