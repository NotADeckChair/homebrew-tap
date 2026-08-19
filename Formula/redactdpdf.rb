# Formula/redactdpdf.rb
#
# Homebrew formula for redactdPDF
# https://github.com/NotADeckChair/redactdPDF
#
# To update to a new version:
#   1. Create a tagged release on GitHub (e.g. v0.3.1.0804.1809)
#   2. Download the release archive and compute its SHA256:
#        curl -L https://github.com/NotADeckChair/redactdPDF/archive/refs/tags/v0.3.1.0804.1809.tar.gz | shasum -a 256
#   3. Update `version`, `url`, and `sha256` below
#   4. Commit and push to homebrew-tap

class Redactdpdf < Formula
  desc     "PDF metadata scrubber, linearizer and timestamp setter"
  homepage "https://github.com/NotADeckChair/redactdPDF"
  url      "https://github.com/NotADeckChair/redactdPDF/archive/refs/tags/v0.3.1.0804.1809.tar.gz"
  sha256   "REPLACE_WITH_SHA256_OF_RELEASE_ARCHIVE"
  license  "Apache-2.0"
  version  "0.3.1.0804.1809"

  # ── Runtime dependencies ───────────────────────────────────────────────────
  # Python 3.11+ required for the core engine
  depends_on "python@3.11"

  # PDF processing pipeline (step 3a–4)
  depends_on "mat2"
  depends_on "exiftool"
  depends_on "ghostscript"
  depends_on "qpdf"

  # ── Python package dependencies ────────────────────────────────────────────
  # rich — terminal display with colour and markup
  resource "rich" do
    url    "https://files.pythonhosted.org/packages/source/r/rich/rich-13.7.1.tar.gz"
    sha256 "9be308cb1fe2f1f57d67ce99e95af38a1e2bc71ad9813b0e247cf7ffbcc3a432"
  end

  # ── Install ────────────────────────────────────────────────────────────────
  def install
    # Create a virtualenv in libexec so pip packages are isolated
    venv = libexec/"venv"
    system Formula["python@3.11"].opt_bin/"python3.11", "-m", "venv", venv

    # Install Python dependencies into the venv
    pip = venv/"bin/pip"
    resource("rich").stage do
      system pip, "install", "--no-deps", "."
    end

    # Copy all application source files into libexec
    # libexec is Homebrew's standard location for files that should not
    # be directly on PATH — the wrapper script in bin/ calls them
    libexec.install "redactd.py"
    libexec.install "lib"
    libexec.install "LICENSE"
    libexec.install "NOTICE"

    # Install the Perl wrapper — this is what the user actually calls
    # We write a wrapper script in bin/ that sets the correct paths
    # and delegates to redactd.pl in libexec
    libexec.install "redactd.pl"

    # Write the bin wrapper script
    # This sets REDACTDPDF_VENV so the Python engine can find rich,
    # then delegates to the Perl wrapper in libexec
    (bin/"redactd").write <<~EOS
      #!/usr/bin/env bash
      export REDACTDPDF_HOME="#{libexec}"
      export REDACTDPDF_VENV="#{libexec}/venv"
      export PYTHONPATH="#{libexec}"
      exec perl "#{libexec}/redactd.pl" "$@"
    EOS

    # Set correct permissions — matching the project's security model
    chmod 0700, libexec/"redactd.pl"
    chmod 0600, libexec/"redactd.py"
    system "find", libexec/"lib", "-name", "*.py", "-exec", "chmod", "600", "{}", ";"
  end

  # ── Test ───────────────────────────────────────────────────────────────────
  test do
    # Verify the tool runs and reports the correct version
    assert_match "0.3.1.0804.1809", shell_output("#{bin}/redactd --version")

    # Verify dependency check works
    system "#{bin}/redactd", "--dry-run",
           "--q=67", "--dpi=110",
           "/dev/null", "2024-01-01 00:00:00"
  end
end