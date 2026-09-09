# XivBar

A Windower addon that adds compliments **XivParty's assets**.
XivBar is designed as an expansion for [XivParty](https://github.com/Tylas11/XivParty) and it's suggested to be used alongside it. 
This addon highly borrows from the xivparty plugin so shares the same commands and visual style. 

## Files
XivBar.lua      The addon itself (entry point, _addon.name = 'XivBar')
XivPanel.lua    Shared handler module -- all the bar/image/scale/drag logic that
                every bar (pet, target, subtarget) uses. Not an addon on its own;
                XivBar.lua requires() it.

Both files must sit together, directly inside a folder named `XivBar`.
## Features
* Pet bar: Name, HP, MP, TP.
* Target bar: Name, HP.
* Subtarget bar: Name, HP -- only shows while you actually have a subtarget selected.
* Shared in-game setup mode for positioning and scaling all bars.
* Saves position and scale automatically.

## Commands
/xivbar setup    Toggle setup mode for ALL bars -- drag whichever bar you're pointing at to move it, mouse wheel over one to scale just it
/xivbar show     Show all bars
/xivbar hide     Hide all bars
/xivbar reset    Reset all bars to default position/scale

## Installation
1. Install **XivParty** <----Not needed but highly suggested.
2. Place the `XivBar` folder (containing `XivBar.lua` and `XivPanel.lua`) in your
   Windower `addons` directory.
3. Load the addon with:
lua load XivBar
   or put this into the chatbar:
//lua load XIVbar

That's it. Your GEO can now see the luopan -- and the enemy's HP while you're at it.
SMN and PUP and BST too... But this entire thing was created cause I couldn't see my Loupan. 
But then the position of the target bar bothered me. As did subtarget. So. Here you go. My suffering= Your benifit.

Based off Tylas11's addon. 
