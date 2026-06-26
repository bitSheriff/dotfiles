{
  default = "ddg";
  privateDefault = "ddg";
  engines = {
    "Nix Packages" = {
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      definedAliases = [ "@np" ];
    };
    "Nix Options" = {
      definedAliases = [ "@no" ];
      urls = [
        {
          template = "https://search.nixos.org/options";
          params = [
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };

    # https://www.amazon.de/s?k=searchTerms
    "Amazon" = {
      definedAliases = [ "@am" ];
      urls = [
        {
          template = "https://www.amazon.de/s";
          params = [
            {
              name = "k";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };

    "GitHub" = {
      definedAliases = [ "@gh" ];
      urls = [
        {
          template = "https://github.com/search";
          params = [
            {
              name = "q";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
  };
}
