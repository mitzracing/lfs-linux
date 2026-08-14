PREFIX ?= /usr
DESTDIR ?=

BINDIR := $(DESTDIR)$(PREFIX)/bin
LIBEXECDIR := $(DESTDIR)$(PREFIX)/lib/lfs-linux
DATADIR := $(DESTDIR)$(PREFIX)/share

.PHONY: install test package-check release-archive

install:
	install -Dm755 bin/lfs-linux $(BINDIR)/lfs-linux
	install -Dm755 bin/lfs-linux-desktop $(BINDIR)/lfs-linux-desktop
	install -Dm755 libexec/lfs-linux-core $(LIBEXECDIR)/lfs-linux-core
	install -Dm644 share/lfs-linux/release.env $(DATADIR)/lfs-linux/release.env
	install -Dm644 share/lfs-linux/lfs-0.7G-stock.manifest $(DATADIR)/lfs-linux/lfs-0.7G-stock.manifest
	install -Dm644 share/lfs-linux/wine-11.15-1-runtime.manifest $(DATADIR)/lfs-linux/wine-11.15-1-runtime.manifest
	install -Dm644 share/applications/io.github.mitzracing.live_for_speed_linux_launcher.desktop $(DATADIR)/applications/io.github.mitzracing.live_for_speed_linux_launcher.desktop
	install -Dm644 share/metainfo/io.github.mitzracing.live_for_speed_linux_launcher.metainfo.xml $(DATADIR)/metainfo/io.github.mitzracing.live_for_speed_linux_launcher.metainfo.xml
	install -Dm644 share/icons/hicolor/scalable/apps/io.github.mitzracing.live_for_speed_linux_launcher.svg $(DATADIR)/icons/hicolor/scalable/apps/io.github.mitzracing.live_for_speed_linux_launcher.svg
	install -Dm644 LICENSE $(DATADIR)/licenses/live-for-speed-launcher/LICENSE
	install -Dm644 docs/LEGAL.md $(DATADIR)/doc/live-for-speed-launcher/LEGAL.md
	install -Dm644 docs/TROUBLESHOOTING.md $(DATADIR)/doc/live-for-speed-launcher/TROUBLESHOOTING.md
	install -Dm644 docs/ARCHITECTURE.md $(DATADIR)/doc/live-for-speed-launcher/ARCHITECTURE.md
	install -Dm644 docs/MAINTENANCE.md $(DATADIR)/doc/live-for-speed-launcher/MAINTENANCE.md

test:
	./tests/test-public-static.sh
	./tests/test-public-core.sh
	./tests/test-website.sh
	./tests/test-release-archive.sh

package-check:
	rm -rf artifacts/pkgroot
	$(MAKE) DESTDIR=$(CURDIR)/artifacts/pkgroot PREFIX=/usr install
	./tests/test-package-boundary.sh artifacts/pkgroot

release-archive:
	./scripts/build-release-archive.sh
