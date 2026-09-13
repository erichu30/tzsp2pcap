# Build and release

Local builds and GitHub Actions both run `nix-build nix/release.nix` inside
Docker. Actions uses native Linux amd64 and arm64 runners. The release
expression pins Nixpkgs and uses `pkgsStatic`,
so the distributed executable does not require Nix or a shared libpcap.
The existing `nix-build` entry point remains available for a regular build
using your configured Nixpkgs.

## Local builds

With Docker Buildx, build both Linux release archives locally. Nix does not
need to be installed on the host:

```sh
sh scripts/build-release.sh amd64
sh scripts/build-release.sh arm64
```

Docker must support the requested architecture (native execution or emulation).
Actions runs these exact scripts and the same Dockerfile. They produce
`dist/tzsp2pcap-linux-amd64.tar.gz` and `dist/tzsp2pcap-linux-arm64.tar.gz`.
Each archive contains the executable and its license. Build outputs are ignored
by Git. Only arm64 verifies the `-R BYTES` help text and executes the binary
in a scratch image with no Nix store or shared libraries.

The Dockerfile also retains a Debian build test with `build-essential`,
`libpcap-dev`, `git`, and `ca-certificates`:

```sh
docker buildx build --platform linux/amd64 --target build-test .
docker buildx build --platform linux/arm64 --target build-test .
```

Both compile with `make`; only arm64 executes `./tzsp2pcap -h` and checks
the `-R BYTES` help text. The `binary` target exports this dynamically linked
Debian binary; the `release` target exports the static Nix binary.

## GitHub Actions

Pull requests, pushes to `master`, and manual runs build both architectures
and retain the archives as workflow artifacts. Verification is part of the
Docker build, so local builds and Actions perform the same checks.

Pushing a `v*` tag builds both architectures and then creates a GitHub Release
(or updates assets on an existing release). The assets are:

- `tzsp2pcap-linux-amd64.tar.gz`
- `tzsp2pcap-linux-arm64.tar.gz`
- `SHA256SUMS`

Only the release job receives `contents: write`. A failed build prevents release
publication. A rerun replaces assets for the same tag.

After merging the workflow, publish a version from the intended commit:

```sh
git tag v1.0.0
git push origin v1.0.0
```

Choose the actual version before running those commands. No tag is created by
normal branch pushes or manual build runs.
