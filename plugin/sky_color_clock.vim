"=============================================================================
" File: sky_color_clock.vim
" Author: mopp
" Created: 2018-01-18
"=============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if exists('s:is_loaded')
    finish
endif
let s:is_loaded = 1


" Local immutable variables.
let s:pi = 3.14159265359


" degrees = radian * 180 / pi.
function! s:rad_to_deg(r) abort
    return a:r * 180.0 / s:pi
endfunction


" radian = degrees * pi / 180.
function! s:deg_to_rad(d) abort
    return a:d * s:pi / 180.0
endfunction


function! s:get_sunset_time_from_noon(timestamp) abort
    let current_year = str2nr(strftime('%Y', a:timestamp))
    let leap_count   = count(map(range(1970, current_year - 1), 'v:val % 400 == 0 || (v:val % 4 == 0 && v:val % 100 != 0)'), 1)
    let day_of_year  = float2nr(a:timestamp / (24 * 60 * 60)) % 365 - leap_count - 1

    let latitude          = s:deg_to_rad(g:sky_color_clock#latitude)
    let sun_declination   = s:deg_to_rad(-23.44 * (cos(s:deg_to_rad((360 / 365.0) * (day_of_year + 10)))))
    let sunset_hour_angle = acos(-1 * tan(latitude * tan(sun_declination)))
    return 24.0 * (s:rad_to_deg(sunset_hour_angle) / 360.0)
endfunction


function! s:default_color_stops(timestamp) abort
    let sunset_time_from_noon = s:get_sunset_time_from_noon(a:timestamp)
    let sunrise               = 12 - sunset_time_from_noon
    let sunset                = 12 + sunset_time_from_noon
    return [
                \ [sunrise - 2.0,          "#111111"],
                \ [sunrise - 1.5,          "#4d548a"],
                \ [sunrise - 1.0,          "#c486b1"],
                \ [sunrise - 0.5,          "#ee88a0"],
                \ [sunrise,                "#ff7d75"],
                \ [sunrise + 0.5,          "#f4eeef"],
                \ [(sunset + sunrise) / 2, "#5dc9f1"],
                \ [sunset - 1.5,           "#9eefe0"],
                \ [sunset - 1.0,           "#f1e17c"],
                \ [sunset - 0.5,           "#f86b10"],
                \ [sunset,                 "#100028"],
                \ [sunset + 0.5,           "#111111"],
                \ ]
endfunction


" Define global variables.
let g:sky_color_clock#latitude                = get(g:, 'sky_color_clock#latitude', 35)
let g:sky_color_clock#color_stops             = get(g:, 'sky_color_clock#color_stops', s:default_color_stops(localtime()))
let g:sky_color_clock#datetime_format         = get(g:, 'sky_color_clock#datetime_format', '%d %H:%M')
let g:sky_color_clock#enable_emoji_icon       = get(g:, 'sky_color_clock#enable_emoji_icon', has('mac'))
let g:sky_color_clock#temperature_color_stops = get(g:, 'sky_color_clock#temperature_color_stops', [
            \ [263, '#00a1ff'],
            \ [288, '#ffffff'],
            \ [313, '#ffa100']
            \ ])

let g:sky_color_clock#openweathermap_api_key = get(g:, 'sky_color_clock#openweathermap_api_key', exists('$OPENWEATHERMAP_API_KEY') ? expand('$OPENWEATHERMAP_API_KEY') : '')
let g:sky_color_clock#openweathermap_city_id = get(g:, 'sky_color_clock#openweathermap_city_id', '1850144')


" for preload.
call sky_color_clock#statusline()



let &cpo = s:save_cpo
unlet s:save_cpo
