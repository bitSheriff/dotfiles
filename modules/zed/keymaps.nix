{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [ ];

  home-manager.users.${username} = {
    programs.zed-editor = {
      userKeymaps = [
        {
          context = "Editor && (vim_mode == normal || vim_mode == visual) && !VimWaiting && !menu";
          bindings = {
            "space t i" = "editor::ToggleInlayHints";
            "space u w" = "editor::ToggleSoftWrap";
            "space c z" = "workspace::ToggleCenteredLayout";
            "space m p" = "markdown::OpenPreview";
            "space m P" = "markdown::OpenPreviewToTheSide";
            "space f p" = "projects::OpenRecent";
            "space s w" = "pane::DeploySearch";
            "space a c" = "assistant::ToggleFocus";
            "g f" = "editor::OpenExcerpts";
            "space f" = "file_finder::Toggle";
            "space e" = "workspace::ToggleLeftDock";
          };
        }
        {
          context = "Editor && vim_mode == normal && !VimWaiting && !menu";
          bindings = {
            # Window movement
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";

            # LSP
            "space c a" = "editor::ToggleCodeActions";
            "space ." = "editor::ToggleCodeActions";
            "space c f" = "editor::Format";
            "space c r" = "editor::Rename";
            "g d" = "editor::GoToDefinition";
            "g D" = "editor::GoToDefinitionSplit";
            "g i" = "editor::GoToImplementation";
            "g I" = "editor::GoToImplementationSplit";
            "g t" = "editor::GoToTypeDefinition";
            "g T" = "editor::GoToTypeDefinitionSplit";
            "g r" = "editor::FindAllReferences";
            "] d" = "editor::GoToDiagnostic";
            "[ d" = "editor::GoToPreviousDiagnostic";
            "] e" = "editor::GoToDiagnostic";
            "[ e" = "editor::GoToPreviousDiagnostic";

            # Symbol search
            "s s" = "outline::Toggle";
            "s S" = "project_symbols::Toggle";
            "space x x" = "diagnostics::Deploy";

            # Git
            "] h" = "editor::GoToHunk";
            "[ h" = "editor::GoToPreviousHunk";

            # Buffers
            "shift-h" = "pane::ActivatePreviousItem";
            "shift-l" = "pane::ActivateNextItem";
            "shift-q" = "pane::CloseActiveItem";
            "ctrl-q" = "pane::CloseActiveItem";
            "space b d" = "pane::CloseActiveItem";
            "space b o" = "pane::CloseInactiveItems";
            "ctrl-s" = "workspace::Save";
            "space space" = "file_finder::Toggle";
            "space /" = "pane::DeploySearch";
            "space e" = "pane::RevealInProjectPanel";

            # Docks
            "ctrl-alt-left" = "workspace::ToggleLeftDock";
            "ctrl-alt-right" = "workspace::ToggleRightDock";
          };
        }
        {
          context = "EmptyPane || SharedScreen";
          bindings = {
            "space space" = "file_finder::Toggle";
            "space f p" = "projects::OpenRecent";
          };
        }
        {
          context = "Editor && vim_mode == visual && !VimWaiting && !menu";
          bindings = {
            "g c" = "editor::ToggleComments";
          };
        }
        {
          context = "Editor && vim_mode == insert && !menu";
          bindings = {
            "j j" = "vim::NormalBefore";
            "j k" = "vim::NormalBefore";
          };
        }
        {
          context = "Editor && vim_operator == c";
          bindings = {
            "c" = "vim::CurrentLine";
            "r" = "editor::Rename";
          };
        }
        {
          context = "Workspace";
          bindings = {
            "ctrl-shift-t" = "terminal_panel::ToggleFocus";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "ctrl-shift-t" = "terminal_panel::ToggleFocus";
          };
        }
        {
          context = "ProjectPanel && not_editing";
          bindings = {
            "a" = "project_panel::NewFile";
            "A" = "project_panel::NewDirectory";
            "r" = "project_panel::Rename";
            "d" = "project_panel::Delete";
            "x" = "project_panel::Cut";
            "c" = "project_panel::Copy";
            "p" = "project_panel::Paste";
            "q" = "workspace::ToggleRightDock";
            "space e" = "workspace::ToggleRightDock";
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
          };
        }
        {
          context = "Dock";
          bindings = {
            "ctrl-w h" = "workspace::ActivatePaneLeft";
            "ctrl-w l" = "workspace::ActivatePaneRight";
            "ctrl-w k" = "workspace::ActivatePaneUp";
            "ctrl-w j" = "workspace::ActivatePaneDown";
            "ctrl-alt-left" = "workspace::ToggleLeftDock";
            "ctrl-alt-right" = "workspace::ToggleRightDock";
          };
        }
      ];
    };
  };
}
