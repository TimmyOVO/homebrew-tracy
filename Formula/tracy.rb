class Tracy < Formula
  desc "Real-time, nanosecond resolution frame profiler"
  homepage "https://github.com/wolfpld/tracy"
  url "https://github.com/wolfpld/tracy/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "b0e972dfeebe42470187c1a47b449c8ee9e8656900bcf87b403175ed50796918"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "capstone"
  depends_on "freetype"
  depends_on "zstd"

  on_macos do
    depends_on "glfw"
  end

  on_linux do
    depends_on "wayland-protocols" => :build
    depends_on "dbus"
    depends_on "libxkbcommon"
    depends_on "mesa"
    depends_on "tbb"
    depends_on "wayland"
  end

  def install
    # Prefer system libraries where possible; Homebrew forbids using
    # FetchContent/CPM for common deps like zstd.
    inreplace "cmake/vendor.cmake" do |s|
      s.gsub! <<~OLD, <<~NEW
        # Zstd

        CPMAddPackage(
            NAME zstd
            GITHUB_REPOSITORY facebook/zstd
            GIT_TAG v1.5.7
            OPTIONS
                "ZSTD_BUILD_SHARED OFF"
            EXCLUDE_FROM_ALL TRUE
            SOURCE_SUBDIR build/cmake
        )
      OLD
        # Zstd

        pkg_check_modules(ZSTD libzstd)
        if (ZSTD_FOUND)
            add_library(libzstd INTERFACE)
            target_include_directories(libzstd INTERFACE ${ZSTD_INCLUDE_DIRS})
            target_link_libraries(libzstd INTERFACE ${ZSTD_LINK_LIBRARIES})
        else()
            CPMAddPackage(
                NAME zstd
                GITHUB_REPOSITORY facebook/zstd
                GIT_TAG v1.5.7
                OPTIONS
                    "ZSTD_BUILD_SHARED OFF"
                EXCLUDE_FROM_ALL TRUE
                SOURCE_SUBDIR build/cmake
            )
        endif()
      NEW
    end

    # Capstone 5.x renamed the AArch64 API to ARM64 (CS_ARCH_ARM64,
    # ARM64_OP_IMM, and the cs_detail::arm64 union member). Patch Tracy's
    # server code to match the Capstone version shipped by Homebrew.
    inreplace "server/TracyWorker.cpp" do |s|
      s.gsub! "CS_ARCH_AARCH64", "CS_ARCH_ARM64"
      s.gsub! "detail.aarch64", "detail.arm64"
      s.gsub! "AARCH64_OP_IMM", "ARM64_OP_IMM"
    end

    # The profiler frontend also uses the old AArch64 names when
    # inspecting operands; adjust them to the ARM64 naming used by
    # capstone 5.x.
    inreplace "profiler/src/profiler/TracySourceView.cpp" do |s|
      s.gsub! "CS_ARCH_AARCH64", "CS_ARCH_ARM64"
      s.gsub! "detail.aarch64", "detail.arm64"
      s.gsub! "AARCH64_OP_IMM", "ARM64_OP_IMM"
      s.gsub! "AARCH64_OP_REG", "ARM64_OP_REG"
      s.gsub! "AARCH64_OP_MEM", "ARM64_OP_MEM"
    end

    args = %w[CAPSTONE GLFW FREETYPE].map { |arg| "-DDOWNLOAD_#{arg}=OFF" }
    args << "-DHOMEBREW_ALLOW_FETCHCONTENT=ON"

    buildpath.each_child do |child|
      next unless child.directory?
      next unless (child/"CMakeLists.txt").exist?
      next if %w[python test].include?(child.basename.to_s)

      system "cmake", "-S", child, "-B", child/"build", *args, *std_cmake_args
      system "cmake", "--build", child/"build"
      bin.install child.glob("build/tracy-*").select(&:executable?)
    end

    system "cmake", "-S", ".", "-B", "build",
           "-DBUILD_SHARED_LIBS=ON", "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    bin.install_symlink "tracy-profiler" => "tracy"
  end

  test do
    assert_match "Tracy Profiler #{version}", shell_output("#{bin}/tracy --help")

    port = free_port
    pid = spawn bin/"tracy", "-p", port.to_s
    sleep 1
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
