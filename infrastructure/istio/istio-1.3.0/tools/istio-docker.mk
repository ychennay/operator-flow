## Copyright 2018 Istio Authors
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

.PHONY: docker
.PHONY: docker.all
.PHONY: docker.save
.PHONY: docker.push

# Docker target will build the go binaries and package the docker for local testing.
# It does not upload to a registry.
docker: build-linux test-bins-linux docker.all

# Add new docker targets to the end of the DOCKER_TARGETS list.
DOCKER_TARGETS:=docker.pilot docker.proxy_debug docker.proxytproxy docker.proxyv2 docker.app docker.app_sidecar docker.test_policybackend \
	docker.proxy_init docker.mixer docker.mixer_codegen docker.citadel docker.galley docker.sidecar_injector docker.kubectl docker.node-agent-k8s

$(ISTIO_DOCKER) $(ISTIO_DOCKER_TAR):
	mkdir -p $@

.SECONDEXPANSION: #allow $@ to be used in dependency list

# generated content
$(ISTIO_DOCKER)/istio_ca.crt $(ISTIO_DOCKER)/istio_ca.key: ${GEN_CERT} | ${ISTIO_DOCKER}
	${GEN_CERT} --key-size=2048 --out-cert=${ISTIO_DOCKER}/istio_ca.crt \
                    --out-priv=${ISTIO_DOCKER}/istio_ca.key --organization="k8s.cluster.local" \
                    --mode=self-signed --ca=true
$(ISTIO_DOCKER)/node_agent.crt $(ISTIO_DOCKER)/node_agent.key: ${GEN_CERT} $(ISTIO_DOCKER)/istio_ca.crt $(ISTIO_DOCKER)/istio_ca.key
	${GEN_CERT} --key-size=2048 --out-cert=${ISTIO_DOCKER}/node_agent.crt \
                    --out-priv=${ISTIO_DOCKER}/node_agent.key --organization="NodeAgent" \
		    --mode=signer --host="nodeagent.google.com" --signer-cert=${ISTIO_DOCKER}/istio_ca.crt \
                    --signer-priv=${ISTIO_DOCKER}/istio_ca.key

# directives to copy files to docker scratch directory

# tell make which files are copied from $(ISTIO_OUT_LINUX) and generate rules to copy them to the proper location:
# generates rules like the following:
# $(ISTIO_DOCKER)/pilot-agent: $(ISTIO_OUT_LINUX)/pilot-agent | $(ISTIO_DOCKER)
# 	cp $(ISTIO_OUT_LINUX)/$FILE $(ISTIO_DOCKER)/($FILE)
DOCKER_FILES_FROM_ISTIO_OUT_LINUX:=pkg-test-echo-cmd-client pkg-test-echo-cmd-server \
                             pilot-discovery pilot-agent sidecar-injector mixs mixgen \
                             istio_ca node_agent node_agent_k8s galley istio-iptables
$(foreach FILE,$(DOCKER_FILES_FROM_ISTIO_OUT_LINUX), \
        $(eval $(ISTIO_DOCKER)/$(FILE): $(ISTIO_OUT_LINUX)/$(FILE) | $(ISTIO_DOCKER); cp $(ISTIO_OUT_LINUX)/$(FILE) $(ISTIO_DOCKER)/$(FILE)))

# rule for the test certs.
$(ISTIO_DOCKER)/certs:
	cp -a tests/testdata/certs $(ISTIO_DOCKER)/.

# tell make which files are copied from the source tree and generate rules to copy them to the proper location:
# TODO(sdake)                      $(NODE_AGENT_TEST_FILES) $(GRAFANA_FILES)
DOCKER_FILES_FROM_SOURCE:=tools/packaging/common/istio-iptables.sh docker/ca-certificates.tgz \
                          tests/testdata/certs/cert.crt tests/testdata/certs/cert.key tests/testdata/certs/cacert.pem
# generates rules like the following:
# $(ISTIO_DOCKER)/tools/packaging/common/istio-iptables.sh: $(ISTIO_OUT)/tools/packaging/common/istio-iptables.sh | $(ISTIO_DOCKER)
# 	cp $FILE $$(@D))
$(foreach FILE,$(DOCKER_FILES_FROM_SOURCE), \
        $(eval $(ISTIO_DOCKER)/$(notdir $(FILE)): $(FILE) | $(ISTIO_DOCKER); cp $(FILE) $$(@D)))


