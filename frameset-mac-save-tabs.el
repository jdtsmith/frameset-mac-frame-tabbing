;; -*- lexical-binding:t -*-
;; frameset-mac-save-tabs

;; Enable framesets to save and restore frame tab groups.  Advises
;; frameset-save (to add a 'mac-frame-tab-group frame property),
;; frameset--restore-frame (to enable or disable tabbing on frame
;; creation), frameset--minibufferless-last-p (to pre-sort frames into
;; group/tab order), and frameset-restore (to reunite any tabs that
;; didn't get placed together, e.g. minibufferless frames that have to
;; be restored after their minibuffer host.).

;; (c) 2020 J.D. Smith
;; 

;; Add information on tab groups to frame parameters before saving
(defun frameset-mac-record-tabs (frame-list &rest rest)
  (let ((list (or (copy-sequence frame-list) (frame-list))))
    (dolist (frame list)
      (let ((tab-frames (mac-frame-tab-group-property frame :frames)))
	(set-frame-parameter frame 'mac-frame-tab-group
			     (cond
			      ((eq (length tab-frames)  1) ;solo
			       nil)
			      ((eq (car tab-frames) frame) ;primary
			       (cdr tab-frames))
			      (t `(secondary               ;secondary
				   ,(car tab-frames)	   ;our parent
				   ,(seq-position tab-frames frame)))))))))
(advice-add #'frameset-save :before #'frameset-mac-record-tabs)

;; Swap frames for unique frame ID in tab list
(defun frameset-mac-filter-tabs (current filtered parameters saving)
  (let ((frame-list (cdr current)))
    (if frame-list
	(if saving
	    (progn
	      (if (eq (car frame-list) 'secondary)
		  (setf (nth 1 frame-list)
			(frameset-frame-id (nth 1 frame-list)))
		(setcdr current (mapcar #'frameset-frame-id frame-list))))))
    current))
(add-to-list 'frameset-filter-alist
	     '(mac-frame-tab-group . frameset-mac-filter-tabs))

;; Sort tabs as PARENT1 SECONDARY1.1 SECONDARY1.2 PARENT2 SECONDARY2.1 ...
(defun frameset-mac-sort-tabs (orig-sort-fun state1 state2)
  (let ((tg1 (cdr (assq 'mac-frame-tab-group (car state1))))
	(tg2 (cdr (assq 'mac-frame-tab-group (car state2))))
	(has-mini1 (car-safe (cdr (assq 'frameset--mini (car state1)))))
	(has-mini2 (car-safe (cdr (assq 'frameset--mini (car state2)))))
	(orig-sort (funcall orig-sort-fun state1 state2)))
    (cond ((or (not has-mini1) (not has-mini2)) ;mini-bufferlessness wins
	   orig-sort)

	  ((and (not tg1) (not tg2)) ;both singles, irrelevant
	   orig-sort)
	  ((not tg1) t)			;singles first
	  ((not tg2) nil)
	  
	  ((and (eq (car tg1) 'secondary) (eq (car tg2) 'secondary)) ; two secondarys 
	   (if (string-equal (nth 1 tg1) (nth 1 tg2)) ; same parent!
	       (< (nth 2 tg1) (nth 2 tg2)) ; put in sibling order 
	     (string< (nth 1 tg1) (nth 1 tg2)))) ; unrelated, sort by their parent's ids
	  
	  ((not (or (eq (car tg1) 'secondary) (eq (car tg2) 'secondary))) ;two parents
	   (string< (frameset-cfg-id (car state1)) (frameset-cfg-id (car state2))))

	  (t				;one secondary, one parent
	   (let* ((secondary-2nd (eq (car tg2) 'secondary))
		  (secondarys-parent-id (nth 1 (if secondary-2nd tg2 tg1)))
		  (parents-id (frameset-cfg-id (car (if secondary-2nd state1 state2)))))
	     (if (string-equal parents-id secondarys-parent-id)
		 secondary-2nd		;parent and child: parent first
	       (funcall (if secondary-2nd #'string< #'string>) ;somebody else's
			parents-id secondarys-parent-id)))))))
(advice-add #'frameset--minibufferless-last-p :around #'frameset-mac-sort-tabs)

;; Set mac-frame-tabbing for each secondary frame to restore it in-place
(defun frameset-mac-frame-tabbing (orig-fun parameters &rest rest)
  (let* ((has-mini (car-safe (cdr (assq 'frameset--mini parameters))))
	 (mac-frame-tabbing
	  (and has-mini ; MB-less frames must be joined later
	       (eq (car-safe (cdr (assq 'mac-frame-tab-group parameters)))
		   'secondary))))
    ;; (message "Frame [%s] %s (%s,%s) - %s"
    ;; 	     (if mac-frame-tabbing "Tabbing" "NewFrame")
    ;; 	     (cdr (assq 'frameset--id parameters))
    ;; 	     (cdr (assq 'left parameters))
    ;; 	     (cdr (assq 'top parameters))
    ;; 	     (cdr (assq 'mac-frame-tab-group parameters)))
    (apply orig-fun parameters rest)))
(advice-add #'frameset--restore-frame :around #'frameset-mac-frame-tabbing)

;; Move any tabs into tab groups that were not already placed there
;; (should only be minibufferless frames that had to be restored later)
(defun frameset-mac-reunite-tabs (frameset &rest rest)
  (let ((frames (frame-list)))
    (dolist (frame frames)
      (let ((tab-ids (frame-parameter frame 'mac-frame-tab-group))
	    (tab-frames (mac-frame-tab-group-property frame :frames)))
	(cond
	 ((not tab-ids) ; should be solo
	  (when (> (length tab-frames) 1)
	    ;(message "Solo frame has %s tabs, setting nil" (length tab-frames))
	    (mac-set-frame-tab-group-property frame :frames nil)))

	 ((eq (car tab-ids) 'secondary)) ; do nothing, will get set

	 (t (let ((others ;first in a tab group
		   (mapcar (lambda (f)
			     (frameset-frame-with-id f frames)) tab-ids)))
	      (when (and others
			 (not (equal others (cdr tab-frames))))
		;(message "Re-uniting %s with %s tabs" frame (1- (length tab-ids)))
		(mac-set-frame-tab-group-property frame :frames
						  (cons frame others)))))))
      (set-frame-parameter frame 'mac-frame-tab-group nil))))
(advice-add #'frameset-restore :after #'frameset-mac-reunite-tabs)

(provide 'frameset-mac-save-tabs)
