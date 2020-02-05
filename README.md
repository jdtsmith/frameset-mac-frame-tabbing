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

## Example Desktop

Though not really related to this package, a simple way to easily switch among many _named_ desktops is below.  Just `C-c d l` and choose among the named desktops you have saved.  By default this does _not_ auto-save the open desktop (e.g. if you forget what you are doing and wander off to something else).  But you can `C-c d s` to re-save it, or save to another name, at any time.

```elisp
;;===> desktop: Some custom configs for in-built desktop sessions
(use-package desktop
  :bind (("C-c d l" . my-desktop-load)
	 ("C-c d s" . my-desktop-save)
	 ("C-c d a" . desktop-save-mode))
  :init
  (desktop-save-mode -1)
  (setq desktop-base-dir "~/.emacs.d/desktops"
	desktop-files-not-to-save "^$")	;allow tramp files
  (defun my-desktop-load (name)
    (interactive
     (list
      (completing-read "Load Desktop: "
		       (cl-remove-if
			(lambda (x) (string-match-p "^\.\.?$" x))
			(directory-files desktop-base-dir)))))
    (desktop-change-dir (expand-file-name name desktop-base-dir)))
  
  (defun my-desktop-save (name)
    (interactive
     (list
      (completing-read "Write Desktop: "
		       (cl-remove-if
			(lambda (x) (string-match-p "^\.\.?$" x))
			(directory-files desktop-base-dir))
		       nil nil (and desktop-dirname
				    (file-name-nondirectory desktop-dirname)))))
    (setq desktop-dirname (expand-file-name name desktop-base-dir))
    (if (file-exists-p desktop-dirname)
	(if (y-or-n-p (format "Desktop %s exists, overwrite? " name))
	    (progn
	      (desktop-save desktop-dirname)
	      (message "Desktop %s saved" name))
	  (message "Cancelled"))
      (make-directory desktop-dirname 'parents)
      (desktop-save desktop-dirname))))
```
