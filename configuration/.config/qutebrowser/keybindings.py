def load_keybindings(config):
    config.bind('=', 'cmd-set-text -s :open')
    config.bind('H', 'history')                                                 # open history
    config.bind('h', 'back')                                                    # go back in history
    config.bind('l', 'forward')                                                 # go forward in history
    config.bind('T', 'hint links tab')

    # config.bind('pP', 'open -- {primary}')
    config.bind('pp', 'open -- {clipboard}')
    config.bind('pP', 'open -t -- {clipboard}')
    config.bind('py', 'spawn mpv {url}')                                        # open the current url in mpv
    config.bind('pY', 'hint links spawn --detach mpv {hint-url}')
    
    config.unbind('q')                                                          # i dont need macros

    ## Quickmarks
    config.bind('B', 'bookmark-list')                                           # open bookmarks list
    config.bind('Qa', 'quickmark-save')                                         # save current page as quickmark
    config.bind('Qd', 'quickmark-del')                                          # delete current page as quickmark
    config.bind('Qo', 'cmd-set-text -s :quickmark-load')                        # open quickmarks

    # Tabs
    config.bind('gJ', 'tab-move +')
    config.bind('gK', 'tab-move -')
    config.bind('gm', 'tab-move')

    ## UI Changes
    config.bind('tH', 'config-cycle tabs.show multiple never')
    config.bind('sH', 'config-cycle statusbar.show always never')
    # config.bind('tT', 'config-cycle tabs.position top left')

