## sky-color-clock.vim
This plugin is inspired by [zk-phi/sky-color-clock: [Emacs] A clock widget for modeline with sky color at the time and moonphase icon](https://github.com/zk-phi/sky-color-clock).

## Feature
- [X] A clock widget for statusline with sky color at the time.
- [X] Moonphase emoji

## installation
```vim
call dein#add('mopp/sky-color-clock.vim')

" set statusline to enable this plugin.
set statusline+=%#SkyColorClock#%{sky_color_clock#statusline()}

" For only test
let g:sky_color_clock#timestamp_force_override = 1516201200 + 12 * 60 * 60 " 12:00:00

" Configure variables.
let g:sky_color_clock#latitude
let g:sky_color_clock#color_stops
let g:sky_color_clock#datetime_format
```
