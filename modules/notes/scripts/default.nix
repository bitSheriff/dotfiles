{ pkgs, ... }:

let
  jour = import ./jour.nix { inherit pkgs; };
  todoCommon = import ./todo-common.nix { inherit pkgs; };
  todo = import ./todo.nix { inherit pkgs todoCommon; };
  todo-list = import ./todo-list.nix { inherit pkgs todoCommon; };
  notes = import ./notes.nix { inherit pkgs; };
  memo = import ./memo.nix { inherit pkgs; };
in
{
  environment.systemPackages = [
    jour
    todo
    todo-list
    notes
  ]
  ++ memo;
}
