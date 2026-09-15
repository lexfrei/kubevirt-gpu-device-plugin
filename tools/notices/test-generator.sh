#!/usr/bin/env bash
# Copyright (c) 2026 NVIDIA CORPORATION. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/../.."
source tools/generate-notices.sh
WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT
MODULE_INDEX="${WORK_DIR}/modules.csv"
VERSIONS_MK="${WORK_DIR}/versions.mk"
DOCKERFILE="${WORK_DIR}/Dockerfile"
printf '%s\n' 'VERSION ?= v1.6.0' > "${VERSIONS_MK}"
printf '%s\n' 'FROM builder:example AS builder' 'FROM nvcr.io/nvidia/distroless/go:v4.1.1' > "${DOCKERFILE}"
resolve_release_metadata
[[ "${RELEASE_VERSION}" == v1.6.0 ]]
[[ "${BASE_IMAGE_VERSION}" == v4.1.1 ]]
[[ "${BASE_SOURCE_URL}" == */go/v4.1.1/index.html ]]
(
    module_version() { printf '%s\n' v1.36.12-0.20260120151049-f2248ac996af; }
    [[ "$(module_source_base google.golang.org/protobuf)" == */blob/f2248ac996af/ ]]
)

# Fixture inventory deliberately omits most modules. IDs must remain complete
# and a component with multiple legal files must reference every file.
printf '%s\n' 'go.yaml.in/yaml/v3,Apache-2.0 AND MIT,fixture' > "${MODULE_INDEX}"
build_license_references
[[ "$(references_for_module go.yaml.in/yaml/v3)" == 'L01a, L01b' ]]
[[ "$(references_for_module pci.ids)" == L02 ]]
emit_license_file_references | grep '/NOTICE' >/dev/null

# Adding a module and changing its version must affect both rendered outputs.
printf '%s\n' 'github.com/fsnotify/fsnotify,BSD-3-Clause,fixture' >> "${MODULE_INDEX}"
module_version() { printf '%s\n' v9.9.9; }
build_license_references
[[ "$(references_for_module github.com/fsnotify/fsnotify)" == L02 ]]
[[ "$(references_for_module pci.ids)" == L03 ]]
emit_index | grep 'v9.9.9' >/dev/null
emit_license_file_references | grep 'fsnotify/blob/v9.9.9/LICENSE' >/dev/null

# Unreviewed repositories and unversioned bases must fail closed.
if (module_source_base example.invalid/new-module) 2>/dev/null; then
    die 'unreviewed module was accepted'
fi
DOCKERFILE="${WORK_DIR}/Dockerfile"
printf '%s\n' 'FROM nvcr.io/nvidia/distroless/go:latest' > "${DOCKERFILE}"
if (resolve_release_metadata) 2>/dev/null; then
    die 'unversioned base was accepted'
fi
printf '%s\n' 'Notice generator regression tests passed.'
