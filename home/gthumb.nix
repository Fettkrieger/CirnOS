# gThumb Image Viewer configuration and keybindings
{ config, pkgs, lib, ... }:

{
  # gThumb custom keybindings (GTK accelerator format)
  # Format: (gtk_accel_path "action" "keybinding")
  # Use "" for keybinding to disable, or a combo like "<Control>x"
  #
  # Available modifiers: <Control>, <Shift>, <Alt>, <Super>
  # Special keys: Delete, Return, space, Left, Right, Up, Down, Home, End, etc.
  #
  # To find more actions: run gthumb, press Ctrl+Shift+? or check
  # ~/.config/gthumb/accels after using the app
  
  home.file.".config/gthumb/accels".text = ''
    ; gThumb accelerators - managed by Home Manager
    ; Uncomment and modify lines to customize keybindings
    
    ; === Navigation ===
    (gtk_accel_path "<Actions>/viewer/go-back" "<Alt>Left")
    (gtk_accel_path "<Actions>/viewer/go-forward" "<Alt>Right")
    (gtk_accel_path "<Actions>/viewer/go-first" "Home")
    (gtk_accel_path "<Actions>/viewer/go-last" "End")
    (gtk_accel_path "<Actions>/viewer/go-previous" "Left")
    (gtk_accel_path "<Actions>/viewer/go-next" "Right")
    ; (gtk_accel_path "<Actions>/viewer/go-up" "<Alt>Up")
    
    ; === View Controls ===
    (gtk_accel_path "<Actions>/viewer/view-fullscreen" "F11")
    (gtk_accel_path "<Actions>/viewer/view-fullscreen" "f")
    (gtk_accel_path "<Actions>/viewer/toggle-sidebar" "F9")
    (gtk_accel_path "<Actions>/viewer/toggle-statusbar" "<Control>F9")
    (gtk_accel_path "<Actions>/viewer/view-slideshow" "F5")
    
    ; === Zoom ===
    (gtk_accel_path "<Actions>/viewer/zoom-in" "plus")
    (gtk_accel_path "<Actions>/viewer/zoom-in" "equal")
    (gtk_accel_path "<Actions>/viewer/zoom-out" "minus")
    (gtk_accel_path "<Actions>/viewer/zoom-fit" "1")
    (gtk_accel_path "<Actions>/viewer/zoom-fit-width" "2")
    (gtk_accel_path "<Actions>/viewer/zoom-100" "3")
    ; (gtk_accel_path "<Actions>/viewer/zoom-200" "4")
    ; (gtk_accel_path "<Actions>/viewer/zoom-300" "5")
    
    ; === Rotation & Flip ===
    (gtk_accel_path "<Actions>/viewer/rotate-right" "r")
    (gtk_accel_path "<Actions>/viewer/rotate-left" "<Shift>r")
    (gtk_accel_path "<Actions>/viewer/flip-horizontal" "h")
    (gtk_accel_path "<Actions>/viewer/flip-vertical" "v")
    
    ; === File Operations ===
    (gtk_accel_path "<Actions>/viewer/open-location" "<Control>l")
    (gtk_accel_path "<Actions>/viewer/save" "<Control>s")
    (gtk_accel_path "<Actions>/viewer/save-as" "<Control><Shift>s")
    (gtk_accel_path "<Actions>/viewer/revert" "F6")
    (gtk_accel_path "<Actions>/viewer/print" "<Control>p")
    
    ; === Edit ===
    (gtk_accel_path "<Actions>/viewer/copy" "<Control>c")
    (gtk_accel_path "<Actions>/viewer/paste" "<Control>v")
    (gtk_accel_path "<Actions>/viewer/undo" "<Control>z")
    (gtk_accel_path "<Actions>/viewer/redo" "<Control>y")
    
    ; === File Management ===
    (gtk_accel_path "<Actions>/viewer/trash" "Delete")
    (gtk_accel_path "<Actions>/viewer/delete" "<Shift>Delete")
    (gtk_accel_path "<Actions>/viewer/rename" "F2")
    (gtk_accel_path "<Actions>/viewer/copy-to-folder" "<Control><Shift>c")
    (gtk_accel_path "<Actions>/viewer/move-to-folder" "<Control><Shift>m")
    
    ; === Selection (Browser mode) ===
    (gtk_accel_path "<Actions>/browser/select-all" "<Control>a")
    (gtk_accel_path "<Actions>/browser/select-none" "<Control><Shift>a")
    (gtk_accel_path "<Actions>/browser/invert-selection" "<Control>i")
    
    ; === Tools ===
    (gtk_accel_path "<Actions>/viewer/set-as-wallpaper" "<Control>w")
    (gtk_accel_path "<Actions>/viewer/open-with" "o")
    (gtk_accel_path "<Actions>/viewer/properties" "<Alt>Return")
    (gtk_accel_path "<Actions>/viewer/edit-metadata" "<Control>m")
    
    ; === Window ===
    (gtk_accel_path "<Actions>/viewer/close" "<Control>w")
    (gtk_accel_path "<Actions>/viewer/quit" "<Control>q")
    (gtk_accel_path "<Actions>/viewer/preferences" "<Control>comma")
    (gtk_accel_path "<Actions>/viewer/help" "F1")
    (gtk_accel_path "<Actions>/viewer/shortcuts" "<Control>question")
    
    ; === Browser specific ===
    ; (gtk_accel_path "<Actions>/browser/show-hidden" "<Control>h")
    ; (gtk_accel_path "<Actions>/browser/sort-by-name" "")
    ; (gtk_accel_path "<Actions>/browser/sort-by-date" "")
    ; (gtk_accel_path "<Actions>/browser/sort-by-size" "")
    ; (gtk_accel_path "<Actions>/browser/sort-reversed" "")
    
    ; === Editing tools (when image editor is active) ===
    ; (gtk_accel_path "<Actions>/image-editor/crop" "<Control><Shift>x")
    ; (gtk_accel_path "<Actions>/image-editor/resize" "<Control><Shift>r")
    ; (gtk_accel_path "<Actions>/image-editor/adjust-colors" "<Control><Shift>b")
    ; (gtk_accel_path "<Actions>/image-editor/enhance-auto" "<Control><Shift>e")
    ; (gtk_accel_path "<Actions>/image-editor/desaturate" "<Control><Shift>g")
    ; (gtk_accel_path "<Actions>/image-editor/negative" "<Control><Shift>n")
  '';
}
