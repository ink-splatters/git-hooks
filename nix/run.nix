{ tools, pre-commit, git, runCommand, writeText, writeScript }:

{ src
, hooks ? null
}:

let
  # https://github.com/tweag/ormolu/issues/311
  ormoluCmd = writeScript "ormolu-pre-commit-check" ''
    #!/usr/bin/env bash
    for f in "$@"; do
      ${tools.ormolu}/bin/ormolu --mode inplace $f
    done
  '';
  hooksYaml = writeText "pre-commit-hooks" ''
  -   id: hlint
      name: hlint
      description: HLint gives suggestions on how to improve your source code.
      entry: ${tools.hlint}/bin/hlint
      language: system
      files: '\.l?hs$'
  -   id: ormolu
      name: ormolu
      description: Haskell code prettifier.
      entry: ${ormoluCmd}
      language: script
      files: '\.l?hs$'
  -   id: cabal-fmt
      name: cabal-fmt
      description: Format Cabal files
      entry: cabal-fmt --inplace
      language: system
      files: '\.cabal$'
  -   id: canonix
      name: canonix
      description: Nix code prettifier.
      entry: ${tools.canonix}/bin/canonix
      language: system
      files: '\.nix$'
  -   id: elm-format
      name: elm-format
      description: Format Elm files
      entry: ${tools.elm-format}/bin/elm-format --yes --elm-version=0.19
      language: system
      files: \.elm$
  -   id: shellcheck
      name: shellcheck
      description: Format shell files
      types: [bash]
      entry: ${tools.shellcheck}/bin/shellcheck
      language: system
  '';

  hooks = runCommand "pre-commit-hooks-dir" { buildInputs = [git]; } ''
    HOME=$PWD
    mkdir -p $out
    ln -s ${hooksYaml} $out/.pre-commit-hooks.yaml
    cd $out
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    git init
    git add .
    git commit -m "init"
  '';

  run = runCommand "pre-commit-run" { buildInputs = [git]; } ''
    HOME=$PWD
    ln -s ${hooksYaml} .pre-commit-hooks
    cp --no-preserve=mode -R ${src} src
    ln -s ${hooks} src/.pre-commit-hooks
    cd src
    rm -rf src/.git/*
    git init
    echo "Running: $ pre-commit run --all-files"
    ${pre-commit}/bin/pre-commit run --all-files
  '';
in run // {
  shellHook = ''
    ln -s ${hooks} .pre-commit-hooks
    export PATH=$PATH:${pre-commit}
    pre-commit install
  '';
}
