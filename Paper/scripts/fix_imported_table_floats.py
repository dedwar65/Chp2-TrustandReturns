from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
paper = root / 'Paper'
subfiles_dir = paper / 'Subfiles'

# Find all \input{...} paths in paper subfiles and main draft
tex_sources = [paper / 'Chp2-draft.tex'] + sorted(subfiles_dir.glob('*.tex'))
input_re = re.compile(r"\\input\{([^}]+)\}")

inputs = set()
for src in tex_sources:
    text = src.read_text(encoding='utf-8')
    for m in input_re.finditer(text):
        rel = m.group(1)
        # resolve relative to source file location
        target = (src.parent / rel).resolve()
        if target.suffix == '':
            target = target.with_suffix('.tex')
        if target.exists() and target.suffix == '.tex':
            inputs.add(target)

# Only patch imported table files that contain a LaTeX table float
begin_table_re = re.compile(r"\\begin\{table\}\[[^\]]*\]")
patched = []
for path in sorted(inputs):
    txt = path.read_text(encoding='utf-8')
    new = begin_table_re.sub(r"\\begin{table}[H]", txt)
    if new != txt:
        path.write_text(new, encoding='utf-8')
        patched.append(path)

print(f"Patched {len(patched)} files")
for p in patched:
    print(p)
