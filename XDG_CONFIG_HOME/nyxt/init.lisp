(in-package :nyxt)

(define-configuration buffer
  ((override-map (let ((map (make-keymap "override-map")))
                      (define-key map "M-c" 'nyxt/web-mode:copy)
                      (define-key map "M-v" 'nyxt/web-mode:paste)
                      (define-key map "M-t" 'set-url-new-buffer)
                      (define-key map "M-r" 'reload-current-buffer)
                      (define-key map "M-w" 'delete-current-buffer)
                      (define-key map "M-p" 'switch-buffer)))))

(define-configuration buffer
  ((request-resource-hook
    (reduce #'hooks:add-hook (list
                              (url-dispatching-handler
                               'magnet-links2
                               (match-scheme "magnet")
                               (lambda (url)
                                       (uiop:launch-program
                                        `("notify-send", (quri:uri-path url)))
                                       nil)))
            :initial-value %slot-default%))))

(defvar my-search-engines
  (list
   '(
     "w"
     "https://en.wikipedia.org/w/index.php?search=~a"
     "https://en.wikipedia.org/" )
   '(
     "rt"
     "https://rutracker.org/forum/tracker.php?nm=~a"
     "https://rutracker.org/")
   '(
     "yt"
     "https://youtube.com/results?search_query=~a"
     "https://youtube.com/")
   '(
     "google"
     "https://google.com/search?q=~a"
     "https://google.com/")
   ))

(define-configuration buffer
  ((search-engines (mapcar (lambda (engine) (apply 'make-search-engine engine))
                           my-search-engines))))
