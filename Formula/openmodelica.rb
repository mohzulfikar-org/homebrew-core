class Openmodelica < Formula
  desc "Open-source modeling and simulation tool"
  homepage "https://openmodelica.org/"
  # GitHub's archives lack submodules, must pull:
  url "https://github.com/OpenModelica/OpenModelica.git",
      tag:      "v1.18.0",
      revision: "49be4faa5a625a18efbbd74cc2f5be86aeea37bb"
  license "GPL-3.0-only"
  revision 4
  head "https://github.com/OpenModelica/OpenModelica.git", branch: "master"

  bottle do
    sha256 cellar: :any, arm64_monterey: "d9e65f475d509a52bba2a5cc5e226cf4db2cc26e634c6d3808a070b86104b8bc"
    sha256 cellar: :any, arm64_big_sur:  "0b75f8ac2ef95f961c7552390a7d4af7c22295c72957586d2bb080c1d3e98a28"
    sha256 cellar: :any, monterey:       "2973059a681603e60c7c2095374fdab3182a1b24ec67f994d809f4d9a69cbd36"
    sha256 cellar: :any, big_sur:        "a45f82e9fe3235f819537dc3f32320b7ec7a4df2c41ecf15c2c569dc97f5490e"
    sha256 cellar: :any, catalina:       "04dd6804347ec497df8850da688230d035a678c8a05cd146ba8bfa7e2a992f84"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "cmake" => :build
  depends_on "gcc" => :build # for gfortran
  depends_on "gnu-sed" => :build
  depends_on "libtool" => :build
  depends_on "openjdk" => :build
  depends_on "pkg-config" => :build

  depends_on "boost"
  depends_on "gettext"
  depends_on "hdf5"
  depends_on "hwloc"
  depends_on "lp_solve"
  depends_on "omniorb"
  depends_on "openblas"
  depends_on "qt@5"
  depends_on "readline"
  depends_on "sundials"

  uses_from_macos "curl"
  uses_from_macos "expat"
  uses_from_macos "libffi", since: :catalina
  uses_from_macos "ncurses"

  # Fix -flat_namespace being used on Big Sur and later.
  # We patch `libtool.m4` and not `configure` because we call `autoreconf`
  patch :DATA

  def install
    if MacOS.version >= :catalina
      ENV.append_to_cflags "-I#{MacOS.sdk_path_if_needed}/usr/include/ffi"
    else
      ENV.append_to_cflags "-I#{Formula["libffi"].opt_include}"
    end
    args = %W[
      --prefix=#{prefix}
      --disable-debug
      --disable-modelica3d
      --with-cppruntime
      --with-hwloc
      --with-lapack=-lopenblas
      --with-omlibrary=core
      --with-omniORB
    ]

    system "autoreconf", "--install", "--verbose", "--force"
    system "./configure", *args
    # omplot needs qt & OpenModelica #7240.
    # omparser needs OpenModelica #7247
    # omshell, omedit, omnotebook, omoptim need QTWebKit: #19391 & #19438
    # omsens_qt fails with: "OMSens_Qt is not supported on MacOS"
    system "make", "omc", "omlibrary-core", "omsimulator"
    prefix.install Dir["build/*"]
  end

  test do
    system "#{bin}/omc", "--version"
    system "#{bin}/OMSimulator", "--version"
    (testpath/"test.mo").write <<~EOS
      model test
      Real x;
      initial equation x = 10;
      equation der(x) = -x;
      end test;
    EOS
    assert_match "class test", shell_output("#{bin}/omc #{testpath/"test.mo"}")
  end
end

__END__
--- a/OMCompiler/3rdParty/lis-1.4.12/m4/libtool.m4
+++ b/OMCompiler/3rdParty/lis-1.4.12/m4/libtool.m4
@@ -1067,16 +1067,11 @@ _LT_EOF
       _lt_dar_allow_undefined='$wl-undefined ${wl}suppress' ;;
     darwin1.*)
       _lt_dar_allow_undefined='$wl-flat_namespace $wl-undefined ${wl}suppress' ;;
-    darwin*) # darwin 5.x on
-      # if running on 10.5 or later, the deployment target defaults
-      # to the OS version, if on x86, and 10.4, the deployment
-      # target defaults to 10.4. Don't you love it?
-      case ${MACOSX_DEPLOYMENT_TARGET-10.0},$host in
-	10.0,*86*-darwin8*|10.0,*-darwin[[91]]*)
-	  _lt_dar_allow_undefined='$wl-undefined ${wl}dynamic_lookup' ;;
-	10.[[012]][[,.]]*)
+    darwin*)
+      case ${MACOSX_DEPLOYMENT_TARGET},$host in
+	10.[[012]],*|,*powerpc*)
 	  _lt_dar_allow_undefined='$wl-flat_namespace $wl-undefined ${wl}suppress' ;;
-	10.*)
+	*)
 	  _lt_dar_allow_undefined='$wl-undefined ${wl}dynamic_lookup' ;;
       esac
     ;;
