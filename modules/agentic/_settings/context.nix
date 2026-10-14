let
  banned_words = ''
    Please do not use the following words, because they do sound too much AI: delve, tapestry, meticulous, pivotal, intricate,
    interplay, underscore, garner, bolster, vibrant, bustling, multifaceted, seamless, commendable, ever-evolving, realm, landscape (figurative), testament, showcase, foster, harness (verb), unlock (figurative), elevate, embark, navigate (figurative), robust, crucial, essential, profound, nuanced, holistic, myriad, plethora, leverage (verb).
  '';
in
{
  globalContext = ''
    # Global Context

    ## Banned Words and Phrases
    ${banned_words}
  '';
}
