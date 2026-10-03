{ pkgs, ... }:

let
  jour = import ./jour.nix { inherit pkgs; };
  todo = import ./todo.nix { inherit pkgs; };
  todo-list = import ./todo-list.nix { inherit pkgs; };
  notes = import ./notes.nix { inherit pkgs; };
  memo = import ./memo.nix { inherit pkgs; };
in
{
  environment.systemPackages = [
    jour
    todo
    todo-list
    notes
  ] ++ memo;
}
