class Mongotools < Formula
  desc "CLI tool for MongoDB collection management (mmv and mcp)"
  homepage "https://github.com/yourusername/mongotools"
  url "https://github.com/yourusername/mongotools/archive/v1.0.0.tar.gz"
  sha256 "your_tarball_sha256"

  depends_on "mongodb/brew/mongodb-community-shell"

  def install
    bin.install "mongotool.sh"
    bin.install_symlink bin/"mongotool.sh" => "mmv"
    bin.install_symlink bin/"mongotool.sh" => "mcp"
  end

  def caveats
    <<~EOS
      This tool requires `mongoimport` and `mongoexport`, which are included in the MongoDB shell package.
    EOS
  end

  test do
    system "#{bin}/mmv", "--version"
    system "#{bin}/mcp", "--version"
  end
end
