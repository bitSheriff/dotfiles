''
  /* ------------------------ */
  /* -- Gray Extensions color */
  /* ------------------------ */

  toolbar .toolbarbutton-1:not(#firefox-view-button):not(#star-button) {
      filter: grayscale(100%)!important;
  }
  toolbar .toolbarbutton-1:not(#firefox-view-button):not(#star-button):hover {
      filter: grayscale(0%)!important;
  }

  /* ------------------------ */
  /* -- Clean extensions menu */
  /* ------------------------ */

  #unified-extensions-view {
    --uei-icon-size: 20px !important; /* Icons size */
    width: 280px !important; /* Panel width */
  }

  .panel-header,
  .unified-extensions-item-message-deck,
  .unified-extensions-item-menu-button.subviewbutton {
    display: none !important; /* Hide panel header, permissions items and setting buttons */
  }

  .panel-subview-footer-button {
    text-align-last: center !important; /* Center text on footer */
  }

  /* -------------------------------------- */
  /* -- Removes Items from Tab Context Menu */
  /* -------------------------------------- */

  menuseparator,
  #context_openANewTab,
  #context_newTab,
  #context_bookmarkTab,
  #context_moveTabOptions,
  #context_reloadTab,
  #context_selectAllTabs,
  #context_closeDuplicateTabs,
  #context_closeTabOptions,
  #context_toggleMuteTab,
  #context_pinTab,
  #context_unpinTab,
  #context_openTabInWindow,
  #context_sendTabToDevice_separator,
  #context_sendTabToDevice,
  #context_reloadAllTabs,
  #context_bookmarkAllTabs,
  #context_closeTabsToTheEnd,
  #context_closeOtherTabs,
  #context_undoCloseTab,
  #context_closeTab,
  menuitem.share-tab-url-item
  { display: none !important }

  /* -------------------------------------------- */
  /* -- Creates animated border around active tab */
  /* -------------------------------------------- */

  /* Source file https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/tab_animated_active_border.css made available under Mozilla Public License v. 2.0
  See the above repository for updates as well as full license text. */

  /* Creates a colorful animated border around active tab */

  @keyframes filter{from{ filter: hue-rotate(0deg) } to { filter: hue-rotate(360deg) }}

  .tabbrowser-tab[selected] > .tab-stack::before{
    grid-area: 1/1;
    content: "";
    display: inherit;
    margin-block: var(--tab-block-margin);
    border-radius: var(--tab-border-radius);
    z-index: 0;
    background-image: conic-gradient(
      rgb(203, 166, 247),
      rgb(147, 153, 178) 70deg,
      rgb(166, 173, 200) 105deg,
      rgb(186, 194, 222) 160deg,
      rgb(205, 214, 244) 200deg,
      rgb(180, 190, 254) 255deg,
      rgb(203, 166, 247) 290deg,
      rgb(203, 166, 247) 360deg);
    background-size: cover;
    background-position: center;
    animation: filter steps(30) 2s infinite;
  }
  .tab-background[selected]{
    border: 1px solid transparent !important;
    outline: none !important;
    background-clip: padding-box !important;
  }

  /* ----------------------------------------------------------- */
''
