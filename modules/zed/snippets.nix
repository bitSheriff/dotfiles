{
  config,
  pkgs,
  ...
}:

let
  rust = {
    "Dead Code" = {
      prefix = "dead code";
      body = "#[allow(dead_code)]";
      description = "Allow dead code, not used function ...";
    };
  };

  cpp = {
    "Doxygen Function" = {
      prefix = "doxy function";
      description = "Template for a doxygen block";
      body = [
        "/**"
        " * @brief ${"1:Description"}"
        " *"
        " * @param ${"2:Param"}"
        " *"
        " * @return ${"3:Return"}"
        " */"
      ];
    };
  };

  markdown = {
    "Todo" = {
      prefix = "todo";
      body = "- [ ] ";
    };

  };

in
{
  home-manager.users.benjamin = {
    home.file.".config/zed/snippets/rust.json".text = builtins.toJSON rust;
    home.file.".config/zed/snippets/c.json".text = builtins.toJSON cpp;
    home.file.".config/zed/snippets/markdown.json".text = builtins.toJSON markdown;
  };
}
