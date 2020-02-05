# frameset-mac-frame-tabbing

This simple package enable saving and restoring Mac native tabs, including their positions, grouping and orientation with other tabs, etc., as part of any _frameset_ (Emacs native way of saving all frame/window and associated buffers, used e.g. by `desktop`, `desktop+` and other session management tools).  

This package is designed for and works specifically with the [emacs-mac](https://github.com/railwaycat/homebrew-emacsmacport) port and its `mac-frame-tab-group-property` commmand. 


## Installation

Not yet on MELPA, so just clone the repository and `require` it, or, if you are a `use-package` user:

```elisp
;;==> frameset-mac-save-tabs: Advise frameset to save and restore tab groups
(use-package frameset-mac-save-tabs
  :after frameset
  :load-path "/path/to/frameset-mac-save-tabs")
```

## Usage

Any command that saves or restores a `frameset`, including Emacs' native `desktop`, or any related session management package, will automatically save and restore mac tab information. 
