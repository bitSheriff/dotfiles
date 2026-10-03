[

  {
    trigger = "h1";
    body = "# $1";
  }
  {
    trigger = "h2";
    body = "## $1";
  }
  {
    trigger = "h3";
    body = "### $1";
  }
  {
    trigger = "h4";
    body = "#### $1";
  }
  {
    trigger = "h5";
    body = "#### $1";
  }
  {
    trigger = "callout";
    body = ''
      > [!NOTE]
      > $1
    '';
  }
  {
    trigger = "cmt";
    body = "<!-- $1 -->";
    description = "Comment";
  }
  {
    trigger = "td";
    body = "- [ ] $1";
  }
  {
    trigger = "lnk";
    body = "[$1]($2)";
  }
  {
    trigger = "cb";
    description = "Code Block";
    body = ''
      ```
      $1
      ```
    '';
  }
  {
    trigger = "mb";
    description = "Math Block";
    body = ''
      \$\$
      $1
      \$\$
    '';
  }
]
