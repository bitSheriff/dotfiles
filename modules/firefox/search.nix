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
    "Ocean Of Pdf" = {
      definedAliases = [ "@op" ];
      urls = [
        {
          template = "https://oceanofpdf.com";
          params = [
            {
              name = "s";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
    # https://mynixos.com/search?q
    "My Nixos" = {
      definedAliases = [ "@mn" ];
      urls = [
        {
          template = "https://mynixos.com/search";
          params = [
            {
              name = "q";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
    # https://www.flipkart.com/search?q=searchTerms
    "Flipkart" = {
      definedAliases = [ "@fk" ];
      urls = [
        {
          template = "https://www.flipkart.com/search";
          params = [
            {
              name = "q";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
    # https://www.amazon.in/s?k=searchTerms
    "Amazon" = {
      definedAliases = [ "@am" ];
      urls = [
        {
          template = "https://www.amazon.in/s";
          params = [
            {
              name = "k";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
    # https://hslpicker.com/#ff7575
    "hslpicker" = {
      definedAliases = [ "@hex" ];
      urls = [
        {
          template = "https://hslpicker.com/";
          params = [
            {
              name = "k";
              value = "{searchTerms}";
            }
          ];
        }
      ];
    };
  };
}