# tell make which files are copied from ISTIO_BIN and generate rules to copy them to the proper location:
# generates rules like the following:
# $(ISTIO_DOCKER)/kubectl: $(ISTIO_BIN)/kubectl | $(ISTIO_DOCKER)
# 	cp $(ISTIO_BIN)/kubectl $(ISTIO_DOCKER)/kubectl
DOCKER_FILES_FROM_ISTIO_BIN:=kubectl
$(foreach FILE,$(DOCKER_FILES_FROM_ISTIO_BIN), \
        $(eval $(ISTIO_BIN)/$(FILE): ; bin/testEnvLocalK8S.sh getDeps))
$(foreach FILE,$(DOCKER_FILES_FROM_ISTIO_BIN), \
        $(eval $(ISTIO_DOCKER)/$(FILE): $(ISTIO_BIN)/$(FILE) | $(ISTIO_DOCKER); cp $(ISTIO_BIN)/$(FILE) $(ISTIO_DOCKER)/$(FILE)))

# pilot docker images

docker.proxy_init: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.proxy_init: pilot/docker/Dockerfile.proxy_init
docker.proxy_init: $(ISTIO_DOCKER)/istio-iptables.sh
docker.proxy_init: $(ISTIO_DOCKER)/istio-iptables
	$(DOCKER_RULE)

docker.sidecar_injector: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.sidecar_injector: pilot/docker/Dockerfile.sidecar_injector
docker.sidecar_injector:$(ISTIO_DOCKER)/sidecar-injector
	$(DOCKER_RULE)

# BUILD_PRE tells $(DOCKER_RULE) to run the command specified before executing a docker build
# BUILD_ARGS tells  $(DOCKER_RULE) to execute a docker build with the specified commands

docker.proxy_debug: BUILD_PRE=$(if $(filter 1,${USE_LOCAL_PROXY}),,mv envoy-debug-${PROXY_REPO_SHA} envoy &&) chmod 755 envoy pilot-agent &&
docker.proxy_debug: BUILD_ARGS=--build-arg proxy_version=istio-proxy:${PROXY_REPO_SHA} --build-arg istio_version=${VERSION} --build-arg BASE_VERSION=${BASE_VERSION} --build-arg ISTIO_API_SHA=${ISTIO_PROXY_ISTIO_API_SHA_LABEL} --build-arg ENVOY_SHA=${ISTIO_PROXY_ENVOY_SHA_LABEL}
docker.proxy_debug: pilot/docker/Dockerfile.proxy_debug
docker.proxy_debug: tools/packaging/common/envoy_bootstrap_v2.json
docker.proxy_debug: tools/packaging/common/envoy_bootstrap_drain.json
docker.proxy_debug: install/gcp/bootstrap/gcp_envoy_bootstrap.json
docker.proxy_debug: $(ISTIO_DOCKER)/ca-certificates.tgz
docker.proxy_debug: ${ISTIO_ENVOY_LINUX_DEBUG_PATH}
docker.proxy_debug: $(ISTIO_OUT_LINUX)/pilot-agent
docker.proxy_debug: pilot/docker/Dockerfile.proxyv2
docker.proxy_debug: pilot/docker/envoy_pilot.yaml.tmpl
docker.proxy_debug: pilot/docker/envoy_policy.yaml.tmpl
docker.proxy_debug: pilot/docker/envoy_telemetry.yaml.tmpl
	$(DOCKER_RULE)

# The file must be named 'envoy', depends on the release.
${ISTIO_ENVOY_LINUX_RELEASE_DIR}/envoy: ${ISTIO_ENVOY_LINUX_RELEASE_PATH}
	mkdir -p $(DOCKER_BUILD_TOP)/proxyv2
	cp ${ISTIO_ENVOY_LINUX_RELEASE_PATH} ${ISTIO_ENVOY_LINUX_RELEASE_DIR}/envoy

