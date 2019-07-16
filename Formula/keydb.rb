class Keydb < Formula
  desc "A Multithreaded Fork of Redis"
  homepage "https://keydb.dev"
  url "https://github.com/JohnSully/KeyDB/archive/v0.9.5.tar.gz"
  sha256 "383aefcf44545ce3fc0a8498f6ecab8a7cb99a31229fe6a78c55260794e99d55"
  head "https://github.com/JohnSully/KeyDB.git", :branch => "master"


  def install
    # Architecture isn't detected correctly on 32bit Snow Leopard without help
    ENV["OBJARCH"] = "-arch #{MacOS.preferred_arch}"

    system "make", "install", "PREFIX=#{prefix}", "CC=#{ENV.cc}"

    %w[run db/keydb log].each { |p| (var/p).mkpath }

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis_6379.pid", var/"run/keydb.pid"
      s.gsub! "dir ./", "dir #{var}/db/keydb/"
      s.sub!  /^bind .*$/, "bind 127.0.0.1 ::1"
    end

    etc.install "redis.conf" => "keydb.conf"
    etc.install "sentinel.conf" => "keydb-sentinel.conf"
  end

  plist_options :manual => "keydb-server #{HOMEBREW_PREFIX}/etc/keydb.conf"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/keydb-server</string>
          <string>#{etc}/keydb.conf</string>
          <string>--daemonize no</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/keydb.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/keydb.log</string>
      </dict>
    </plist>
  EOS
  end

  test do
    system bin/"keydb-server", "--test-memory", "2"
    %w[run db/keydb log].each { |p| assert_predicate var/p, :exist?, "#{var/p} doesn't exist!" }
  end
end
