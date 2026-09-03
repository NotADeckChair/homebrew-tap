# Formula/redactdpdf.rb
#
# Homebrew formula for redactdPDF (private repository)
# https://github.com/NotADeckChair/redactdPDF
#
# Prerequisites — set your GitHub token before installing:
#   export HOMEBREW_GITHUB_API_TOKEN=your_github_token_here
#
# Then install with:
#   brew tap NotADeckChair/tap
#   brew install redactdpdf
#
# To update to a new version:
#   1. Create a tagged release on GitHub
#   2. curl -L https://api.github.com/repos/NotADeckChair/redactdPDF/tarball/vX.X.X \
#        -H "Authorization: bearer $HOMEBREW_GITHUB_API_TOKEN" | shasum -a 256
#   3. Update url (use api.github.com form), sha256, and version below
#   4. Commit and push to homebrew-tap

require "download_strategy"

# Custom download strategy for private GitHub repositories.
# Reads HOMEBREW_GITHUB_API_TOKEN from the environment and passes it
# as an Authorization header so Homebrew can access private release archives.
class GitHubPrivateRepositoryDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    unless @github_token
      raise CurlDownloadStrategyError,
            "HOMEBREW_GITHUB_API_TOKEN is required to install redactdpdf.\n" \
            "  export HOMEBREW_GITHUB_API_TOKEN=your_github_token_here"
    end
  end

  def _fetch(url:, resolved_url:, timeout:)
    curl_download url,
                  "--header", "Authorization: bearer #{@github_token}",
                  "--header", "Accept: application/vnd.github+json",
                  "--location",
                  to: temporary_path,
                  timeout: timeout
  end
end

class Redactdpdf < Formula
  desc     "PDF metadata scrubber, linearizer and timestamp setter"
  homepage "https://github.com/NotADeckChair/redactdPDF"
  url      "https://api.github.com/repos/NotADeckChair/redactdPDF/tarball/v0.3.2.0903.1435",
           using: GitHubPrivateRepositoryDownloadStrategy
  sha256   "187a94754661e8fa8f745399e3b59aedadcdf45e4bdaee553e88d93a92facae2"
  license  "Apache-2.0"
  version  "0.3.2.0903.1435"

  # ── Runtime dependencies ───────────────────────────────────────────────────
  depends_on "python@3.11"
  depends_on "mat2"
  depends_on "exiftool"
  depends_on "ghostscript"
  depends_on "qpdf"

  # ── Python package dependencies ────────────────────────────────────────────
  resource "rich" do
    url    "https://files.pythonhosted.org/packages/source/r/rich/rich-13.7.1.tar.gz"
    sha256 "9be308cb1fe2f1f57d67ce99e95af38a1e2bc71ad9813b0e247cf7ffbcc3a432"
  end

  # ── Install ────────────────────────────────────────────────────────────────
  def install
    # Create isolated virtualenv in libexec
    venv = libexec/"venv"
    system Formula["python@3.11"].opt_bin/"python3.11", "-m", "venv", venv

    # Install Python dependencies into the venv
    pip = venv/"bin/pip"
    resource("rich").stage do
      system pip, "install", "--no-deps", "."
    end

    # Install application source files into libexec
    libexec.install "redactd.py"
    libexec.install "lib"
    libexec.install "LICENSE"
    libexec.install "NOTICE"
    libexec.install "redactd.pl"

    # Write the bin wrapper script
    (bin/"redactd").write <<~EOS
      #!/usr/bin/env bash
      export REDACTDPDF_HOME="#{libexec}"
      export REDACTDPDF_VENV="#{libexec}/venv"
      export PYTHONPATH="#{libexec}"
      exec perl "#{libexec}/redactd.pl" "$@"
    EOS

    # Set correct permissions
    chmod 0700, libexec/"redactd.pl"
    chmod 0600, libexec/"redactd.py"
    system "find", libexec/"lib", "-name", "*.py", "-exec", "chmod", "600", "{}", ";"
  end

  # ── Caveats ────────────────────────────────────────────────────────────────
  def caveats
    <<~EOS
      redactdPDF requires a GitHub personal access token to install
      from the private repository. Set it before running brew install:

        export HOMEBREW_GITHUB_API_TOKEN=your_github_token_here

      Add this to ~/.zshrc to make it permanent.

      Optional — for HFS+ creation-date support:
        xcode-select --install
    EOS
  end

  # ── Test ───────────────────────────────────────────────────────────────────
  test do
    assert_match "0.3.1.0804.1809", shell_output("#{bin}/redactd --version")
  end
end