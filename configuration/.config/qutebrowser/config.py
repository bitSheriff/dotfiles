
def dracula_theme(c, options = {}):
    palette = {
        'background': '#282a36',
        'background-alt': '#282a36', 
        'background-attention': '#181920',
        'border': '#282a36',
        'current-line': '#44475a',
        'selection': '#44475a',
        'foreground': '#f8f8f2',
        'foreground-alt': '#e0e0e0',
        'foreground-attention': '#ffffff',
        'comment': '#6272a4',
        'cyan': '#8be9fd',
        'green': '#50fa7b',
        'orange': '#ffb86c',
        'pink': '#ff79c6',
        'purple': '#bd93f9',
        'red': '#ff5555',
        'yellow': '#f1fa8c'
    }   

    spacing = options.get('spacing', {
        'vertical': 5,
        'horizontal': 5
    })

    padding = options.get('padding', {
        'top': spacing['vertical'],
        'right': spacing['horizontal'],
        'bottom': spacing['vertical'],
        'left': spacing['horizontal']
    })

    ## Background color of the completion widget category headers.
    c.colors.completion.category.bg = palette['background']

    ## Bottom border color of the completion widget category headers.
    c.colors.completion.category.border.bottom = palette['border']

    ## Top border color of the completion widget category headers.
    c.colors.completion.category.border.top = palette['border']

    ## Foreground color of completion widget category headers.
    c.colors.completion.category.fg = palette['foreground']

    ## Background color of the completion widget for even rows.
    c.colors.completion.even.bg = palette['background']

    ## Background color of the completion widget for odd rows.
    c.colors.completion.odd.bg = palette['background-alt']

    ## Text color of the completion widget.
    c.colors.completion.fg = palette['foreground']

    ## Background color of the selected completion item.
    c.colors.completion.item.selected.bg = palette['selection']

    ## Bottom border color of the selected completion item.
    c.colors.completion.item.selected.border.bottom = palette['selection']

    ## Top border color of the completion widget category headers.
    c.colors.completion.item.selected.border.top = palette['selection']

    ## Foreground color of the selected completion item.
    c.colors.completion.item.selected.fg = palette['foreground']

    ## Foreground color of the matched text in the completion.
    c.colors.completion.match.fg = palette['orange']

    ## Color of the scrollbar in completion view
    c.colors.completion.scrollbar.bg = palette['background']

    ## Color of the scrollbar handle in completion view.
    c.colors.completion.scrollbar.fg = palette['foreground']

    ## Background color for the download bar.
    c.colors.downloads.bar.bg = palette['background']

    ## Background color for downloads with errors.
    c.colors.downloads.error.bg = palette['background']

    ## Foreground color for downloads with errors.
    c.colors.downloads.error.fg = palette['red']

    ## Color gradient stop for download backgrounds.
    c.colors.downloads.stop.bg = palette['background']

    ## Color gradient interpolation system for download backgrounds.
    ## Type: ColorSystem
    ## Valid values:
    ##   - rgb: Interpolate in the RGB color system.
    ##   - hsv: Interpolate in the HSV color system.
    ##   - hsl: Interpolate in the HSL color system.
    ##   - none: Don't show a gradient.
    c.colors.downloads.system.bg = 'none'

    ## Background color for hints. Note that you can use a `rgba(...)` value
    ## for transparency.
    c.colors.hints.bg = palette['background']

    ## Font color for hints.
    c.colors.hints.fg = palette['purple']

    ## Hints
    c.hints.border = '1px solid ' + palette['background-alt']

    ## Font color for the matched part of hints.
    c.colors.hints.match.fg = palette['foreground-alt']

    ## Background color of the keyhint widget.
    c.colors.keyhint.bg = palette['background']

    ## Text color for the keyhint widget.
    c.colors.keyhint.fg = palette['purple']

    ## Highlight color for keys to complete the current keychain.
    c.colors.keyhint.suffix.fg = palette['selection']

    ## Background color of an error message.
    c.colors.messages.error.bg = palette['background']

    ## Border color of an error message.
    c.colors.messages.error.border = palette['background-alt']

    ## Foreground color of an error message.
    c.colors.messages.error.fg = palette['red']

    ## Background color of an info message.
    c.colors.messages.info.bg = palette['background']

    ## Border color of an info message.
    c.colors.messages.info.border = palette['background-alt']

    ## Foreground color an info message.
    c.colors.messages.info.fg = palette['comment']

    ## Background color of a warning message.
    c.colors.messages.warning.bg = palette['background']

    ## Border color of a warning message.
    c.colors.messages.warning.border = palette['background-alt']

    ## Foreground color a warning message.
    c.colors.messages.warning.fg = palette['red']

    ## Background color for prompts.
    c.colors.prompts.bg = palette['background']

    # ## Border used around UI elements in prompts.
    c.colors.prompts.border = '1px solid ' + palette['background-alt']

    ## Foreground color for prompts.
    c.colors.prompts.fg = palette['cyan']

    ## Background color for the selected item in filename prompts.
    c.colors.prompts.selected.bg = palette['selection']

    ## Background color of the statusbar in caret mode.
    c.colors.statusbar.caret.bg = palette['background']

    ## Foreground color of the statusbar in caret mode.
    c.colors.statusbar.caret.fg = palette['orange']

    ## Background color of the statusbar in caret mode with a selection.
    c.colors.statusbar.caret.selection.bg = palette['background']

    ## Foreground color of the statusbar in caret mode with a selection.
    c.colors.statusbar.caret.selection.fg = palette['orange']

    ## Background color of the statusbar in command mode.
    c.colors.statusbar.command.bg = palette['background']

    ## Foreground color of the statusbar in command mode.
    c.colors.statusbar.command.fg = palette['pink']

    ## Background color of the statusbar in private browsing + command mode.
    c.colors.statusbar.command.private.bg = palette['background']

    ## Foreground color of the statusbar in private browsing + command mode.
    c.colors.statusbar.command.private.fg = palette['foreground-alt']

    ## Background color of the statusbar in insert mode.
    c.colors.statusbar.insert.bg = palette['background-attention']

    ## Foreground color of the statusbar in insert mode.
    c.colors.statusbar.insert.fg = palette['foreground-attention']

    ## Background color of the statusbar.
    c.colors.statusbar.normal.bg = palette['background']

    ## Foreground color of the statusbar.
    c.colors.statusbar.normal.fg = palette['foreground']

    ## Background color of the statusbar in passthrough mode.
    c.colors.statusbar.passthrough.bg = palette['background']

    ## Foreground color of the statusbar in passthrough mode.
    c.colors.statusbar.passthrough.fg = palette['orange']

    ## Background color of the statusbar in private browsing mode.
    c.colors.statusbar.private.bg = palette['background-alt']

    ## Foreground color of the statusbar in private browsing mode.
    c.colors.statusbar.private.fg = palette['foreground-alt']

    ## Background color of the progress bar.
    c.colors.statusbar.progress.bg = palette['background']

    ## Foreground color of the URL in the statusbar on error.
    c.colors.statusbar.url.error.fg = palette['red']

    ## Default foreground color of the URL in the statusbar.
    c.colors.statusbar.url.fg = palette['foreground']

    ## Foreground color of the URL in the statusbar for hovered links.
    c.colors.statusbar.url.hover.fg = palette['cyan']

    ## Foreground color of the URL in the statusbar on successful load
    c.colors.statusbar.url.success.http.fg = palette['green']

    ## Foreground color of the URL in the statusbar on successful load
    c.colors.statusbar.url.success.https.fg = palette['green']

    ## Foreground color of the URL in the statusbar when there's a warning.
    c.colors.statusbar.url.warn.fg = palette['yellow']

    ## Status bar padding
    c.statusbar.padding = padding

    ## Background color of the tab bar.
    ## Type: QtColor
    c.colors.tabs.bar.bg = palette['selection']

    ## Background color of unselected even tabs.
    ## Type: QtColor
    c.colors.tabs.even.bg = palette['selection']

    ## Foreground color of unselected even tabs.
    ## Type: QtColor
    c.colors.tabs.even.fg = palette['foreground']

    ## Color for the tab indicator on errors.
    ## Type: QtColor
    c.colors.tabs.indicator.error = palette['red']

    ## Color gradient start for the tab indicator.
    ## Type: QtColor
    c.colors.tabs.indicator.start = palette['orange']

    ## Color gradient end for the tab indicator.
    ## Type: QtColor
    c.colors.tabs.indicator.stop = palette['green']

    ## Color gradient interpolation system for the tab indicator.
    ## Type: ColorSystem
    ## Valid values:
    ##   - rgb: Interpolate in the RGB color system.
    ##   - hsv: Interpolate in the HSV color system.
    ##   - hsl: Interpolate in the HSL color system.
    ##   - none: Don't show a gradient.
    c.colors.tabs.indicator.system = 'none'

    ## Background color of unselected odd tabs.
    ## Type: QtColor
    c.colors.tabs.odd.bg = palette['selection']

    ## Foreground color of unselected odd tabs.
    ## Type: QtColor
    c.colors.tabs.odd.fg = palette['foreground']

    # ## Background color of selected even tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.even.bg = palette['background']

    # ## Foreground color of selected even tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.even.fg = palette['foreground']

    # ## Background color of selected odd tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.odd.bg = palette['background']

    # ## Foreground color of selected odd tabs.
    # ## Type: QtColor
    c.colors.tabs.selected.odd.fg = palette['foreground']

    ## Tab padding
    c.tabs.padding = padding
    c.tabs.indicator.width = 1
    c.tabs.favicons.scale = 1


