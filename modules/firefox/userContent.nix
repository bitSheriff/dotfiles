# User content
# 1. removes dirty padding on top of icon in home screen
# 2. hover on icons on home screen will show specified color
# 3. removes the url bal in center on the home screen
# 4. removes pinned icon indicator on home page
# 5. changed home page icon width & height to 0, means no icon only text

/* rust */ ''

  /*================ GLOBAL COLORS ================*/

  @-moz-document url("about:newtab"), url("about:home"), url(about:privatebrowsing) {
    .top-site-outer .tile {
      background-color: rgba(30 30 46 / 0.1) !important;
    }
    .top-site-outer:hover {
      background-color: rgba(73 77 100 / 1) !important;
    }
  }

  @-moz-document url("about:home"), url("about:newtab"){
    .logo-and-wordmark{ display: none !important; }
  }

  @-moz-document url("about:newtab"), url("about:home"){
    .search-handoff-button{ display: none !important; }
  }

  @-moz-document url("about:home"), url("about:newtab"){
    .icon.icon-pin-small{ display: none !important }
  }

  @-moz-document url("about:home"), url("about:newtab"){
    .tile > .icon-wrapper{
      width: 0% !important;
      height: 0% !important;
    }
    .icon-pin-small{ display: none !important; }
  }

''
