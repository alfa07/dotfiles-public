-- Arrange Chrome and Ghostty windows across external displays.
--
-- Home setup (DELL monitors): Ghostty on top-left, Chrome on top-right.
-- Work setup (LG HDR 4K monitors): Chrome on left, Ghostty on right.
-- Detection is by case-insensitive substring match on NSScreen.localizedName.

on dbg(msg)
    set ts to do shell script "/bin/date +%H:%M:%S.%N | cut -c1-12"
    log ("[" & ts & "] " & msg)
end dbg

on writeHelper()
    set cacheDir to (do shell script "echo $HOME") & "/.cache/arrange-displays"
    do shell script "/bin/mkdir -p " & quoted form of cacheDir
    set srcPath to cacheDir & "/get_display_bounds.swift"
    set NL to (ASCII character 10)
    set q to (ASCII character 34)   -- "
    set bs to (ASCII character 92)  -- \
    set bb to bs & bs               -- \\
    -- Helper accepts one substring argument; outputs `x y w h` lines, one per
    -- matching screen (case-insensitive contains), sorted left-to-right by x.
    set swiftLines to {¬
        "import Cocoa", ¬
        "guard let main = NSScreen.screens.first else { exit(1) }", ¬
        "let mh = main.frame.size.height", ¬
        "let needle = CommandLine.arguments[1].lowercased()", ¬
        "let matches = NSScreen.screens.filter { $0.localizedName.lowercased().contains(needle) }", ¬
        "let sorted = matches.sorted { $0.frame.origin.x < $1.frame.origin.x }", ¬
        "for s in sorted {", ¬
        "    let f = s.visibleFrame", ¬
        "    let y = mh - (f.origin.y + f.size.height)", ¬
        "    print(" & q & bs & "(Int(f.origin.x)) " & bs & "(Int(y)) " & bs & "(Int(f.size.width)) " & bs & "(Int(f.size.height))" & q & ")", ¬
        "}"}
    set AppleScript's text item delimiters to NL
    set swiftCode to swiftLines as text
    set AppleScript's text item delimiters to ""
    try
        set fh to open for access POSIX file srcPath with write permission
        set eof of fh to 0
        write swiftCode to fh
        close access fh
    on error errMsg
        try
            close access POSIX file srcPath
        end try
        error errMsg
    end try
    -- Cache the compiled binary keyed by source hash; only recompile when the
    -- source changes (i.e. when no binary for the current hash exists).
    set srcHash to do shell script "/usr/bin/shasum " & quoted form of srcPath & " | cut -c1-12"
    set binPath to cacheDir & "/get_display_bounds-" & srcHash
    set needCompile to true
    try
        do shell script "/bin/test -x " & quoted form of binPath
        set needCompile to false
    end try
    if needCompile then
        my dbg("compiling helper -> " & binPath)
        do shell script "/usr/bin/swiftc -O " & quoted form of srcPath & " -o " & quoted form of binPath
    else
        my dbg("using cached helper " & binPath)
    end if
    return binPath
end writeHelper

on getBoundsBySubstring(binPath, needle)
    my dbg("querying displays matching '" & needle & "'")
    set output to do shell script quoted form of binPath & " " & quoted form of needle
    my dbg("  -> raw output: " & output)
    set results to {}
    repeat with ln in (paragraphs of output)
        set lnText to ln as text
        if lnText is not "" then
            set AppleScript's text item delimiters to " "
            set parts to text items of lnText
            set AppleScript's text item delimiters to ""
            set end of results to {(item 1 of parts) as integer, ¬
                                   (item 2 of parts) as integer, ¬
                                   (item 3 of parts) as integer, ¬
                                   (item 4 of parts) as integer}
        end if
    end repeat
    return results
end getBoundsBySubstring

on moveWindows(processName, theX, theY, theW, theH)
    my dbg("moveWindows: " & processName & " -> {" & theX & "," & theY & "," & theW & "," & theH & "}")
    tell application "System Events"
        if not (exists process processName) then
            my dbg("  process not running: " & processName)
            return 0
        end if
        tell process processName
            set winList to (every window)
            my dbg("  found " & (count of winList) & " window(s)")
            set i to 0
            set movedCount to 0
            repeat with w in winList
                set i to i + 1
                my dbg("  window " & i & ": attempting move/resize")
                try
                    try
                        if value of attribute "AXMinimized" of w is true then
                            my dbg("    unminimizing")
                            set value of attribute "AXMinimized" of w to false
                        end if
                    end try
                    try
                        if value of attribute "AXFullScreen" of w is true then
                            my dbg("    exiting fullscreen")
                            set value of attribute "AXFullScreen" of w to false
                        end if
                    end try
                    set position of w to {theX, theY}
                    set size of w to {theW, theH}
                    set movedCount to movedCount + 1
                    my dbg("    done")
                on error errMsg
                    my dbg("    error: " & errMsg)
                end try
            end repeat
            return movedCount
        end tell
    end tell
end moveWindows

my dbg("start")
set helperPath to writeHelper()
my dbg("helper written: " & helperPath)

my dbg("activating Google Chrome")
try
    tell application "Google Chrome" to activate
on error errMsg
    my dbg("  Chrome activate error: " & errMsg)
end try

my dbg("activating Ghostty")
try
    tell application "Ghostty" to activate
on error errMsg
    my dbg("  Ghostty activate error: " & errMsg)
end try

my dbg("delay 0.5")
delay 0.5

-- Detect setup: DELL (home) takes priority, otherwise LG (work).
set dellBounds to getBoundsBySubstring(helperPath, "dell")
set lgBounds to getBoundsBySubstring(helperPath, "lg")

if (count of dellBounds) ≥ 2 then
    my dbg("home setup detected: " & (count of dellBounds) & " DELL display(s)")
    -- Ghostty -> top-left, Chrome -> top-right
    set leftBounds to item 1 of dellBounds
    set rightBounds to item (count of dellBounds) of dellBounds
    set {gx, gy, gw, gh} to leftBounds
    set {cx, cy, cw, ch} to rightBounds
    set displayCount to (count of dellBounds)
else if (count of lgBounds) ≥ 2 then
    my dbg("work setup detected: " & (count of lgBounds) & " LG display(s)")
    -- Chrome -> left, Ghostty -> right
    set leftBounds to item 1 of lgBounds
    set rightBounds to item (count of lgBounds) of lgBounds
    set {cx, cy, cw, ch} to leftBounds
    set {gx, gy, gw, gh} to rightBounds
    set displayCount to (count of lgBounds)
else
    my dbg("no recognized dual-monitor setup found (DELL=" & (count of dellBounds) & ", LG=" & (count of lgBounds) & ")")
    error "No DELL or LG dual-monitor setup detected"
end if

set windowCount to 0
set windowCount to windowCount + moveWindows("Google Chrome", cx, cy, cw, ch)
set windowCount to windowCount + moveWindows("Ghostty", gx, gy, gw, gh)

my dbg("done")
return (windowCount as text) & " windows arranged onto " & (displayCount as text) & " displays"