# pylint: disable=C0111
c = c  # noqa: F821 pylint: disable=E0602,C0103
config = config  # noqa: F821 pylint: disable=E0602,C0103
# pylint settings included to disable linting errors

import subprocess
# Load existing settings made via :set
config.load_autoconfig()

# load dracula theme
dracula_theme(c)

# c.url.start_pages = ""
# c.url.default_page = ""

c.tabs.title.format = "{audio}{current_title}"
c.fonts.web.size.default = 20

c.url.searchengines = {
# note - if you use duckduckgo, you can make use of its built in bangs, of which there are many! https://duckduckgo.com/bangs
        'DEFAULT': 'https://duckduckgo.com/?q={}',
        '!aw': 'https://wiki.archlinux.org/?search={}',
        '!apkg': 'https://archlinux.org/packages/?sort=&q={}&maintainer=&flagged=',
        '!gh': 'https://github.com/search?o=desc&q={}&s=stars',
        '!yt': 'https://www.youtube.com/results?search_query={}',
        }

c.completion.open_categories = ['searchengines', 'quickmarks', 'bookmarks', 'history', 'filesystem']

config.load_autoconfig() # load settings done via the gui

c.auto_save.session = True # save tabs on quit/restart

# keybinding changes
config.bind('=', 'cmd-set-text -s :open')
config.bind('h', 'history')
config.bind('cs', 'cmd-set-text -s :config-source')
config.bind('tH', 'config-cycle tabs.show multiple never')
config.bind('sH', 'config-cycle statusbar.show always never')
config.bind('T', 'hint links tab')
config.bind('pP', 'open -- {primary}')
config.bind('pp', 'open -- {clipboard}')
config.bind('pt', 'open -t -- {clipboard}')
config.bind('qm', 'macro-record')
config.bind('<ctrl-y>', 'spawn --userscript ytdl.sh')
config.bind('tT', 'config-cycle tabs.position top left')
config.bind('gJ', 'tab-move +')
config.bind('gK', 'tab-move -')
config.bind('gm', 'tab-move')

