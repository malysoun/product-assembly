
MATURITY ?= DEV
BUILD_NUMBER  ?= DEV

IMAGENAME  = $(TARGET_PRODUCT)_$(SHORT_VERSION)

FROM_IMAGE = product-base:$(VERSION)_$(BUILD_NUMBER)_$(MATURITY)

TAG = zenoss/$(IMAGENAME):$(VERSION)_$(BUILD_NUMBER)_$(MATURITY)

.PHONY: build push clean getDownloadLogs

UPGRADE_SCRIPTS = upgrade-$(TARGET_PRODUCT).txt upgrade-$(TARGET_PRODUCT).sh $(ADDITIONAL_UPGRADE_SCRIPTS)

build: $(UPGRADE_SCRIPTS) Dockerfile zenpack_download
	docker build  -t $(TAG) .

Dockerfile:
	echo $(FROM_IMAGE)
	@sed -e  's/%FROM_IMAGE%/$(FROM_IMAGE)/g; s/%SHORT_VERSION%/$(SHORT_VERSION)/g' Dockerfile.in > $@

zenpacks:
	@mkdir $@

zenpack_download: zenpacks
	../artifact_download.py ../zenpack_versions.json --zp_manifest zenpacks.json --out_dir zenpacks --reportFile zenpacks_artifact.log

push:
	docker push $(TAG)

clean:
	rm -rf zenpacks
	rm -f Dockerfile $(UPGRADE_SCRIPTS) zenoss_component_artifact.log zenpacks_artifact.log
	-docker rmi -f $(TAG)

getDownloadLogs:
	docker run --rm -v $(PWD):/mnt/export -t $(TAG) rsync -a /opt/zenoss/log/zenoss_component_artifact.log /opt/zenoss/log/zenpacks_artifact.log /mnt/export

upgrade-%.txt:
	@sed -e 's/%HBASE_VERSION%/$(HBASE_VERSION)/g; s/%OPENTSDB_VERSION%/$(OPENTSDB_VERSION)/g; s/%SHORT_VERSION%/$(SHORT_VERSION)/g; s/%VERSION%/$(VERSION)/g; s/%RELEASE_PHASE%/$(MATURITY)/g; ' upgrade-$*.txt.in > $@

upgrade-%.sh:
	@sed -e 's/%SHORT_VERSION%/$(SHORT_VERSION)/g; s/%VERSION%/$(VERSION)/g;' upgrade-$*.sh.in > $@
	@chmod +x $@

run-tests:
	docker run -i --rm $(TAG) /opt/zenoss/install_scripts/starttests.sh
