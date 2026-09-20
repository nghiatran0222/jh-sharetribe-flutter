# Flutter 3.47.4 is pinned in ../.fvmrc (ADR 0013). FVM users: make verify FLUTTER="fvm flutter"
FLUTTER ?= flutter

.PHONY: verify
verify:
	$(FLUTTER) analyze
	$(FLUTTER) test

# End-to-end on a booted simulator or device, in mock mode (ADR 0016).
# Not part of `verify`, which must run without a device. Also writes the
# screenshots in ../docs/screenshots/.
#   make e2e DEVICE=<device-id>     # `flutter devices` lists the ids
DEVICE ?= ios

.PHONY: e2e
e2e:
	$(FLUTTER) drive --driver=test_driver/integration_test.dart \
		--target=integration_test/app_test.dart -d $(DEVICE)