# dark mode setup
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = 'lightness-cielab'
c.colors.webpage.darkmode.policy.images = 'never'
config.set('colors.webpage.darkmode.enabled', False, 'file://*')

# styles, cosmetics
# c.content.user_stylesheets = ["~/.config/qutebrowser/styles/youtube-tweaks.css"]
c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 9, 'right': 9}
c.tabs.indicator.width = 0 # no tab indicators
# c.window.transparent = True # apparently not needed
c.tabs.width = '7%'

# fonts
c.fonts.default_family = []
c.fonts.default_size = '13pt'
c.fonts.web.family.fixed = 'monospace'
c.fonts.web.family.sans_serif = 'monospace'
c.fonts.web.family.serif = 'monospace'
c.fonts.web.family.standard = 'monospace'

# privacy - adjust these settings based on your preference
# config.set("completion.cmd_history_max_items", 0)
# config.set("content.private_browsing", True)
config.set("content.webgl", False, "*")
config.set("content.canvas_reading", False)
config.set("content.geolocation", False)
config.set("content.webrtc_ip_handling_policy", "default-public-interface-only")
config.set("content.cookies.accept", "all")
config.set("content.cookies.store", True)
# config.set("content.javascript.enabled", False) # tsh keybind to toggle

# Adblocking info -->
# For yt ads: place the greasemonkey script yt-ads.js in your greasemonkey folder (~/.config/qutebrowser/greasemonkey).
# The script skips through the entire ad, so all you have to do is click the skip button.
# Yeah it's not ublock origin, but if you want a minimal browser, this is a solution for the tradeoff.
# You can also watch yt vids directly in mpv, see qutebrowser FAQ for how to do that.
# If you want additional blocklists, you can get the python-adblock package, or you can uncomment the ublock lists here.
c.content.blocking.enabled = True
# c.content.blocking.method = 'adblock' # uncomment this if you install python-adblock
# c.content.blocking.adblock.lists = [
#         "https://github.com/ewpratten/youtube_ad_blocklist/blob/master/blocklist.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/legacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2020.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2021.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2022.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2023.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters-2024.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-cookies.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/annoyances-others.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badlists.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/quick-fixes.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/resource-abuse.txt",
#         "https://github.com/uBlockOrigin/uAssets/raw/master/filters/unbreak.txt"]