# Default proxy image.
docker.proxyv2: BUILD_PRE=chmod 755 envoy pilot-agent &&
docker.proxyv2: BUILD_ARGS=--build-arg proxy_version=istio-proxy:${PROXY_REPO_SHA} --build-arg istio_version=${VERSION} --build-arg ISTIO_API_SHA=${ISTIO_PROXY_ISTIO_API_SHA_LABEL} --build-arg ENVOY_SHA=${ISTIO_PROXY_ENVOY_SHA_LABEL} --build-arg BASE_VERSION=${BASE_VERSION}
docker.proxyv2: tools/packaging/common/envoy_bootstrap_v2.json
docker.proxyv2: tools/packaging/common/envoy_bootstrap_drain.json
docker.proxyv2: install/gcp/bootstrap/gcp_envoy_bootstrap.json
docker.proxyv2: $(ISTIO_DOCKER)/ca-certificates.tgz
docker.proxyv2: $(ISTIO_ENVOY_LINUX_RELEASE_DIR)/envoy
docker.proxyv2: $(ISTIO_OUT_LINUX)/pilot-agent
docker.proxyv2: pilot/docker/Dockerfile.proxyv2
docker.proxyv2: pilot/docker/envoy_pilot.yaml.tmpl
docker.proxyv2: pilot/docker/envoy_policy.yaml.tmpl
docker.proxyv2: tools/packaging/common/istio-iptables.sh
docker.proxyv2: pilot/docker/envoy_telemetry.yaml.tmpl
	$(DOCKER_RULE)

# Proxy using TPROXY interception - but no core dumps
docker.proxytproxy: BUILD_ARGS=--build-arg proxy_version=istio-proxy:${PROXY_REPO_SHA} --build-arg istio_version=${VERSION} --build-arg ISTIO_API_SHA=${ISTIO_PROXY_ISTIO_API_SHA_LABEL} --build-arg ENVOY_SHA=${ISTIO_PROXY_ENVOY_SHA_LABEL} --build-arg BASE_VERSION=${BASE_VERSION}
docker.proxytproxy: tools/packaging/common/envoy_bootstrap_v2.json
docker.proxytproxy: tools/packaging/common/envoy_bootstrap_drain.json
docker.proxytproxy: install/gcp/bootstrap/gcp_envoy_bootstrap.json
docker.proxytproxy: $(ISTIO_DOCKER)/ca-certificates.tgz
docker.proxytproxy: $(ISTIO_ENVOY_LINUX_RELEASE_DIR)/envoy
docker.proxytproxy: $(ISTIO_OUT_LINUX)/pilot-agent
docker.proxytproxy: pilot/docker/Dockerfile.proxytproxy
docker.proxytproxy: pilot/docker/envoy_pilot.yaml.tmpl
docker.proxytproxy: pilot/docker/envoy_policy.yaml.tmpl
docker.proxytproxy: tools/packaging/common/istio-iptables.sh
docker.proxytproxy: pilot/docker/envoy_telemetry.yaml.tmpl
	$(DOCKER_RULE)

docker.pilot: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.pilot: $(ISTIO_OUT_LINUX)/pilot-discovery
docker.pilot: tests/testdata/certs/cacert.pem
docker.pilot: pilot/docker/Dockerfile.pilot
	$(DOCKER_RULE)

# Test application
docker.app: pkg/test/echo/docker/Dockerfile.app
docker.app: $(ISTIO_OUT_LINUX)/pkg-test-echo-cmd-client
docker.app: $(ISTIO_OUT_LINUX)/pkg-test-echo-cmd-server
docker.app: $(ISTIO_DOCKER)/certs
	mkdir -p $(ISTIO_DOCKER)/testapp
	cp -r $^ $(ISTIO_DOCKER)/testapp
ifeq ($(DEBUG_IMAGE),1)
	# It is extremely helpful to debug from the test app. The savings in size are not worth the
	# developer pain
	cp $(ISTIO_DOCKER)/testapp/Dockerfile.app $(ISTIO_DOCKER)/testapp/Dockerfile.appdbg
	sed -e "s,FROM \${BASE_DISTRIBUTION},FROM $(HUB)/proxy_debug:$(TAG)," $(ISTIO_DOCKER)/testapp/Dockerfile.appdbg > $(ISTIO_DOCKER)/testapp/Dockerfile.appd
endif
	time (cd $(ISTIO_DOCKER)/testapp && \
		docker build -t $(HUB)/app:$(TAG) -f Dockerfile.app .)


