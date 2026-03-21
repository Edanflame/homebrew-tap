class Chocotrade < Formula
  include Language::Python::Virtualenv

  desc "Chocotrade: gRPC Backend Service with macOS Menu Bar Integration"
  homepage "https://github.com/Edanflame/chocotrade"
  url "https://github.com/Edanflame/chocotrade/archive/refs/tags/v0.1.0.tar.gz"
  # 使用命令 `shasum -a 256 v0.1.0.tar.gz` 获取
  sha256 "12e4c2d29a1a9b7e9879536160ce47c3dae8de9c374cdb71e51ad13cc0aa9f64"
  license "Apache-2.0"

  depends_on "python@3.13"
  depends_on "pybind11"
  depends_on "pyside"

  def install
    # 先把文件放进 libexec
    libexec.install Dir["*"]

    # 干掉 pyside6
    inreplace libexec/"pyproject.toml" do |s|
      s.gsub!(/^.*pyside6.*\n?/, "")
    end

    system "python3.13", "-m", "venv", libexec/"venv"

    # 安装依赖
    system libexec/"venv/bin/pip", "install", "--upgrade", "pip", "setuptools"
    cd libexec do
      system libexec/"venv/bin/pip", "install", "."
    end

    # 生成启动脚本
    (bin/"chocotrade").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/venv/bin/python" -m chocotrade "$@"
    EOS
    chmod 0755, bin/"chocotrade"

    env = {
      PYTHONPATH: "#{Formula["pyside"].opt_prefix}/lib/python3.14/site-packages"
    }
    bin.env_script_all_files(libexec/"bin", env)
  end

  # --- 后台服务配置 (可选) ---
  # 如果你想让用户执行 `brew services start chocotrade` 就能启动 gRPC 服务
  service do
    run [opt_bin/"chocotrade", "server"]
    keep_alive true
    log_path var/"log/chocotrade.log"
    error_log_path var/"log/chocotrade.err.log"
  end

  test do
    # 简单的测试指令
    system "#{bin}/chocotrade", "--help"
  end
end