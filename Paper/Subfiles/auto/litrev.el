(TeX-add-style-hook
 "litrev"
 (lambda ()
   (LaTeX-add-labels
    "sec:litrev")
   (LaTeX-add-environments
    '("table" LaTeX-env-args ["argument"] 0)))
 :latex)

