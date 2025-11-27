class SpryRunbook < Formula
  desc "Spry Runbook CLI - A runbook execution tool"
  homepage "https://github.com/programmablemd/packages"
  version "0.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/programmablemd/packages/releases/download/v0.1.0/spry-runbook-macos.tar.gz"
      sha256 "PLACEHOLDER_MACOS_SHA256"
    else
      url "https://github.com/programmablemd/packages/releases/download/v0.1.0/spry-runbook-macos.tar.gz"
      sha256 "PLACEHOLDER_MACOS_SHA256"
    end
  end

  on_linux do
    url "https://github.com/programmablemd/packages/releases/download/v0.1.0/spry-sqlpage_0.1.0-ubuntu22.04u1_amd64.deb"
    sha256 "95a1f8c423fd6848ebb02bc2603a724fbbb7109420a8acc968fb151167386827"
  end

  def install
    if OS.mac?
      bin.install "spry-runbook-macos" => "spry-runbook"
    elsif OS.linux?
      # For Linux, extract the DEB package using dpkg-deb
      system "dpkg-deb", "-x", "spry-sqlpage_0.1.0-ubuntu22.04u1_amd64.deb", "."
      bin.install "usr/bin/spry-runbook"
    end
  end

  test do
    system "#{bin}/spry-runbook", "--version"
  end
end

