# OneBag-Emberveil
All your bags in one frame
============================================
OneBag — Emberveil / Unreal Azeroth edition
============================================

Version: 2.0.emberveil

Credits
-------
- Original addon: Kaelten (WoW Ace / classic OneBag)
- Fixed and updated for Emberveil by: Fastshot/Sundorian
- Port / adaptation assistance: Grok (xAI)

Description
-----------
OneBag replaces the default character bags with a single combined bag
window. This Emberveil build keeps the classic 1.12.1-style behavior while
working on the Unreal Azeroth (UE5) client.

Features (Emberveil)
--------------------
- All character bags combined into one frame
- Adjustable columns, scale, and padding (sliders in Menu)
- Slot outlines and optional rarity coloring
- Ammo / soul / profession bag colors
- Individual bag buttons under the frame (show/hide per bag)
- Money display with coin icons
- Clickable options menu (Menu button)
- Position remembered when you move the frame
- Saved settings per character profile (AceDB)

How to use
----------
1. Put the OneBag folder in your AddOns directory.
2. Enable OneBag at the character select screen.
3. Press B (or your bags key) to open the combined bag.
4. Click Menu on the bag window for options.

Optional companion: OneBank (same Emberveil edition) for a combined bank.

Commands
--------
/ob or /onebag — classic slash options (Menu button is preferred)

Notes for Emberveil
-------------------
- Built against Interface 11200 (classic-era API).
- Pure Lua frame setup is used where XML templates fail on the new client.
- Ace2 libraries are still embedded for DB, events, and modules.

License / origin
----------------
Based on the original OneBag by Kaelten (wowace.com era).
Emberveil fixes and updates by Fastshot/Sundorian, with assistance from Grok (xAI).
