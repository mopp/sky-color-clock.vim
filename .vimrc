let &runtimepath .= ',' . expand('%:p:h')
set statusline=%#SkyColorClockTemp#\ %#SkyColorClock#%{sky_color_clock#statusline()}
