(TeX-add-style-hook
 "Chp2-draft"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("placeins" "section")))
   (TeX-run-style-hooks
    "latex2e"
    "Subfiles/packages"
    "Subfiles/litrev"
    "Subfiles/data"
    "Subfiles/results"
    "Subfiles/extensions"
    "Subfiles/appendix"
    "article"
    "art10"
    "subfiles"
    "footnote"
    "lipsum"
    "graphicx"
    "float"
    "placeins"
    "afterpage"
    "caption"
    "subcaption"
    "booktabs"
    "threeparttable"
    "multirow"
    "geometry"
    "pdflscape")
   (TeX-add-symbols
    '("inputtable" 1))
   (LaTeX-add-environments
    "origtable"
    '("table" LaTeX-env-args ["argument"] 0)))
 :latex)