# Test application bundled with the sidecar (for non-k8s).
docker.app_sidecar: tools/packaging/common/envoy_bootstrap_v2.json
docker.app_sidecar: tools/packaging/common/envoy_bootstrap_drain.json
docker.app_sidecar: tools/packaging/common/istio-iptables.sh
docker.app_sidecar: tools/packaging/common/istio-start.sh
docker.app_sidecar: tools/packaging/common/istio-node-agent-start.sh
docker.app_sidecar: tools/packaging/deb/postinst.sh
docker.app_sidecar: pkg/test/echo/docker/echo-start.sh
docker.app_sidecar: $(ISTIO_DOCKER)/ca-certificates.tgz
docker.app_sidecar: $(ISTIO_DOCKER)/certs
docker.app_sidecar: $(ISTIO_ENVOY_LINUX_RELEASE_DIR)/envoy
docker.app_sidecar: $(ISTIO_OUT_LINUX)/pilot-agent
docker.app_sidecar: $(ISTIO_OUT_LINUX)/node_agent
docker.app_sidecar: $(ISTIO_OUT_LINUX)/pkg-test-echo-cmd-client
docker.app_sidecar: $(ISTIO_OUT_LINUX)/pkg-test-echo-cmd-server
docker.app_sidecar: pkg/test/echo/docker/Dockerfile.app_sidecar
docker.app_sidecar: pilot/docker/envoy_pilot.yaml.tmpl
docker.app_sidecar: pilot/docker/envoy_policy.yaml.tmpl
docker.app_sidecar: pilot/docker/envoy_telemetry.yaml.tmpl
	$(DOCKER_RULE)

# Test policy backend for mixer integration
docker.test_policybackend: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.test_policybackend: mixer/docker/Dockerfile.test_policybackend
docker.test_policybackend: $(ISTIO_OUT_LINUX)/mixer-test-policybackend
	$(DOCKER_RULE)

docker.kubectl: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.kubectl: docker/Dockerfile$$(suffix $$@)
	$(DOCKER_RULE)

# mixer docker images

docker.mixer: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.mixer: mixer/docker/Dockerfile.mixer
docker.mixer: $(ISTIO_DOCKER)/mixs
docker.mixer: $(ISTIO_DOCKER)/ca-certificates.tgz
	$(DOCKER_RULE)

# mixer codegen docker images
docker.mixer_codegen: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.mixer_codegen: mixer/docker/Dockerfile.mixer_codegen
docker.mixer_codegen: $(ISTIO_DOCKER)/mixgen
	$(DOCKER_RULE)

# galley docker images

docker.galley: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.galley: galley/docker/Dockerfile.galley
docker.galley: $(ISTIO_DOCKER)/galley
	$(DOCKER_RULE)

# security docker images

docker.citadel: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.citadel: security/docker/Dockerfile.citadel
docker.citadel: $(ISTIO_DOCKER)/istio_ca
docker.citadel: $(ISTIO_DOCKER)/ca-certificates.tgz
	$(DOCKER_RULE)

docker.citadel-test: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.citadel-test: security/docker/Dockerfile.citadel-test
docker.citadel-test: $(ISTIO_DOCKER)/istio_ca
docker.citadel-test: $(ISTIO_DOCKER)/istio_ca.crt
docker.citadel-test: $(ISTIO_DOCKER)/istio_ca.key
	$(DOCKER_RULE)

docker.node-agent: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.node-agent: security/docker/Dockerfile.node-agent
docker.node-agent: $(ISTIO_DOCKER)/node_agent
	$(DOCKER_RULE)

docker.node-agent-k8s: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.node-agent-k8s: security/docker/Dockerfile.node-agent-k8s
docker.node-agent-k8s: $(ISTIO_DOCKER)/node_agent_k8s
	$(DOCKER_RULE)

docker.node-agent-test: BUILD_ARGS=--build-arg BASE_VERSION=${BASE_VERSION}
docker.node-agent-test: security/docker/Dockerfile.node-agent-test
docker.node-agent-test: $(ISTIO_DOCKER)/node_agent
docker.node-agent-test: $(ISTIO_DOCKER)/istio_ca.crt
docker.node-agent-test: $(ISTIO_DOCKER)/node_agent.crt
docker.node-agent-test: $(ISTIO_DOCKER)/node_agent.key
	$(DOCKER_RULE)

docker.base: docker/Dockerfile.base
	$(DOCKER_RULE)

