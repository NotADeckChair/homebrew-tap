# NotADeckChair Homebrew Tap

Homebrew formulae for tools published by [NotADeckChair](https://github.com/NotADeckChair).

---

## Available formulae

| formula | description | version |
|---------|-------------|---------|
| `redactdpdf` | PDF metadata scrubber, linearizer and timestamp setter | 0.3.1.0804.1809 |

---

## Installation

Add this tap once — it covers all formulae now and in future:

```bash
brew tap NotADeckChair/tap
```

Then install any tool:

```bash
brew install redactdpdf
```

Or install directly without adding the tap first:

```bash
brew install NotADeckChair/tap/redactdpdf
```

---

## redactdPDF

Strips all embedded metadata from PDF files, produces linearized
(web-optimized) output, and sets filesystem and internal PDF timestamps
to values you specify.

### Requirements

The following tools are installed automatically as Homebrew dependencies:

```
mat2          deep structural metadata removal
exiftool      metadata field operations
ghostscript   image stream recompression
qpdf          PDF linearisation
python@3.11   core engine runtime
```

Optional — for HFS+ creation-date setting:

```bash
xcode-select --install
```

### Usage

```bash
# Single file
redactd report.pdf "2024-03-15 09:30:00"

# Multiple files (up to 3)
redactd -m file1.pdf file2.pdf file3.pdf "2024-03-15 09:30:00"

# Sweep entire folder (with confirmation prompt)
redactd --sweep /path/to/folder "2024-03-15 09:30:00"

# Override Ghostscript quality and DPI
redactd --q=80 --dpi=150 report.pdf "2024-03-15 09:30:00"

# Disable differential timestamps
redactd --nodiffts --sweep /path/to/folder "2024-03-15 09:30:00"

# Dry run — validate without modifying files
redactd --dry-run report.pdf "2024-03-15 09:30:00"
```

### Source

[github.com/NotADeckChair/redactdPDF](https://github.com/NotADeckChair/redactdPDF)

---

## Updating a formula

After cutting a new release on the source repository:

```bash
# Compute SHA256 of the new release archive
curl -L https://github.com/NotADeckChair/redactdPDF/archive/refs/tags/vX.X.X.tar.gz \
  | shasum -a 256

# Update Formula/redactdpdf.rb — change url, sha256, version
# Then commit and push
git add Formula/redactdpdf.rb
git commit -m "redactdpdf: update to vX.X.X"
git push
```

Users update with:

```bash
brew update && brew upgrade redactdpdf
```

---

## Licence

The formulae in this tap are released under Apache 2.0.
Each tool's own licence applies to the installed software.