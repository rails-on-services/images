MODULES=$(dir $(wildcard */Makefile))

.PHONY: build
build: ## Call the 'build' target on all sub-modules
	$(foreach mod,$(MODULES),($(MAKE) -C $(mod) $@) || exit $$?;)

.PHONY: publish
publish: ## Call the 'publish' target on all sub-modules
	$(foreach mod,$(MODULES),($(MAKE) -C $(mod) $@) || exit $$?;)

.PHONY: publish-latest
publish-latest: ## Call the 'publish-latest' target on all sub-modules
	$(foreach mod,$(MODULES),($(MAKE) -C $(mod) $@) || exit $$?;)
