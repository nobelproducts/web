.PHONY: help build-all save-all build-and-save \
        build-dragon   save-dragon   \
        build-fenix    save-fenix    \
        build-gustex   save-gustex   \
        build-hotprint save-hotprint \
        build-turbo    save-turbo    \
        build-flash    save-flash

IMAGES_DIR := web/deployments/digitalocean/server1/images

# ── Help ─────────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "  nobelproducts — root build"
	@echo ""
	@echo "  Usage: make <target>"
	@echo ""
	@echo "  All projects"
	@echo "    build-and-save   Build all images then save all .tar files"
	@echo "    build-all        Build all Docker images"
	@echo "    save-all         Save all Docker images to $(IMAGES_DIR)/"
	@echo ""
	@echo "  Per project"
	@echo "    build-dragon     Build dragon-screen-web   (dragon-print-studio)"
	@echo "    build-fenix      Build fenix-screen-web    (bangkok-screen-masters)"
	@echo "    build-gustex     Build gustex-screen-web   (gustex-print-studio)"
	@echo "    build-hotprint   Build hotprint-screen-web (hotprint-screen-studio)"
	@echo "    build-turbo      Build turbo-screen-web    (dtf-color-studio)"
	@echo "    build-flash      Build flash-screen-web    (easy-site-builder)"
	@echo ""
	@echo "    save-dragon      Save dragon-screen-web.tar"
	@echo "    save-fenix       Save fenix-screen-web.tar"
	@echo "    save-gustex      Save gustex-screen-web.tar"
	@echo "    save-hotprint    Save hotprint-screen-web.tar"
	@echo "    save-turbo       Save turbo-screen-web.tar"
	@echo "    save-flash       Save flash-screen-web.tar"
	@echo ""

# ── Aggregate ─────────────────────────────────────────────────────────────────

build-and-save: build-all save-all

build-all: build-dragon build-fenix build-gustex build-hotprint build-turbo build-flash

save-all: save-dragon save-fenix save-gustex save-hotprint save-turbo save-flash

# ── Build targets ─────────────────────────────────────────────────────────────

build-dragon:
	@echo "Building dragon-screen-web from dragon-print-studio..."
	$(MAKE) -C dragon-print-studio docker-build

build-fenix:
	@echo "Building fenix-screen-web from bangkok-screen-masters..."
	$(MAKE) -C bangkok-screen-masters docker-build

build-gustex:
	@echo "Building gustex-screen-web from gustex-print-studio..."
	$(MAKE) -C gustex-print-studio docker-build

build-hotprint:
	@echo "Building hotprint-screen-web from hotprint-screen-studio..."
	$(MAKE) -C hotprint-screen-studio docker-build

build-turbo:
	@echo "Building turbo-screen-web from dtf-color-studio..."
	$(MAKE) -C dtf-color-studio docker-build

build-flash:
	@echo "Building flash-screen-web from easy-site-builder..."
	$(MAKE) -C easy-site-builder docker-build

# ── Save targets ──────────────────────────────────────────────────────────────

save-dragon:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving dragon-screen-web → $(IMAGES_DIR)/dragon-screen-web.tar"
	docker save dragon-screen-web:latest -o $(IMAGES_DIR)/dragon-screen-web.tar

save-fenix:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving fenix-screen-web → $(IMAGES_DIR)/fenix-screen-web.tar"
	docker save fenix-screen-web:latest -o $(IMAGES_DIR)/fenix-screen-web.tar

save-gustex:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving gustex-screen-web → $(IMAGES_DIR)/gustex-screen-web.tar"
	docker save gustex-screen-web:latest -o $(IMAGES_DIR)/gustex-screen-web.tar

save-hotprint:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving hotprint-screen-web → $(IMAGES_DIR)/hotprint-screen-web.tar"
	docker save hotprint-screen-web:latest -o $(IMAGES_DIR)/hotprint-screen-web.tar

save-turbo:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving turbo-screen-web → $(IMAGES_DIR)/turbo-screen-web.tar"
	docker save turbo-screen-web:latest -o $(IMAGES_DIR)/turbo-screen-web.tar

save-flash:
	@mkdir -p $(IMAGES_DIR)
	@echo "Saving flash-screen-web → $(IMAGES_DIR)/flash-screen-web.tar"
	docker save flash-screen-web:latest -o $(IMAGES_DIR)/flash-screen-web.tar
