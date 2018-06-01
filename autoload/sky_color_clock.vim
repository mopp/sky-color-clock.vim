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
let s:moonphase_cycle = 29.5306 " Eclipse (synodic month) cycle in days.
let s:new_moon_base_timestamp = 6.8576 " A new moon (1970/01/08 05:35) in days since the epoch.
let s:moonphase_emojis = [
            \ [ 1.84, '🌑'],
            \ [ 5.53, '🌒'],
            \ [ 9.22, '🌓'],
            \ [12.91, '🌔'],
            \ [16.61, '🌕'],
            \ [20.30, '🌖'],
            \ [23.99, '🌗'],
            \ [27.68, '🌘'],
            \ ]


" https://github.com/Qix-/color-convert/blob/427cbb70540bb9e5b3e94aa3bb9f97957ee5fbc0/conversions.js#L555-L580
" https://stackoverflow.com/a/39277954
" https://stackoverflow.com/a/41978310
" https://github.com/tmux/tmux/blob/591b26e46f48f2e6b59f97e6cfb037c6fec48e15/colour.c#L57
" string -> number.
let s:q2c = [0, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
function! s:to_ansi256_color(rgb) abort
    let rgb = s:parse_rgb(a:rgb)
    let r = float2nr(rgb[0] * 255.0)
    let g = float2nr(rgb[1] * 255.0)
    let b = float2nr(rgb[2] * 255.0)

    let qr = s:color_to_6cube(r)
    let qg = s:color_to_6cube(g)
    let qb = s:color_to_6cube(b)
    let cr = s:q2c[qr]
    let cg = s:q2c[qg]
    let cb = s:q2c[qb]

    if cr == r && cg == g && cb == b
        return (16 + (36 * qr) + (6 * qg) + qb)
    endif

    let grey_avg   = (r + g + b) / 3
    let gray_index = 238 < grey_avg ? 23 : (grey_avg - 3) / 10
    let grey       = 8 + 10 * gray_index

    let rgb       = [r, g, b]
    let color_err = s:dist(rgb, [cr, cg, cb])
    let gray_err  = s:dist(rgb, [grey, grey, grey])

    return color_err <= gray_err ? (16 + (36 * qr + 6 * qg + qb)) : (232 + gray_index)
endfunction


function! s:dist(v1, v2) abort
    let sum = 0
    let len = len(a:v1) - 1
    for i in range(0, len)
        let sum = sum + pow(a:v1[i] - a:v2[i], 2)
    endfor

    return sum / len
endfunction


function! s:color_to_6cube(v) abort
    return a:v < 48 ? 0 : a:v < 114 ? 1 : (a:v - 35) / 40
endfunction


" https://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
" [float] -> [float].
function! s:rgb_to_hsl(rgb) abort
    let max = 0.0
    let min = 1.0
    for c in a:rgb
        if max < c
            let max = c
        endif
        if c < min
            let min = c
        endif
    endfor

    let l = (max + min) / 2.0
    let delta = max - min

    if abs(delta) <= 1.0e-10
        return [0.0, 0.0, l]
    endif

    let s = (l <= 0.5) ? (delta / (max + min)) : (delta / (2.0 - max - min))

    let [r, g, b] = a:rgb
    let rc = (max - r) / delta
    let gc = (max - g) / delta
    let bc = (max - b) / delta

    if max == r
        let h = bc - gc
    elseif max == g
        let h = 2.0 + rc - bc
    else
        let h = 4.0 + gc - rc
    endif

    let h = fmod(h / 6.0, 1.0)

    if h < 0.0
        let h = 1.0 + h
    endif

    return [h, s, l]
endfunction


function! s:hue_to_rgb(p, q, t) abort
    let t = a:t
    if 1.0 < a:t
        let t = a:t - 1.0
    elseif a:t < 0.0
        let t = a:t + 1.0
    endi

    if (t < 1.0 / 6.0) | return a:p + (a:q - a:p) * 6.0 * t | endif
    if (t < 1.0 / 2.0) | return a:q | endif
    if (t < 2.0 / 3.0) | return a:p + (a:q - a:p) * (2.0 / 3.0 - t) * 6.0 | endif

    return a:p
endfunction


function! s:hsl_to_rgb(hsl) abort
    let [h, s, l] = a:hsl

    let q = l <= 0.5 ? l * (1.0 + s) : l + s - l * s
    let p = 2.0 * l - q
    let r = s:hue_to_rgb(p, q, h + 1.0 / 3.0)
    let g = s:hue_to_rgb(p, q, h)
    let b = s:hue_to_rgb(p, q, h - 1.0 / 3.0)

    return [r, g, b]
endfunction


" https://hail2u.net/blog/software/convert-hex-color-to-functional-color-with-vim.html
" (string) -> [float].
function! s:parse_rgb(rgb) abort
    let rgb = matchlist(a:rgb, '\([0-9A-F]\{2\}\)\([0-9A-F]\{2\}\)\([0-9A-F]\{2\}\)')[1:3]
    return map(rgb, 'str2nr(v:val, 16) / 255.0')
endfunction


" (float, float, float) -> string.
function! s:to_rgb_string(rgb) abort
    let [r, g, b] = a:rgb
    let r = float2nr(ceil(r * 255.0))
    let g = float2nr(ceil(g * 255.0))
    let b = float2nr(ceil(b * 255.0))
    return printf('#%02x%02x%02x', r, g, b)
endfunction


" (string, string, float) -> string.
function! s:blend_color(base_color, mix_color, fraction) abort
    let x = a:fraction == 0.0 ? 0.5 : a:fraction
    let y = 1.0 - x

    let [r1, g1, b1] = s:parse_rgb(a:base_color)
    let [r2, g2, b2] = s:parse_rgb(a:mix_color)

    let r = (r1 * y) + (r2 * x)
    let g = (g1 * y) + (g2 * x)
    let b = (b1 * y) + (b2 * x)

    return s:to_rgb_string([r, g, b])
endfunction


function! s:make_gradient(color_stops, x) abort
    let first_color = a:color_stops[0]
    if a:x <= first_color[0]
        return first_color[1]
    endif

    let last_color = a:color_stops[0]
    for next_color in a:color_stops
        if a:x <= next_color[0]
            let fraction = ((a:x - last_color[0]) / (next_color[0] - last_color[0]))
            return s:blend_color(last_color[1], next_color[1], fraction)
        endif
        let last_color = next_color
    endfor

    return a:color_stops[-1][1]
endfunction


function! s:pick_bg_color(timestamp) abort
    let [sec, min, hour] = split(strftime('%S,%M,%H', a:timestamp), ',')
    let t = sec / 60.0
    let x = ((t + min) / 60.0) + hour

    return s:make_gradient(g:sky_color_clock#color_stops, x)
endfunction


function! s:pick_fg_color(bg_color) abort
    let [h, s, l] = s:rgb_to_hsl(s:parse_rgb(a:bg_color))
    let new_l = l + (0.5 < l ? -0.55 : 0.55)
    let new_l = (new_l < 0.0) ? 0.0 : new_l
    let new_l = (1.0 < new_l) ? 1.0 : new_l

    return s:to_rgb_string(s:hsl_to_rgb([h, s, new_l]))
endfunction


function! s:get_emoji_moonphase(timestamp) abort
    let time_in_days = a:timestamp / (24.0 * 60.0 * 60.0)
    let current_phase = fmod(time_in_days - s:new_moon_base_timestamp, s:moonphase_cycle)

    for [phase, emoji] in s:moonphase_emojis
        if current_phase <= phase
            return emoji
        endif
    endfor

    return s:moonphase_emojis[-1][1]
endfunction


function! s:get_sky_colors(timestamp) abort
    let bg = s:pick_bg_color(a:timestamp)
    let fg = s:pick_fg_color(bg)

    " Convert the RGB string into ANSI 256 color.
    let bg_t = s:to_ansi256_color(bg)
    let fg_t = s:to_ansi256_color(fg)

    return [fg, bg, fg_t, bg_t]
endfunction


let s:last_update_timestamp = localtime()
let s:statusline_cache = ''
function! sky_color_clock#statusline() abort
    if exists('g:sky_color_clock#timestamp_force_override')
        let now = g:sky_color_clock#timestamp_force_override
    else
        let now = localtime()
    endif

    let statusline = strftime(g:sky_color_clock#datetime_format, now)

    if statusline ==# strftime(g:sky_color_clock#datetime_format, s:last_update_timestamp) && !empty(s:statusline_cache) && !empty(synIDattr(synIDtrans(hlID('SkyColorClock')), 'fg'))
        return s:statusline_cache
    endif
    let s:last_update_timestamp = now

    let [fg, bg, fg_t, bg_t] = s:get_sky_colors(now)

    " Update highlight.
    execute printf('hi SkyColorClock guifg=%s guibg=%s ctermfg=%d ctermbg=%d ', fg, bg, fg_t, bg_t)

    if g:sky_color_clock#enable_emoji_icon != 0
        let statusline = printf("%s %s", s:get_emoji_moonphase(now), statusline)
    endif

    let s:statusline_cache = statusline
    return statusline
endfunction


function! sky_color_clock#preview() abort
    let now = localtime()
    let base_timestamp = (now - (now % (24 * 60 * 60))) - (9 * 60 * 60)

    tabnew
    syntax clear

    let cnt = 0
    let last_colors = s:get_sky_colors(base_timestamp)
    for h in range(0, 23)
        for m in range(0, 55, 5)
            let t = base_timestamp + (h * 60 * 60) + (m * 60)

            let colors = s:get_sky_colors(t)

            if last_colors == colors
                continue
            endif

            let last_colors = colors
            let [fg, bg, fg_t, bg_t] = colors
            let str = strftime(g:sky_color_clock#datetime_format, t)

            call append(cnt, str)

            let group_name = printf('SkyColorClockPreview%d', cnt)
            execute printf('hi %s guifg=%s guibg=%s ctermfg=%d ctermbg=%d', group_name, fg, bg, fg_t, bg_t)
            execute printf('syntax keyword %s %s', group_name, escape(str, ' '))
            execute printf('syntax match %s /%s/', group_name, escape(str, ' '))

            let cnt += 1
        endfor
    endfor
endfunction


function! s:get_current_weather_info() abort
    if executable('curl')
        let cmd = 'curl --silent '
    elseif executable('wget')
        let cmd = 'wget -q -O - '
    else
        throw 'curl and wget is not found !'
    endif


    let uri = printf('http://api.openweathermap.org/data/2.5/weather?id=%s&appid=%s',
                \ g:sky_color_clock#openweathermap_city_id,
                \ g:sky_color_clock#openweathermap_api_key)
    if has('job')
        return job_start(cmd . uri, {'out_cb': function('s:apply_temperature_highlight')})
    else
        return system(cmd . shellescape(uri))
    endif
endfunction


function! s:define_temperature_highlight() abort
    try
        let weather_res = s:get_current_weather_info()
        if type(weather_res) == v:t_string
            call s:apply_temperature_highlight(-1, weather_res)
        endif
    catch /.*/
    endtry
endfunction


function! s:apply_temperature_highlight(ch, out) abort
    let weather_dict = eval(a:out)
    let temp = weather_dict.main.temp

    let bg = s:make_gradient(g:sky_color_clock#temperature_color_stops, temp)
    let bg_t = s:to_ansi256_color(bg)
    execute printf('hi SkyColorClockTemp guibg=%s ctermbg=%d ', bg, bg_t)
endfunction


if !empty(g:sky_color_clock#openweathermap_api_key)
    call s:define_temperature_highlight()
endif

let s:enable_test = 0
if s:enable_test
    call assert_equal('#000000', s:to_rgb_string(s:hsl_to_rgb([0.0, 0.0, 0.0])))
    call assert_equal('#ffffff', s:to_rgb_string(s:hsl_to_rgb([0.0, 0.0, 1.0])))
    call assert_equal('#ff0000', s:to_rgb_string(s:hsl_to_rgb([0.0, 1.0, 0.5])))
    call assert_equal('#00ff00', s:to_rgb_string(s:hsl_to_rgb([120.0 / 360.0, 1.0, 0.5])))
    call assert_equal('#0000ff', s:to_rgb_string(s:hsl_to_rgb([240.0 / 360.0, 1.0, 0.5])))
    call assert_equal('#ffff00', s:to_rgb_string(s:hsl_to_rgb([60.0 / 360.0, 1.0, 0.5])))
    call assert_equal('#00ffff', s:to_rgb_string(s:hsl_to_rgb([180.0 / 360.0, 1.0, 0.5])))
    call assert_equal('#ff00ff', s:to_rgb_string(s:hsl_to_rgb([300.0 / 360.0, 1.0, 0.5])))
    call assert_equal('#c0c0c0', s:to_rgb_string(s:hsl_to_rgb([0.0, 0.0, 0.75])))
    call assert_equal('#808080', s:to_rgb_string(s:hsl_to_rgb([0.0, 0.0, 0.50])))
    call assert_equal('#800000', s:to_rgb_string(s:hsl_to_rgb([0.0, 1.0, 0.25])))
    call assert_equal('#808000', s:to_rgb_string(s:hsl_to_rgb([60.0 / 360.0, 1.0, 0.25])))
    call assert_equal('#008000', s:to_rgb_string(s:hsl_to_rgb([120.0 / 360.0, 1.0, 0.25])))
    call assert_equal('#800080', s:to_rgb_string(s:hsl_to_rgb([300.0 / 360.0, 1.0, 0.25])))
    call assert_equal('#008080', s:to_rgb_string(s:hsl_to_rgb([180.0 / 360.0, 1.0, 0.25])))
    call assert_equal('#000080', s:to_rgb_string(s:hsl_to_rgb([240.0 / 360.0, 1.0, 0.25])))

    " call assert_equal([0.0,           0.0, 0.00], s:rgb_to_hsl(s:parse_rgb('#000000')))
    " call assert_equal([0.0,           0.0, 1.00], s:rgb_to_hsl(s:parse_rgb('#ffffff')))
    " call assert_equal([0.0,           1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#ff0000')))
    " call assert_equal([120.0 / 360.0, 1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#00ff00')))
    " call assert_equal([240.0 / 360.0, 1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#0000ff')))
    " call assert_equal([60.0 / 360.0,  1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#ffff00')))
    " call assert_equal([180.0 / 360.0, 1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#00ffff')))
    " call assert_equal([300.0 / 360.0, 1.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#ff00ff')))
    " call assert_equal([0.0,           0.0, 0.75], s:rgb_to_hsl(s:parse_rgb('#c0c0c0')))
    " call assert_equal([0.0,           0.0, 0.50], s:rgb_to_hsl(s:parse_rgb('#808080')))
    " call assert_equal([0.0,           1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#800000')))
    " call assert_equal([60.0 / 360.0,  1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#808000')))
    " call assert_equal([120.0 / 360.0, 1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#008000')))
    " call assert_equal([300.0 / 360.0, 1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#800080')))
    " call assert_equal([180.0 / 360.0, 1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#008080')))
    " call assert_equal([240.0 / 360.0, 1.0, 0.25], s:rgb_to_hsl(s:parse_rgb('#000080')))

    call assert_equal('🌑', s:get_emoji_moonphase(592500))
    call assert_equal('🌑', s:get_emoji_moonphase(1516155430))
    call assert_equal('🌓', s:get_emoji_moonphase(1516846630))

    if !empty(v:errors)
        for err in v:errors
            echoerr string(err)
        endfor
    endif
endif


let &cpo = s:save_cpo
unlet s:save_cpo
