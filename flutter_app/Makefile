# Flutter 3.47.4 is pinned in ../.fvmrc (ADR 0013). FVM users: make verify FLUTTER="fvm flutter"
FLUTTER ?= flutter

.PHONY: verify
verify:
	$(FLUTTER) analyze
	$(FLUTTER) test
