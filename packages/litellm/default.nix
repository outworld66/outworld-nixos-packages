{
  lib,
  python3Packages,
  prisma_6,
  prisma-engines_6,
}:

let
  litellm = python3Packages.litellm.overridePythonAttrs (old: {
    # The ungenerated dependency would shadow the client bundled below.
    dependencies = builtins.filter (package: (package.pname or "") != "prisma") (
      (old.dependencies or [ ])
      ++ litellm.optional-dependencies.proxy
      ++ litellm.optional-dependencies.extra_proxy
      ++ litellm.optional-dependencies.proxy-runtime
    );
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      prisma_6
      python3Packages.prisma
    ];
    postInstall = (old.postInstall or "") + ''
      schema="$out/${python3Packages.python.sitePackages}/litellm/proxy/schema.prisma"
      cp "$schema" /build/litellm-schema.prisma
      prisma_output="$TMPDIR/litellm-prisma"
      mkdir "$prisma_output"
      prisma_python="$TMPDIR/prisma-python"
      mkdir "$prisma_python"
      cp -r "${python3Packages.prisma}/${python3Packages.python.sitePackages}/prisma" "$prisma_python/"
      chmod -R u+w "$prisma_python/prisma"
      ${python3Packages.python}/bin/python3 - "$prisma_python/prisma/generator/generator.py" <<'PY'
      import pathlib
      import sys

      generator = pathlib.Path(sys.argv[1])
      source = generator.read_text()
      source = source.replace(
          'packaged_schema.write_text(data.datamodel)',
          'if packaged_schema.exists():\n                packaged_schema.chmod(0o644)\n            packaged_schema.write_text(data.datamodel)',
      )
      generator.write_text(source)
      PY
      ${python3Packages.python}/bin/python3 - \
        /build/litellm-schema.prisma "$prisma_output" <<'PY'
      import pathlib
      import sys

      schema = pathlib.Path(sys.argv[1])
      schema.write_text(schema.read_text().replace(
          'provider = "prisma-client-py"',
          f'provider = "prisma-client-py"\n  output = "{sys.argv[2]}"',
          1,
      ))
      PY
      export PRISMA_QUERY_ENGINE_BINARY=${prisma-engines_6}/bin/query-engine
      export PRISMA_QUERY_ENGINE_LIBRARY=${lib.getLib prisma-engines_6}/lib/libquery_engine.node
      export PRISMA_SCHEMA_ENGINE_BINARY=${prisma-engines_6}/bin/schema-engine
      export PRISMA_EXPECTED_ENGINE_VERSION=c2990dca591cba766e3b7ef5d9e8a84796e47ab7
      export PYTHONPATH="$prisma_python''${PYTHONPATH:+:$PYTHONPATH}"
      ${prisma_6}/bin/prisma generate \
        --schema=/build/litellm-schema.prisma
      cp -r "$prisma_output" "$out/${python3Packages.python.sitePackages}/prisma"
      chmod -R go-w "$out/${python3Packages.python.sitePackages}/prisma"
    '';
  });
in
python3Packages.toPythonApplication litellm
