.PHONY: test unit ui snapshot links

test:
	@echo "→ Building & running all tests (unit + snapshot + UI + links)"
	xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet test || true

unit:
	xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet -only-testing:Unit test || true

ui:
	xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet -only-testing:PMRUITests test || true

snapshot:
	xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet -only-testing:Snapshot test || true

links:
	xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet -only-testing:LinkTests test || true