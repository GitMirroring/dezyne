((nil
  .
  ())
 (scheme-mode
  .
  ((eval
    .
    (progn
      (defun prefix-dir-locals-dir (elt)
        (concat (locate-dominating-file buffer-file-name ".dir-locals.el") elt))
      (mapcar
       (lambda (dir) (add-to-list 'geiser-guile-load-path dir))
       (mapcar
        #'prefix-dir-locals-dir
        '("gaiag"))))))))
