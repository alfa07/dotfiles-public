color_map = {
    'S_yellow': '#b58900',
    'S_orange': '#cb4b16',
    'S_red': '#dc322f',
    'S_magenta': '#d33682',
    'S_violet': '#6c71c4',
    'S_blue': '#268bd2',
    'S_cyan': '#2aa198',
    'S_green': '#859900',

    # ! Light
    'S_base03': '#fdf6e3',
    'S_base02': '#eee8d5',
    'S_base01': '#93a1a1',
    'S_base00': '#839496',
    'S_base0': '#657b83',
    'S_base1': '#586e75',
    'S_base2': '#073642',
    'S_base3': '#002b36',
}

color_settings = """
background              S_base03
foreground              S_base0
fading                  40
fadeColor               S_base03
cursorColor             S_base1
pointerColorBackground  S_base01
pointerColorForeground  S_base1

color0                  S_base02
color1                  S_red
color2                  S_green
color3                  S_yellow
color4                  S_blue
color5                  S_magenta
color6                  S_cyan
color7                  S_base2
color9                  S_orange
color8                  S_base03
color10                 S_base01
color11                 S_base00
color12                 S_base0
color13                 S_violet
color14                 S_base1
color15                 S_base3
"""

for (name, code) in color_map.items():
    color_settings = color_settings.replace(name, code)

print(color_settings)


