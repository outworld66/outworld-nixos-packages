{ sing-box }:

sing-box.overrideAttrs (old: {
  # Keep REALITY compatible with Xray 26.9.8+ until the upstream fix ships.
  patches = (old.patches or [ ]) ++ [ ./reality-mlkem-keyshare.patch ];
})
