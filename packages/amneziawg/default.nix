{ linuxPackages }:

let
  patchModule =
    module:
    module.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [ ./ipv6-api-linux-7.1.patch ];
    });
in
(patchModule linuxPackages.amneziawg).overrideAttrs (oldAttrs: {
  passthru = (oldAttrs.passthru or { }) // {
    # Consumers with a non-default kernel must build the module against the
    # matching kernel package set.
    withKernel = kernelPackages: patchModule kernelPackages.amneziawg;
  };
})
