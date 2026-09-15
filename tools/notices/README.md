# Maintaining third-party notices

The release-preparation PR should update `versions.mk`, dependencies and the
runtime Dockerfile first, then run `make notices` and `make notices-check`.
Review and commit the generated `THIRD_PARTY_NOTICES.md` with those inputs before
creating a release tag. Do not automatically choose a new semantic version on
every image build. The release owner selects it; release CI verifies tag equality.

The generator unions both supported runtime package graphs, retains reviewed
supplements and shipped `pci.ids`, and derives license references from the
selected modules' versions and legal files. New upstream repository mappings
and changed reviewed licensing/copyright metadata require review. Generation is
not an automatic legal approval of new dependencies.

Image CI regenerates into a temporary file and fails before building/pushing if
the committed notice differs. The existing Dockerfile copies that reviewed file
to `/licenses/THIRD_PARTY_NOTICES.md`. Release CI repeats the freshness check
before uploading the committed file. These checks prevent stale inputs; they do
not prove that a separately promoted registry image matches the release commit.

Normal release uploads deliberately omit `--clobber`. If a notice asset already
exists, the upload fails without replacing it, including on workflow reruns.
Historical corrections require a separate reviewed publication operation.
Older workflow revisions may still contain `--clobber`; do not rerun them to
repair or validate an existing release attachment.

## Correcting the already released v1.6.0

Prepare the correction against source commit
`d26f2374d3c3f4785f52689cf954d1eea6202fb5`, not an unverified local tag or latest
development dependencies. The reviewed image index is:

```text
nvcr.io/nvidia/kubevirt-gpu-device-plugin@sha256:367c597799aa6925f5bd2bc4bcdc45c26f018d13cdc2ce9aaf1ca07c492c6d9e
```

Its runtime base was identified as distroless Go v4.1.1 on both platforms.
The generator now derives the version-specific source index from the runtime
Dockerfile rather than writing v4.0.2 independently.

Before publication, independently recheck the release digest, source provenance,
dependency inventory, and per-platform embedded notice. Review coverage of Go
standard-library code, native code and base-image licenses separately: the
application-module summary and the base source index alone are not a complete
base-image legal review.

After approval, publish a corrected external notice with its SHA-256, the above
image digest, and a release-note explanation that it supersedes the previous
downloadable notice. Do not rerun the old tag's upload workflow expecting it to
use the correction: that workflow checks out the original tagged source.
Do not move the existing release tag to make the correction available.

Updating a GitHub release attachment cannot change the embedded notice. Ship a
new reviewed image revision/digest to correct `/licenses/THIRD_PARTY_NOTICES.md`,
extract the notice from each published platform image and compare its SHA-256
with the approved release attachment. Record the old/new digest relationship;
do not silently overwrite v1.6.0. Publishing and selecting a replacement release
version are separate release-owner actions, not performed by local generation.
