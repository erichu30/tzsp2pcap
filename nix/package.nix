{ lib, stdenv, libpcap, pkg-config }:

stdenv.mkDerivation rec {
  name = "tzsp2pcap";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [ ../Makefile ../tzsp2pcap.c ../COPYING ];
  };

  buildInputs = [ libpcap ];
  nativeBuildInputs = [ pkg-config ];

  preBuild = lib.optionalString stdenv.hostPlatform.isStatic ''
    makeFlagsArray+=("LIBS=$($PKG_CONFIG --libs --static libpcap)")
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 tzsp2pcap $out/bin/tzsp2pcap
    runHook postInstall
  '';
}
