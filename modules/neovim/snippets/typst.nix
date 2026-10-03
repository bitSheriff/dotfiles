[

  {
    trigger = "h1";
    body = "= $1";
  }
  {
    trigger = "h2";
    body = "== $1";
  }
  {
    trigger = "h3";
    body = "=== $1";
  }
  {
    trigger = "h4";
    body = "==== $1";
  }
  {
    trigger = "h5";
    body = "===== $1";
  }
  {
    trigger = "lnk";
    body = "#link($1)[$2]";
  }
  {
    trigger = "mb";
    description = "Math Block";
    body = ''
      \$
      $1
      \$
    '';
  }
  {
    trigger = "img";
    description = "Simple Image";
    body = ''
      #figure(
        image("$1", width: 100%),
        caption: [$2],
      )

    '';
  }
  {
    trigger = "fig";
    description = "Simple Figure";
    body = ''
      #figure(
        "$1",
        caption: [$2],
      )

    '';
  }
]