# $@ is the name of the target
# $^ the name of the dependencies for the target
# Rule Steps #
##############
# 1. Make a directory $(DOCKER_BUILD_TOP)/%@
# 2. This rule uses cp to copy all dependency filenames into into $(DOCKER_BUILD_TOP/$@
# 3. This rule then changes directories to $(DOCKER_BUID_TOP)/$@
# 4. This rule runs $(BUILD_PRE) prior to any docker build and only if specified as a dependency variable
# 5. This rule finally runs docker build passing $(BUILD_ARGS) to docker if they are specified as a dependency variable

# DOCKER_BUILD_VARIANTS ?=default distroless
DOCKER_BUILD_VARIANTS ?=default
DEFAULT_DISTRIBUTION=default
DOCKER_RULE=$(foreach VARIANT,$(DOCKER_BUILD_VARIANTS), time (mkdir -p $(DOCKER_BUILD_TOP)/$@ && cp -r $^ $(DOCKER_BUILD_TOP)/$@ && cd $(DOCKER_BUILD_TOP)/$@ && $(BUILD_PRE) docker build $(BUILD_ARGS) --build-arg BASE_DISTRIBUTION=$(VARIANT) -t $(HUB)/$(subst docker.,,$@):$(subst -$(DEFAULT_DISTRIBUTION),,$(TAG)-$(VARIANT)) -f Dockerfile$(suffix $@) . ); )

# This target will package all docker images used in test and release, without re-building
# go binaries. It is intended for CI/CD systems where the build is done in separate job.
docker.all: $(DOCKER_TARGETS)

# for each docker.XXX target create a tar.docker.XXX target that says how
# to make a $(ISTIO_OUT_LINUX)/docker/XXX.tar.gz from the docker XXX image
# note that $(subst docker.,,$(TGT)) strips off the "docker." prefix, leaving just the XXX

# create a DOCKER_TAR_TARGETS that's each of DOCKER_TARGETS with a tar. prefix
DOCKER_TAR_TARGETS:=
$(foreach TGT,$(filter-out docker.app,$(DOCKER_TARGETS)),$(eval tar.$(TGT): $(TGT) | $(ISTIO_DOCKER_TAR) ; \
         $(foreach VARIANT,$(DOCKER_BUILD_VARIANTS), time ( \
		     docker save -o ${ISTIO_DOCKER_TAR}/$(subst docker.,,$(TGT))$(subst -$(DEFAULT_DISTRIBUTION),,-$(VARIANT)).tar $(HUB)/$(subst docker.,,$(TGT)):$(subst -$(DEFAULT_DISTRIBUTION),,$(TAG)-$(VARIANT)) && \
             gzip ${ISTIO_DOCKER_TAR}/$(subst docker.,,$(TGT))$(subst -$(DEFAULT_DISTRIBUTION),,-$(VARIANT)).tar \
			   ); \
		  )))

tar.docker.app: docker.app | $(ISTIO_DOCKER_TAR)
	time ( docker save -o ${ISTIO_DOCKER_TAR}/app.tar $(HUB)/app:$(TAG) && \
             gzip ${ISTIO_DOCKER_TAR}/app.tar )

# create a DOCKER_TAR_TARGETS that's each of DOCKER_TARGETS with a tar. prefix DOCKER_TAR_TARGETS:=
$(foreach TGT,$(DOCKER_TARGETS),$(eval DOCKER_TAR_TARGETS+=tar.$(TGT)))

# this target saves a tar.gz of each docker image to ${ISTIO_OUT_LINUX}/docker/
docker.save: $(DOCKER_TAR_TARGETS)

# for each docker.XXX target create a push.docker.XXX target that pushes
# the local docker image to another hub
# a possible optimization is to use tag.$(TGT) as a dependency to do the tag for us
$(foreach TGT,$(filter-out docker.app,$(DOCKER_TARGETS)),$(eval push.$(TGT): | $(TGT) ; \
	time (set -e && for distro in $(DOCKER_BUILD_VARIANTS); do tag=$(TAG)-$$$${distro}; docker push $(HUB)/$(subst docker.,,$(TGT)):$$$${tag%-$(DEFAULT_DISTRIBUTION)}; done)))

push.docker.app: docker.app
	time (docker push $(HUB)/app:$(TAG))

