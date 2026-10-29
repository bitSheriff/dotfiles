let
  banned_words = ''
    delve, tapestry, meticulous, pivotal, intricate,
    interplay, underscore, garner, bolster, vibrant, bustling, multifaceted, seamless, commendable, ever-evolving, realm, landscape (figurative), testament, showcase, foster, harness (verb), unlock (figurative), elevate, embark, navigate (figurative), robust, crucial, essential, profound, nuanced, holistic, myriad, plethora, leverage (verb).
  '';

  writing_style = ''
    ## Writing Style
    Do not use emdashes or emojis.

    ### Banned Words
    Please do not use the following words, because they do sound too much AI:
    ${banned_words}
  '';

  coding_style = ''
    ## Coding Style
    ### Comments and Documentary
    - Minimalism is Mandatory: Write terse, pragmatic documentation. Do NOT generate extensive, verbose docstrings, module-level essays, or line-by-line comments.
    - Self-Documenting Code First: Rely on expressive variable/function naming and clean architecture instead of comments. Only comment on why a specific implementation choice was made or to explain highly unconventional logic. Never comment on what obvious code is doing.
    - Zero AI Fluff: Completely eliminate overly descriptive, academic, or stereotypical AI vocabulary (e.g., "This robust function ensures...", "Crucial for...", "Delve into"). Strip out all conversational filler, introductory summaries, and concluding remarks.
    - Standardized Brevity: When a docstring is strictly required for public APIs, limit it to a single, direct sentence describing the primary behavior or return value. Omit boilerplate tags for trivial parameters.
    - Senior Engineer Persona: Write code and comments like a seasoned developer submitting a professional pull request—pragmatic, laser-focused, and completely devoid of unnecessary hand-holding or filler.

    ### Language Specifics
    #### Nix
    If you write extentions, scripts or derivations for a `flake.nix` and those modules get too big, move them to a seperate file located in the `.nix/` directory side-by-side to the flake.nix. Include those files later in the `flake.nix` so it does not get too big and one might lose the overview.

    Furher it is important, that the `flake.nix` always works. So if the build-tools, targets or something else is changed, the `flake.nix` (or other nix files) should be updated immediatly as well. They should be the single-source-of-truth.

    If you write as shell-script inside nix, always use `writeShellApplication` with all its dependencies so it works even if the nix devShell is not active.
    Always start from a _pure_ perspective, declare all dependencies if needed.
  '';
in
''
  # Global Context

  ${coding_style}

  ${writing_style}

''
