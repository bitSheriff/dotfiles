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
  '';
in
''
  # Global Context

  ${coding_style}

  ${writing_style}

''
