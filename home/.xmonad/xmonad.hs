{-# LANGUAGE DeriveDataTypeable #-}
import Control.Monad (liftM2)
import Data.List (isPrefixOf)

import XMonad
import XMonad.Hooks.DynamicLog (
        shorten, statusBar, xmobar, xmobarColor, xmobarPP, PP(..)
    )
import XMonad.Hooks.ManageDocks (manageDocks, docksEventHook, avoidStruts)
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Run (runInTerm)
import XMonad.Util.Themes (ThemeInfo(..))
import XMonad.Layout.Decoration (Theme(..), defaultTheme)
import XMonad.Actions.CycleWS (
        nextScreen,  swapNextScreen, prevScreen, swapPrevScreen
    )
import XMonad.Layout.Tabbed (tabbed, shrinkText)
import XMonad.Layout.LayoutBuilder (layoutN, layoutAll, relBox, IncLayoutN(..))
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Actions.NoBorders (toggleBorder)
import XMonad.Layout.Fullscreen (
        fullscreenFull, fullscreenEventHook, fullscreenManageHook
    )

import TallTabbed
import Solarized

main = do
  config <- buildConfig
  xmonad config

buildConfig = statusBar "xmobar" myPP toggleStrutsKey myConfig
  where
    myPP = xmobarPP {
        ppCurrent = xmobarColor solarizedMagenta "",
        ppHiddenNoWindows = \workspaceId -> "",
        ppTitle = xmobarColor solarizedCyan "" . shorten 80,
        ppVisible = xmobarColor solarizedYellow "",
        ppLayout = \layout -> xmobarColor solarizedYellow ""
            $ "<action=xdotool key super+space>" ++ layout ++ "</action>",
        ppUrgent = xmobarColor solarizedRed "yellow"
      }
    toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)

myConfig = defaultConfig {
    modMask = mod4Mask,
    workspaces = myWorkspaces,
    handleEventHook = myEventHook,
    layoutHook = myLayout,
    manageHook = myManageHook,
    focusedBorderColor = solarizedYellow,
    normalBorderColor = solarizedBase02
  }
  `additionalKeysP` myKeys

myWorkspaces = clickable . (map xmobarEscape) $ workspaces
  where
    workspaces = ["✣", "⚙", "★", "4", "5", "6", "7", "8", "✉", "☺"]
    clickable list = [
        "<action=xdotool key super+" ++ show i ++ ">" ++ ws ++ "</action>" |
          (i, ws) <- zip "1234567890" list
      ]
    xmobarEscape = concatMap $ \char -> case char of
      '<' -> "<<"
      _ -> [char]

myEventHook = composeAll [
    fullscreenEventHook,
    docksEventHook
  ] 

solarizedTheme :: ThemeInfo
solarizedTheme =
    (TI "" "" "" defaultTheme) {
        themeName = "Solarized Theme",
        themeAuthor = "Julian Andrews",
        themeDescription = "Theme using Solarized's colors",
        theme = defaultTheme {
            fontName            = "xft:Deja Vu Mono:size=10",
            activeColor         = solarizedCyan,
            activeBorderColor   = solarizedBase03,
            activeTextColor     = solarizedBase03,
            inactiveColor       = solarizedBase02,
            inactiveBorderColor = solarizedBase03,
            inactiveTextColor   = solarizedBase00,
            urgentColor         = solarizedRed,
            decoHeight          = 27
          }
      }

myLayout = myHorizontal ||| myVertical ||| myFullscreenTabbed
  where
    myTabbed = tabbed shrinkText (theme solarizedTheme)
    myFullscreenTabbed = renamed [Replace "Tabbed"] . fullscreenFull $ myTabbed
    r1 = 3/5
    r2 = 1/2
    myHorizontal = renamed [Replace "Horizontal"] $ horizontal myTabbed 1 1 r1 r2
    myVertical = renamed [Replace "Vertical"] $ vertical myTabbed 1 1 r1 r2

myManageHook = composeAll [
    role =? "gimp-image-window" --> (ask >>= doF . W.sink),
    fmap (isPrefixOf "Gimp-") className --> doFloat,
    className =? "Transmission-gtk" --> doFloat,
    fmap (isPrefixOf "Sgt-") className --> doFloat,
    manageDocks,
    fullscreenManageHook,
    manageHook defaultConfig
  ]
  where role = stringProperty "WM_WINDOW_ROLE"

myKeys = [
    ("<XF86Sleep>", spawn "systemctl suspend"),
    ("<XF86HomePage>", spawn "sensible-browser"),
    ("<XF86Mail>", spawn "sensible-browser https://mail.google.com"),
    ("<XF86Calculator>", runInTerm "" "python" ),
    ("<XF86AudioMute>", spawn "amixer -qD pulse set Master 1+ toggle"),
    ("<XF86AudioLowerVolume>", spawn "amixer -qD pulse set Master 5%- unmute"),
    ("<XF86AudioRaiseVolume>", spawn "amixer -qD pulse set Master 5%+ unmute"),
    ("M-S-z", spawn "/home/julian/.local/bin/screen-lock"),
    ("M-,", sendMessage $ IncLayoutN (-1)),
    ("M-.", sendMessage $ IncLayoutN 1),
    ("M-w", prevScreen),
    ("M-e", nextScreen),
    ("M-S-w", swapPrevScreen),
    ("M-S-e", swapNextScreen),
    ("M-a", withFocused toggleBorder)
  ] ++ [
    ("M-" ++ modMasks ++ [key], action tag) |
      (tag, key)  <- zip myWorkspaces "1234567890",
      (modMasks, action) <- [
          ("", windows . W.greedyView),
          ("S-", windows . W.shift)
        ]
  ]
