# Copyright 2019 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Dependencies for the Rust `bindgen` rules"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//bindgen/3rdparty/crates:defs.bzl", "crate_repositories")

BINDGEN_VERSION = "0.65.1"

# buildifier: disable=unnamed-macro
def rust_bindgen_dependencies():
    """Declare dependencies needed for bindgen."""

    maybe(
        http_archive,
        name = "llvm-raw",
        urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-project-14.0.6.src.tar.xz"],
        strip_prefix = "llvm-project-14.0.6.src",
        sha256 = "8b3cfd7bc695bd6cea0f37f53f0981f34f87496e79e2529874fd03a2f9dd3a8a",
        build_file_content = "# empty",
        patch_args = ["-p1"],
        patches = [
            Label("//bindgen/3rdparty/patches:llvm-project.cxx17.patch"),
            Label("//bindgen/3rdparty/patches:llvm-project.incompatible_disallow_empty_glob.patch"),
        ],
    )

    maybe(
        http_archive,
        name = "rules_rust_bindgen__bindgen-cli-{}".format(BINDGEN_VERSION),
        sha256 = "33373a4e0ec8b6fa2654e0c941ad16631b0d564cfd20e7e4b3db4c5b28f4a237",
        type = "tar.gz",
        urls = ["https://crates.io/api/v1/crates/bindgen-cli/{}/download".format(BINDGEN_VERSION)],
        strip_prefix = "bindgen-cli-{}".format(BINDGEN_VERSION),
        build_file = Label("//bindgen/3rdparty:BUILD.bindgen-cli.bazel"),
    )

    crate_repositories()

# buildifier: disable=unnamed-macro
def rust_bindgen_register_toolchains(register_toolchains = True):
    """Registers the default toolchains for the `rules_rust` [bindgen][bg] rules.

    [bg]: https://rust-lang.github.io/rust-bindgen/

    Args:
        register_toolchains (bool, optional): Whether or not to register toolchains.
    """
    if register_toolchains:
        native.register_toolchains(str(Label("//bindgen:default_bindgen_toolchain")))

# buildifier: disable=unnamed-macro
def rust_bindgen_repositories():
    """**Deprecated**: Instead use [rust_bindgen_dependencies](#rust_bindgen_dependencies) and [rust_bindgen_register_toolchains](#rust_bindgen_register_toolchains)"""

    rust_bindgen_dependencies()
    rust_bindgen_register_toolchains()

_COMMON_WORKSPACE = """\
workspace(name = "{}")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_cc",
    urls = ["https://github.com/bazelbuild/rules_cc/releases/download/0.0.1/rules_cc-0.0.1.tar.gz"],
    sha256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241",
)
"""

_CLANG_BUILD_FILE = """\
load("@rules_cc//cc:defs.bzl", "cc_import")

package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "clang",
    srcs = ["bin/clang"],
)

cc_import(
    name = "libclang",
    shared_library = "lib/libclang.{suffix}",
)

alias(
    name = "libclang.so",
    actual = ":libclang",
    deprecation = "Use :libclang instead",
)

cc_import(
    name = "libc++",
    shared_library = "lib/libc++.{suffix}"
)
"""

def _bindgen_clang_repositories():
    # Releases @ http://releases.llvm.org/download.html
    maybe(
        http_archive,
        name = "bindgen_clang_linux_x86_64",
        urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz"],
        strip_prefix = "clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04",
        sha256 = "b25f592a0c00686f03e3b7db68ca6dc87418f681f4ead4df4745a01d9be63843",
        build_file_content = _CLANG_BUILD_FILE.format(suffix = "so"),
        workspace_file_content = _COMMON_WORKSPACE.format("bindgen_clang_linux_86_64"),
    )

    maybe(
        http_archive,
        name = "bindgen_clang_linux_aarch64",
        urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-aarch64-linux-gnu.tar.xz"],
        strip_prefix = "clang+llvm-10.0.0-aarch64-linux-gnu",
        sha256 = "c2072390dc6c8b4cc67737f487ef384148253a6a97b38030e012c4d7214b7295",
        build_file_content = _CLANG_BUILD_FILE.format(suffix = "so"),
        workspace_file_content = _COMMON_WORKSPACE.format("bindgen_clang_linux_aarch64"),
    )

    maybe(
        http_archive,
        name = "bindgen_clang_osx_x86_64",
        urls = ["https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-apple-darwin.tar.xz"],
        strip_prefix = "clang+llvm-10.0.0-x86_64-apple-darwin",
        sha256 = "633a833396bf2276094c126b072d52b59aca6249e7ce8eae14c728016edb5e61",
        build_file_content = _CLANG_BUILD_FILE.format(suffix = "dylib"),
        workspace_file_content = _COMMON_WORKSPACE.format("bindgen_clang_osx"),
    )