define run_vulnerability_scanning
        $(eval RESULTS_DIR := vulnerability_scan_results)
        $(eval CURL_RESPONSE := $(shell curl -s --create-dirs -o $(RESULTS_DIR)/$(1) -w "%{http_code}" http://imagescanner.cloud.ibm.com/scan?image="docker.io/$(2)")) \
        $(if $(filter $(CURL_RESPONSE), 200), (mv $(RESULTS_DIR)/$(1) $(RESULTS_DIR)/$(1).json))
endef

# create a DOCKER_PUSH_TARGETS that's each of DOCKER_TARGETS with a push. prefix
DOCKER_PUSH_TARGETS:=
$(foreach TGT,$(DOCKER_TARGETS),$(eval DOCKER_PUSH_TARGETS+=push.$(TGT)))

# Will build and push docker images.
docker.push: $(DOCKER_PUSH_TARGETS)

# Scan images for security vulnerabilities using the ImageScanner tool
docker.scan_images: $(DOCKER_PUSH_TARGETS)
	$(foreach TGT,$(DOCKER_TARGETS),$(call run_vulnerability_scanning,$(subst docker.,,$(TGT)),$(HUB)/$(subst docker.,,$(TGT)):$(TAG)))

# Base image for 'debug' containers.
# You can run it first to use local changes (or guarantee it is built from scratch)
docker.basedebug:
	docker build -t istionightly/base_debug -f docker/Dockerfile.xenial_debug docker/

# Run this target to generate images based on Bionic Ubuntu
# This must be run as a first step, before the 'docker' step.
docker.basedebug_bionic:
	docker build -t istionightly/base_debug_bionic -f docker/Dockerfile.bionic_debug docker/
	docker tag istionightly/base_debug_bionic istionightly/base_debug

# Run this target to generate images based on Debian Slim
# This must be run as a first step, before the 'docker' step.
docker.basedebug_deb:
	docker build -t istionightly/base_debug_deb -f docker/Dockerfile.deb_debug docker/
	docker tag istionightly/base_debug_deb istionightly/base_debug

# Job run from the nightly cron to publish an up-to-date xenial with the debug tools.
docker.push.basedebug: docker.basedebug
	docker push istionightly/base_debug:latest

# Build a dev environment Docker image.
DEV_IMAGE_NAME = istio/dev:$(USER)
DEV_CONTAINER_NAME = istio-dev
DEV_GO_VERSION = 1.12.5
tools/docker-dev/image-built: tools/docker-dev/Dockerfile
	@echo "building \"$(DEV_IMAGE_NAME)\" Docker image"
	@docker build \
		--build-arg goversion="$(DEV_GO_VERSION)" \
		--build-arg user="${shell id -un}" \
		--build-arg group="${shell id -gn}" \
		--build-arg uid="${shell id -u}" \
		--build-arg gid="${shell id -g}" \
		--tag "$(DEV_IMAGE_NAME)" - < tools/docker-dev/Dockerfile
	@touch $@

# Start a dev environment Docker container.
.PHONY = dev-shell clean-dev-shell
dev-shell: tools/docker-dev/image-built
	@if test -z "$(shell docker ps -a -q -f name=$(DEV_CONTAINER_NAME))"; then \
	    echo "starting \"$(DEV_CONTAINER_NAME)\" Docker container"; \
		docker run --detach \
			--name "$(DEV_CONTAINER_NAME)" \
			--volume "$(GOPATH):/home/$(USER)/go:consistent" \
			--volume "$(HOME)/.config/gcloud:/home/$(USER)/.config/gcloud:cached" \
			--volume "$(HOME)/.kube:/home/$(USER)/.kube:cached" \
			--volume /var/run/docker.sock:/var/run/docker.sock \
			"$(DEV_IMAGE_NAME)" \
			'while true; do sleep 60; done';  fi
	@echo "executing shell in \"$(DEV_CONTAINER_NAME)\" Docker container"
	@docker exec --tty --interactive "$(DEV_CONTAINER_NAME)" /bin/bash

clean-dev-shell:
	docker rm -f "$(DEV_CONTAINER_NAME)" || true
	if test -n "$(shell docker images -q $(DEV_IMAGE_NAME))"; then \
		docker rmi -f "$(shell docker images -q $(DEV_IMAGE_NAME))" || true; fi
	rm -f tools/docker-dev/image-built
