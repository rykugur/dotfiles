{ config
, lib
, inputs
, stdenv
, ...
}: {
  stdenv.mkDerivatikon {
  name = "pyfa";
  src = fetchzip {
    url = "";
    sha256 = lib.fakeSha256;
  };
}
}
