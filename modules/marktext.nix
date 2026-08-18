{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:
let
  # MarkText preferences, written to ~/.config/marktext/preferences.json.
  # Defaults mirror the upstream schema; change only the values you need:
  # https://github.com/marktext/marktext/blob/develop/packages/desktop/src/main/preferences/schema.json
  preferences = {
    # General
    autoSave = false;
    autoSaveDelay = 5000;
    titleBarStyle = "custom";
    openFilesInNewWindow = false;
    openFolderInNewWindow = false;
    zoom = 1.0;
    hideScrollbar = true;
    wordWrapInToc = false;
    fileSortBy = "modified";
    fileSortOrder = "asc";
    # lastOpenedFolder has no default value
    startUpAction = "restoreAll";
    # defaultDirectoryToOpen has no default value
    language = "en";

    # Editor
    editorFontFamily = "Open Sans";
    fontSize = 16;
    lineHeight = 1.6;
    wrapCodeBlocks = true;
    editorLineWidth = "80%"; # maximum editor area width. empty string, suffixes of ch (characters), px (pixels) or % (percentage) are allowed
    codeFontSize = 14;
    codeFontFamily = "DejaVu Sans Mono";
    codeBlockLineNumbers = true;
    trimUnnecessaryCodeBlockEmptyLines = true;
    autoPairBracket = true;
    autoPairMarkdownSyntax = true;
    autoPairQuote = true;
    endOfLine = "default";
    defaultEncoding = "utf8";
    autoGuessEncoding = true;
    trimTrailingNewline = 2;
    textDirection = "ltr";
    hideQuickInsertHint = false;
    hideLinkPopup = false;
    autoCheck = false;

    # Markdown
    autoNormalizeLineEndings = false;
    preferLooseListItem = true;
    bulletListMarker = "-";
    orderListDelimiter = ".";
    preferHeadingStyle = "atx";
    tabSize = 4;
    listIndentation = 1;
    frontmatterType = "-";
    superSubScript = false;
    footnote = true;
    isHtmlEnabled = true;
    isGitlabCompatibilityEnabled = false;
    sequenceTheme = "hand";
    plantumlServer = "https://www.plantuml.com/plantuml";

    # Theme
    theme = "synthwave-84";
    followSystemTheme = false;
    lightModeTheme = "light";
    restoreLayoutState = true;
    darkModeTheme = "dark";
    customCss = "";

    # Spellchecker
    spellcheckerEnabled = false;
    spellcheckerNoUnderline = false;
    spellcheckerLanguage = "en-US";

    # Image
    imageInsertAction = "path";
    imagePreferRelativeDirectory = false;
    imageRelativeDirectoryBase = "file";
    imageRelativeDirectoryName = "assets";

    # Layout / view
    sideBarVisibility = false;
    tabBarVisibility = false;
    sourceCodeModeEnabled = false;
    openedFilesInSidebar = true;

    # Search / watcher
    searchExclusions = [ ];
    searchMaxFileSize = "";
    searchIncludeHidden = false;
    searchNoIgnore = false;
    searchFollowSymlinks = true;
    watcherUsePolling = false;
  };

  # MarkText (electron-store) rewrites preferences.json on startup (schema
  # migrations) and via the in-app settings UI, so the file must be writable.
  # A store symlink (xdg.configFile/home.file) is read-only and makes the app
  # crash with EROFS, so we seed a real, writable copy via activation instead.
  preferencesFile = pkgs.writeText "marktext-preferences.json" (builtins.toJSON preferences);
in
{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    marktext
  ];

  ##################
  ## HOME MANAGER ##
  ##################
  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    # Overwrite preferences.json on every rebuild with the declarative copy.
    # Trade-off: changes made in MarkText's own settings UI are reset on the
    # next `nixos-rebuild`. Manage the values you care about here instead.
    home.activation.marktextPreferences = {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.config/marktext"
        $DRY_RUN_CMD rm -f $VERBOSE_ARG "$HOME/.config/marktext/preferences.json"
        $DRY_RUN_CMD install -m600 $VERBOSE_ARG \
            ${preferencesFile} "$HOME/.config/marktext/preferences.json"
      '';
    };
  };
}
