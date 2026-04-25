{
  config,
  pkgs,
  inputs,
  lib,
  activeUsers,
  ...
}:

{
  imports = [
  ];

  environment.systemPackages = with pkgs; [
    mpc
    rmpc # cli mpc client written in rust
  ];

  home-manager.users.benjamin = lib.mkIf (lib.elem "benjamin" activeUsers) {
    services.mpd = {
      enable = true;
      musicDirectory = "/home/benjamin/Music";
      extraConfig = ''
        audio_output {
          type "pulse"
          name "PulseAudio"
          mixer_type "software"
        }
      '';
    };

    xdg.configFile."rmpc/config.ron".text = ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
          address: "127.0.0.1:6600",
          music_directory: "/home/benjamin/Music",
          password: None,
          theme: Some("nord"),
          cache_dir: None,
          on_song_change: None,
          volume_step: 5,
          max_fps: 30,
          scrolloff: 0,
          wrap_navigation: false,
          enable_mouse: true,
          scroll_amount: 1,
          enable_config_hot_reload: true,
          enable_lyrics_hot_reload: false,
          status_update_interval_ms: 1000,
          rewind_to_start_sec: None,
          keep_state_on_song_change: true,
          reflect_changes_to_playlist: false,
          select_current_song_on_change: false,
          ignore_leading_the: false,
          browser_song_sort: [Disc, Track, Artist, Title],
          directories_sort: SortFormat(group_by_type: true, reverse: false),
          auto_open_downloads: true,
          album_art: (
              method: Auto,
              max_size_px: (width: 1200, height: 1200),
              disabled_protocols: ["http://", "https://"],
              vertical_align: Center,
              horizontal_align: Center,
          ),
          keybinds: (
              global: {
                  "q":          Quit,
                  "?":          ShowHelp,
                  ":":          CommandMode,
                  "oI":         ShowCurrentSongInfo,
                  "oo":         ShowOutputs,
                  "op":         ShowDecoders,
                  "od":         ShowDownloads,
                  "oP":         Partition(),
                  "z":          ToggleRepeat,
                  "x":          ToggleRandom,
                  "c":          ToggleConsume,
                  "v":          ToggleSingle,
                  "p":          TogglePause,
                  "s":          Stop,
                  ">":          NextTrack,
                  "<":          PreviousTrack,
                  "f":          SeekForward,
                  "b":          SeekBack,
                  ".":          VolumeUp,
                  ",":          VolumeDown,
                  "<Tab>":      NextTab,
                  "gt":         NextTab,
                  "<S-Tab>":    PreviousTab,
                  "gT":         PreviousTab,
                  "1":          SwitchToTab("Queue"),
                  "2":          SwitchToTab("Directories"),
                  "3":          SwitchToTab("Artists"),
                  "4":          SwitchToTab("Album Artists"),
                  "5":          SwitchToTab("Albums"),
                  "6":          SwitchToTab("Playlists"),
                  "7":          SwitchToTab("Search"),
                  "<C-u>":      Update,
                  "<C-U>":      Rescan,
                  "R":          AddRandom,
              },
              navigation: {
                  "<C-c>":      Close,
                  "<Esc>":      Close,
                  "<CR>":       Confirm,
                  "k":          Up,
                  "<Up>":       Up,
                  "j":          Down,
                  "<Down>":     Down,
                  "h":          Left,
                  "<Left>":     Left,
                  "l":          Right,
                  "<Right>":    Right,
                  "<C-w>k":     PaneUp,
                  "<C-Up>":     PaneUp,
                  "<C-w>j":     PaneDown,
                  "<C-Down>":   PaneDown,
                  "<C-w>h":     PaneLeft,
                  "<C-Left>":   PaneLeft,
                  "<C-w>l":     PaneRight,
                  "<C-Right>":  PaneRight,
                  "K":          MoveUp,
                  "J":          MoveDown,
                  "<C-u>":      UpHalf,
                  "<C-d>":      DownHalf,
                  "<C-b>":      PageUp,
                  "<PageUp>":   PageUp,
                  "<C-f>":      PageDown,
                  "<PageDown>": PageDown,
                  "gg":         Top,
                  "G":          Bottom,
                  "<Space>":    Select,
                  "<C-Space>":  InvertSelection,
                  "/":          EnterSearch,
                  "n":          NextResult,
                  "N":          PreviousResult,
                  "a":          Add,
                  "A":          AddAll,
                  "D":          Delete,
                  "<C-r>":      Rename,
                  "i":          FocusInput,
                  "oi":         ShowInfo,
                  "<C-z>":      ContextMenu(),
                  "<C-s>s":     Save(kind: Modal(all: false, duplicates_strategy: Ask)),
                  "<C-s>a":     Save(kind: Modal(all: true, duplicates_strategy: Ask)),
                  "r":          Rate(),
              },
              queue: {
                  "d":          Delete,
                  "D":          DeleteAll,
                  "<CR>":       Play,
                  "C":          JumpToCurrent,
                  "X":          Shuffle,
              },
          ),
          search: (
              case_sensitive: false,
              ignore_diacritics: false,
              search_button: false,
              mode: Contains,
              tags: [
                  (value: "any",         label: "Any Tag"),
                  (value: "artist",      label: "Artist"),
                  (value: "album",       label: "Album"),
                  (value: "albumartist", label: "Album Artist"),
                  (value: "title",       label: "Title"),
                  (value: "filename",    label: "Filename"),
                  (value: "genre",       label: "Genre"),
              ],
          ),
          artists: (
              album_display_mode: SplitByDate,
              album_sort_by: Date,
              album_date_tags: [Date],
          ),
          tabs: [
              (
                  name: "Queue",
                  pane: Split(
                      direction: Horizontal,
                      panes: [
                          (
                              size: "35%",
                              pane: Split(
                                  direction: Vertical,
                                  panes: [
                                      (
                                          size: "100%",
                                          borders: "LEFT | RIGHT | TOP",
                                          border_symbols: Rounded,
                                          pane: Pane(AlbumArt)
                                      ),
                                      (
                                          size: "7",
                                          borders: "ALL",
                                          border_symbols: Inherited(parent: Rounded, top_left: "├", top_right: "┤",),
                                          border_title: [(kind: Text(" Lyrics "))],
                                          border_title_alignment: Right,
                                          pane: Pane(Lyrics)
                                      ),
                                  ],
                              ),
                          ),
                          (
                              size: "65%",
                              pane: Split(
                                  direction: Vertical,
                                  panes: [
                                      (
                                          size: "3",
                                          borders: "ALL",
                                          border_symbols: Inherited(parent: Rounded, bottom_left: "├", bottom_right: "┤",),
                                          pane: Split(
                                              direction: Horizontal,
                                              panes: [
                                                  (
                                                      size: "1",
                                                      pane: Pane(Empty())
                                                  ),
                                                  (
                                                      size: "100%",
                                                      pane: Pane(QueueHeader())
                                                  ),
                                              ]
                                          )
                                      ),
                                      (
                                          size: "100%",
                                          borders: "LEFT | RIGHT | BOTTOM",
                                          border_symbols: Rounded,
                                          pane: Split(
                                              direction: Horizontal,
                                              panes: [
                                                  (
                                                      size: "1",
                                                      pane: Pane(Empty())
                                                  ),
                                                  (
                                                      size: "100%",
                                                      pane: Pane(Queue)
                                                  ),
                                              ]
                                          )
                                      ),
                                  ],
                              )
                          ),
                      ],
                  ),
              ),
              (
                  name: "Directories",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Directories), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Artists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Artists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Album Artists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(AlbumArtists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Albums",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Albums), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Playlists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Playlists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Search",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Search), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
          ],
      )
    '';
    xdg.configFile."rmpc/themes/nord.ron".text = ''
                  #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
          default_album_art_path: None,
          format_tag_separator: " | ",
          browser_column_widths: [20, 38, 42],
          background_color: "#2e3440",
          modal_backdrop: true,
          text_color: "#d8dee9",
          header_background_color: "#2e3440",
          modal_background_color: "#2e3440",
          preview_label_style: (fg: "#b48ead"),
          preview_metadata_group_style: (fg: "#81a1c1"),
          song_table_album_separator: None,
          tab_bar: (
              active_style: (fg: "#2e3440", bg: "#81A1C1", modifiers: "Bold"),
              inactive_style: (fg: "#4c566a", bg: "#2e3440"),
          ),
          highlighted_item_style: (fg: "#a3be8c", modifiers: "Bold"),
          current_item_style: (fg: "#2e3440", bg: "#81a1c1", modifiers: "Bold"),
          borders_style: (fg: "#81a1c1", modifiers: "Bold"),
          highlight_border_style: (fg: "#81a1c1"),
          symbols: (song: "󰝚 ", dir: "󱍙 ", playlist: "󰲸 ", marker: "* ", ellipsis: "...",
              song_style: (fg: "#81a1c1"), dir_style: (fg: "#81a1c1"),
          ),
          progress_bar: (
              symbols: ["", "█", "", "█", "" ],
              track_style: (fg: "#3b4252", bg: "#2e3440"),
              elapsed_style: (fg: "#81a1c1", bg: "#2e3440"),
              thumb_style: (fg: "#81a1c1", bg: "#3b4252"),
              use_track_when_empty: false,
          ),
          scrollbar: (
              symbols: ["┋", "█", "󰄿", "󰄼"],
              track_style: (fg: "#81a1c1"),
              ends_style: (fg: "#81a1c1"),
              thumb_style: (fg: "#81a1c1"),
          ),
          song_table_format: [
              (
              prop: (kind: Transform(Replace(content: (kind: Sticker("rating")), replacements: [
                  (match:  "0", replace: (kind: Group([(kind: Text("󰎡"),style: (fg: "#81a1c1"))]))),
                  (match:  "1", replace: (kind: Group([(kind: Text("󰎤"),style: (fg: "#81a1c1"))]))),
                  (match:  "2", replace: (kind: Group([(kind: Text("󰎧"),style: (fg: "#81a1c1"))]))),
                  (match:  "3", replace: (kind: Group([(kind: Text("󰎪"),style: (fg: "#81a1c1"))]))),
                  (match:  "4", replace: (kind: Group([(kind: Text("󰎭"),style: (fg: "#81a1c1"))]))),
                  (match:  "5", replace: (kind: Group([(kind: Text("󰎱"),style: (fg: "#81a1c1"))]))),
                  (match:  "6", replace: (kind: Group([(kind: Text("󰎳"),style: (fg: "#81a1c1"))]))),
                  (match:  "7", replace: (kind: Group([(kind: Text("󰎶"),style: (fg: "#81a1c1"))]))),
                  (match:  "8", replace: (kind: Group([(kind: Text("󰎹"),style: (fg: "#81a1c1"))]))),
                  (match:  "9", replace: (kind: Group([(kind: Text("󰎼"),style: (fg: "#81a1c1"))]))),
                  (match: "10", replace: (kind: Group([(kind: Text("󰽽"),style: (fg: "#81a1c1"))]))),
              ])), default: (kind: Text(""), style: (fg: "#5e81ac"))),
              width: "3",
              label: "Rating",
              alignment: Center,
                  label_prop: (kind: Group([
                      (kind: Text("󰩳"), style: (fg: "#81a1c1")),
                  ]))
              ),
              (
                  prop: (kind: Sticker("playCount"),style: (fg: "#81a1c1"),
                       default: (kind: Text(""), style: (fg: "#5e81ac"))),
                  width: "3",
                  alignment: Left,
                  label: "Playcount",
                  label_prop: (kind: Group([
                      (kind: Text("󰆙"), style: (fg: "#81a1c1")),
                  ]))
              ),
              (
                  prop:(kind: Text("│"), style: (fg: "#81a1c1")),
                  width: "1",
                  alignment: Center,
                  label: "",
                  label_prop: (kind: Group([
                      (kind: Text("│"), style: (fg: "#81a1c1")),
                  ]))
              ),
              (
                  prop: (kind: Property(Artist), style: (fg: "#81a1c1"),
                      default: (kind: Text("Unknown Artist"), style: (fg: "#b48ead"))),
                  width: "23%",
                  label_prop: (kind: Group([
                      (kind: Text("Artist "), style: (fg: "#d8dee9")),
                      (kind: Text(""), style: (fg: "#81a1c1"))
                  ]))
              ),
              (
                  prop: (kind: Property(Title), style: (fg: "#88c0d0"),
                      default: (kind: Property(Filename), style: (fg: "#d8dee9"),
                          default: (kind: Text("Unknown Title"), style: (fg: "#d8dee9")))),
                  width: "36%",
                  label_prop: (kind: Group([
                      (kind: Text("Title "), style: (fg: "#d8dee9")),
                      (kind: Text(""), style: (fg: "#81a1c1"))
                  ]))
              ),
              (
                  prop: (kind: Property(Album), style: (fg: "#81a1c1"),
                      default: (kind: Text("Unknown Album"), style: (fg: "#b48ead"))),
                  width: "33%",
                  label_prop: (kind: Group([
                      (kind: Text("Album "), style: (fg: "#d8dee9")),
                      (kind: Text("󰀥"), style: (fg: "#81a1c1"))
                  ]))
              ),
              (
                  prop: (kind: Property(Duration), style: (fg: "#88c0d0"),
                      default: (kind: Text("-"))),
                  width: "8%",
                  alignment: Right,
                  label_prop: (kind: Group([
                      (kind: Text("Length "), style: (fg: "#d8dee9")),
                      (kind: Text(" "), style: (fg: "#81a1c1"))
                  ]))
              ),
          ],
          layout: Split(
              direction: Vertical, panes: [
                  (size: "7", borders: "NONE", pane: Component("header")),
                  (size: "100%", borders: "NONE", pane: Pane(TabContent)),
                  (size: "3", borders: "NONE", pane: Component("progress_bar")),
              ]),
          browser_song_format: [
              (kind: Group([
                          (kind: Property(Track)),
                          (kind: Text(" ")),
                      ])),
              (kind: Group([
                          (kind: Property(Artist)),
                          (kind: Text(" - ")),
                          (kind: Property(Title)),
                      ]), default: (kind: Property(Filename)))
          ],
          level_styles: (
              info:  (fg: "#a3be8c", bg: "#2e3440"),
              warn:  (fg: "#ebcb8b", bg: "#2e3440"),
              error: (fg: "#bf616a", bg: "#2e3440"),
              debug: (fg: "#d08770", bg: "#2e3440"),
              trace: (fg: "#b48ead", bg: "#2e3440"),
          ),
          components: {
              "header_line_0": Split(direction: Horizontal, panes: [
                          (size: "12%", borders: "NONE", pane: Component("tab_bar_left")),
                          (size: "76%", borders: "NONE", pane: Pane(Tabs)),
                          (size: "12%", borders: "NONE", pane: Component("tab_bar_right")),
                  ]),
              "header_line_1": Split(direction: Horizontal, panes: [
                                  (size: "22%", pane: Component("header_element_1")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "56%", pane: Component("header_element_2")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "22%", pane: Component("header_element_3")),
                                  (size: "2", pane: Component("header_element_right_end")),
                  ]),
              "header_line_2": Split(direction: Horizontal, panes: [
                                  (size: "22%", pane: Component("header_element_4")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "56%", pane: Component("header_element_5")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "22%", pane: Component("header_element_6")),
                                  (size: "2", pane: Component("header_element_right_end")),
                  ]),
              "header_line_3": Split(direction: Horizontal, panes: [
                                  (size: "25%", pane: Component("header_element_7")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "50%", pane: Component("header_element_8")),
                                  (size: "1", pane: Component("header_element_space")),
                                  (size: "25%", pane: Component("header_element_9")),
                                  (size: "2", pane: Component("header_element_right_end")),

                  ]),
              "header": Split(
                  direction: Vertical, panes: [
                      (size: "2", borders: "TOP | RIGHT | LEFT", border_symbols: Rounded,
                          pane: Split(direction: Horizontal, panes: [
                              (size: "100%", borders: "NONE", pane: Component("header_line_0")),
                        ])
                      ),
                      (size: "5", borders: "ALL", border_symbols: Library("rounded_collapsed_top"),
                        pane: Split(direction: Vertical, panes: [
                           (size: "100%", borders: "NONE", pane: Component("header_line_1")),
                           (size: "100%", borders: "NONE", pane: Component("header_line_2")),
                           (size: "100%", borders: "NONE", pane: Component("header_line_3")),
                        ])
                      ),
                  ]
              ),
              "progress_bar": Split(
                  direction: Vertical, panes: [
                    (size: "3", borders: "ALL", border_symbols: Rounded ,
                        border_title: [
                               (kind: Property(Status(Elapsed)),style: (fg: "#d8dee9")),
                               (kind: Property(Status(StateV2(playing_label: "─󱦟─", paused_label: "  ", stopped_label: "  "))),
                                   style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(Duration)),style: (fg: "#d8dee9"))
                            ],
                        border_title_position: Top,
                        border_title_alignment: Center,
                        pane: Split(direction: Vertical, panes: [
                            (size: "100%", borders: "NONE",pane: Pane(ProgressBar)),
                      ])
                    ),
                  ]
              ),
              "tab_bar_left": Split(direction: Horizontal, panes: [
                   (size: "100%", pane: Pane(Property(content: [
                                   (kind: Text(" "), style: (fg: "#81a1c1", modifiers: "Bold")),
                                   (kind: Property(Status(StateV2(playing_label: "", paused_label: "", stopped_label: ""))),
                                       style: (fg: "#d8dee9")),
                                   (kind: Text("  "), style: (fg: "#81a1c1", modifiers: "Bold")),
                                   (kind: Property(Song(FileExtension)), style: (fg: "#4c566a")),
                                   (kind: Text(" ")),
                                   (kind: Property(Widget(ScanStatus)), style: (fg: "#d8dee9", modifiers: "Bold")),
                                   (kind: Text(" ")),
                                   (kind: Property(Status(InputBuffer())), style: (fg: "#4c566a")),
                               ], align: Left))
                   ),
                  ]),
              "tab_bar_right": Split(direction: Horizontal, panes: [
                       (size: "100%", pane: Pane(Property(content: [
                                       (kind: Transform(Replace(content: (kind: Property(Status(Partition)), style: (fg: "#4c566a")), replacements: [
                                           (match:  "default", replace: (kind: Group([(kind: Text(""))]))),
                                         ]))),
                                       (kind: Text(" ")),
                                       (kind: Property(Song(Channels())), style: (fg: "#4c566a"),
                                           default: (kind: Text("0"), style: (fg: "#4c566a"))),
                                       (kind: Text(" 󱡫 "),style: (fg: "#4c566a")),
                                       (kind: Text(" 󱡬"), style: (fg: "#81a1c1", modifiers: "Bold")),
                                       (kind: Property(Status(Volume)), style: (fg: "#d8dee9")),
                                       (kind: Text("% "), style: (fg: "#81a1c1", modifiers: "Bold"))
                                   ], align: Right))
                       ),
                  ]),
              "header_element_1": Split(
                  direction: Horizontal,
                  panes: [
                     (size: "100%", pane: Pane(Property(content: [
                                     (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                     (kind: Property(Status(Elapsed)),style: (fg: "#d8dee9")),
                                     (kind: Text(" / "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                     (kind: Property(Status(Duration)),style: (fg: "#d8dee9")),
                                     (kind: Text(" 󱦟"),style: (fg: "#81a1c1", modifiers: "Bold")),
                                     (kind: Text(" ]"),style: (fg: "#81a1c1", modifiers: "Bold")),
                                 ], align: Left))
                     ),
                  ]
              ),
              "header_element_2": Split(
                  direction: Horizontal,
                  panes: [
                      (size: "100%", pane: Pane(Property(content: [
                                      (kind: Property(Song(Title)), style: (fg: "#d8dee9",modifiers: "Bold"),
                                          default: (kind: Property(Song(Filename)), style: (fg: "#d8dee9",modifiers: "Bold"),
                                              default: (kind: Text("Unknown Title"), style: (fg: "#d8dee9",modifiers: "Bold"))))
                                  ], align: Center, scroll_speed: 4))
                      ),
                  ]
              ),
              "header_element_3": Split(
                  direction: Horizontal,
                  panes: [
                     (size: "100%", pane: Pane(Property(content: [
                               (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(RepeatV2(on_label: "", off_label: "",
                                               on_style: (fg: "#d8dee9", modifiers: "Bold"),
                                               off_style: (fg: "#4c566a", modifiers: "Bold"))))),
                               (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(RandomV2(on_label: "", off_label: "",
                                               on_style: (fg: "#d8dee9", modifiers: "Bold"),
                                               off_style: (fg: "#4c566a", modifiers: "Bold"))))),
                               (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(ConsumeV2(on_label: "󰮯", off_label: "󰮯", oneshot_label: "󰮯󰇊",
                                               on_style: (fg: "#d8dee9", modifiers: "Bold"),
                                               off_style: (fg: "#4c566a", modifiers: "Bold"))))),
                               (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(SingleV2(on_label: "󰎤", off_label: "󰎦", oneshot_label: "󰇊", off_oneshot_label: "󱅊",
                                               on_style: (fg: "#d8dee9", modifiers: "Bold"),
                                               off_style: (fg: "#4c566a", modifiers: "Bold"))))),
                               (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Property(Status(Crossfade)),style: (fg: "#4c566a"),
                                default: (kind: Text("󰴽"), style: (fg: "#4c566a"))),
                               (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                               (kind: Transform(Replace(content: (kind: Property(Status(InputMode()))), replacements: [
                                       (match:  "Normal", replace: (kind: Group([(kind: Text("N"),style: (fg: "#4c566a", modifiers: "Bold"))]))),
                                       (match:  "Insert", replace: (kind: Group([(kind: Text("I"),style: (fg: "#d8dee9", modifiers: "Bold"))]))),
                                   ]))),
                           ], align: Right))
                     ),
                  ]
              ),
              "header_element_4": Split(
                  direction: Horizontal,
                  panes: [
                      (size: "100%", pane: Pane(Property(content: [
                                      (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                      (kind: Property(Song(Bits())),default: (kind: Text(" "), style: (fg: "#d8dee9")), style: (fg: "#d8dee9")),
                                      (kind: Text(" bit"),style: (fg: "#81a1c1")),
                                      (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                      (kind: Property(Status(Bitrate)),default: (kind: Text(" "), style: (fg: "#d8dee9")),style: (fg: "#d8dee9")),
                                      (kind: Text(" kbps"),style: (fg: "#81a1c1")),
                                      (kind: Text(" ]"),style: (fg: "#81a1c1", modifiers: "Bold"))
                                  ], align: Left))
                      ),
                  ]
              ),
              "header_element_5": Split(
                  direction: Horizontal,
                  panes: [
                       (size: "100%", pane: Pane(Property(content: [
                                       (kind: Property(Song(Artist)), style: (fg: "#88c0d0"),
                                           default: (kind: Text("Unknown Artist"), style: (fg: "#88c0d0"))),
                                       (kind: Text(" - "), style: (fg: "#d8dee9")),
                                       (kind: Property(Song(Album)),style: (fg: "#81a1c1" ),
                                           default: (kind: Text("Unknown Album"), style: (fg: "#81a1c1")))
                                   ], align: Center, scroll_speed: 4))
                       ),
                  ]
              ),
              "header_element_6": Split(
                  direction: Horizontal,
                  panes: [
                       (size: "100%", pane: Pane(Property(content: [
                                       (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                       (kind: Property(Status(QueueTimeRemaining(separator: " "))),style: (fg: "#d8dee9")),
                                       (kind: Text(" / "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                       (kind: Property(Status(QueueTimeTotal(separator: " "))),style: (fg: "#d8dee9")),
                                       (kind: Text(" 󱎫"),style: (fg: "#81a1c1", modifiers: "Bold")),
                                   ], align: Right))
                       ),
                  ]
              ),
              "header_element_7": Split(
                  direction: Horizontal,
                  panes: [
                        (size: "100%", pane: Pane(Property(content: [
                                        (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                        (kind: Property(Song(SampleRate())),default: (kind: Text(" "), style: (fg: "#d8dee9")), style: (fg: "#d8dee9")),
                                        (kind: Text(" Hz"),style: (fg: "#81a1c1")),
                                        (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                        (kind: Property(Song(Position)), style: (fg: "#d8dee9"),
                                            default: (kind: Text("0"), style: (fg: "#d8dee9"))),
                                        (kind: Text(" / "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                        (kind: Property(Status(QueueLength())),style: (fg: "#d8dee9")),
                                        (kind: Text(" 󰴍"),style: (fg: "#81a1c1", modifiers: "Bold")),
                                        (kind: Text(" ]"),style: (fg: "#81a1c1", modifiers: "Bold"))
                                    ], align: Left))
                        ),
                  ]
              ),
              "header_element_8": Split(
                  direction: Horizontal,
                  panes: [
                         (size: "100%", pane: Pane(Property(content: [
                                         (kind: Property(Song(Other("albumartist"))),style: (fg: "#4c566a"),
                                             default: (kind: Text("Unknown Albumartist"), style: (fg: "#4c566a"))),
                                         (kind: Text(" - "), style: (fg: "#4c566a")),
                                         (kind: Property(Song(Other("composer"))),style: (fg: "#4c566a"),
                                             default: (kind: Text("Unknown Composer"), style: (fg: "#4c566a"))),
                                     ], align: Center, scroll_speed: 4))
                         ),
                  ]
              ),
              "header_element_9": Split(
                  direction: Horizontal,
                  panes: [
                         (size: "100%", pane: Pane(Property(content: [
                                         (kind: Text("[ "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                         (kind: Property(Song(Other("date"))),style: (fg: "#d8dee9"),
                                             default: (kind: Text("Unknown Date"), style: (fg: "#4c566a"))),
                                         (kind: Text(" | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                         (kind: Property(Song(Track)),style: (fg: "#d8dee9"),
                                             default: (kind: Text("0"), style: (fg: "#4c566a"))),
                                         (kind: Text(" / "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                         (kind: Property(Song(Disc)),style: (fg: "#d8dee9"),
                                             default: (kind: Text("0"), style: (fg: "#4c566a"))),
                                         (kind: Text(" 󰥠 | "),style: (fg: "#81a1c1", modifiers: "Bold")),
                                         (kind: Property(Song(Other("genre"))),style: (fg: "#d8dee9"),
                                             default: (kind: Text("Unknown Genre"), style: (fg: "#4c566a"))),
                                     ], align: Right))
                         ),
                  ]
              ),
              "header_element_right_end": Split(
                  direction: Horizontal,
                  panes: [
                     (size: "100%", pane: Pane(Property(content: [
                                     (kind: Text(" ]"),style: (fg: "#81a1c1", modifiers: "Bold")),
                                 ], align: Right))
                     ),
                  ]
              ),
              "header_element_space": Split(
                  direction: Horizontal,
                  panes: [
                     (size: "100%", pane: Pane(Property(content: [
                                     (kind: Text(" ")),
                                 ], align: Right))
                     ),
                  ]
              ),
          },
          cava: (
              bar_symbols: ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'],
              bar_width: 1, bar_spacing: 1,
              bg_color: "#2e3440",
              bar_color: Gradient({
                      0:   "#5e81ac",
                      33:  "#81a1c1",
                      67:  "#88c0d0",
                      100: "#8fbcbb",
                  })
          ),
          lyrics:(timestamp: false),
          border_symbol_sets: {
          "rounded_collapsed_top": (
              parent: Rounded,
              top_left: "├",
              top_right: "┤",
              ),
          },
      )
    '';

  };

}
