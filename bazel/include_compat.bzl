# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.!

"""Maps the "third_party/..." include paths to Bazel Central Registry modules.

The SentencePiece sources include their third-party headers with a
"third_party/..." prefix. The CMake build satisfies those includes with
checkouts or vendored copies under third_party/. For Bazel, the repository
rule below generates a small repository of forwarding headers, each of which
simply includes the corresponding header of the module fetched from the
Bazel Central Registry. No third-party code is vendored or duplicated.

Keep _FORWARDED_HEADERS in sync with the "third_party/..." includes used by
the sources, and the deps of the aggregate targets in //bazel/BUILD.bazel in
sync with the module targets that provide them. A missing entry shows up as
a "file not found" error for the corresponding include.
"""

# Maps the include paths used by the SentencePiece sources to the include
# paths exported by the corresponding Bazel modules.
_FORWARDED_HEADERS = {
    "third_party/absl/base/attributes.h": "absl/base/attributes.h",
    "third_party/absl/base/internal/endian.h": "absl/base/internal/endian.h",
    "third_party/absl/base/thread_annotations.h": "absl/base/thread_annotations.h",
    "third_party/absl/cleanup/cleanup.h": "absl/cleanup/cleanup.h",
    "third_party/absl/container/btree_set.h": "absl/container/btree_set.h",
    "third_party/absl/container/fixed_array.h": "absl/container/fixed_array.h",
    "third_party/absl/container/flat_hash_map.h": "absl/container/flat_hash_map.h",
    "third_party/absl/container/flat_hash_set.h": "absl/container/flat_hash_set.h",
    "third_party/absl/flags/flag.h": "absl/flags/flag.h",
    "third_party/absl/flags/parse.h": "absl/flags/parse.h",
    "third_party/absl/flags/usage.h": "absl/flags/usage.h",
    "third_party/absl/flags/usage_config.h": "absl/flags/usage_config.h",
    "third_party/absl/functional/any_invocable.h": "absl/functional/any_invocable.h",
    "third_party/absl/functional/function_ref.h": "absl/functional/function_ref.h",
    "third_party/absl/hash/hash.h": "absl/hash/hash.h",
    "third_party/absl/log/check.h": "absl/log/check.h",
    "third_party/absl/log/flags.h": "absl/log/flags.h",
    "third_party/absl/log/globals.h": "absl/log/globals.h",
    "third_party/absl/log/initialize.h": "absl/log/initialize.h",
    "third_party/absl/log/log.h": "absl/log/log.h",
    "third_party/absl/numeric/bits.h": "absl/numeric/bits.h",
    "third_party/absl/random/random.h": "absl/random/random.h",
    "third_party/absl/status/status.h": "absl/status/status.h",
    "third_party/absl/status/status_builder.h": "absl/status/status_builder.h",
    "third_party/absl/status/status_macros.h": "absl/status/status_macros.h",
    "third_party/absl/strings/ascii.h": "absl/strings/ascii.h",
    "third_party/absl/strings/match.h": "absl/strings/match.h",
    "third_party/absl/strings/numbers.h": "absl/strings/numbers.h",
    "third_party/absl/strings/str_cat.h": "absl/strings/str_cat.h",
    "third_party/absl/strings/str_format.h": "absl/strings/str_format.h",
    "third_party/absl/strings/str_join.h": "absl/strings/str_join.h",
    "third_party/absl/strings/str_replace.h": "absl/strings/str_replace.h",
    "third_party/absl/strings/str_split.h": "absl/strings/str_split.h",
    "third_party/absl/strings/string_view.h": "absl/strings/string_view.h",
    "third_party/absl/strings/strip.h": "absl/strings/strip.h",
    "third_party/absl/synchronization/blocking_counter.h": "absl/synchronization/blocking_counter.h",
    "third_party/absl/synchronization/mutex.h": "absl/synchronization/mutex.h",
    "third_party/absl/time/clock.h": "absl/time/clock.h",
    "third_party/absl/time/time.h": "absl/time/time.h",
    "third_party/absl/types/span.h": "absl/types/span.h",
    # The sources include this as "darts_clone/darts.h" (without the
    # third_party/ prefix): the path must not collide with the vendored
    # third_party/darts_clone/darts.h file, which would otherwise shadow this
    # forwarding header on platforms that build without sandboxing (Windows).
    # CMake resolves the same include against the vendored copy through its
    # third_party include directory.
    #
    # Angle brackets are required here: the forwarding header is itself named
    # darts.h, so a quoted include would resolve to itself through the
    # includer-directory lookup. The angle form only searches the include
    # path, where the darts-clone module exposes the real header.
    "darts_clone/darts.h": "<darts.h>",
}

_HEADER_TEMPLATE = """\
// Generated by //bazel:include_compat.bzl. Forwards the
// "{from_header}" include path used by the SentencePiece
// sources to the corresponding Bazel module.
#ifndef {guard}
#define {guard}

#include {include}

#endif  // {guard}
"""

_BUILD_TEMPLATE = """\
# Generated by //bazel:include_compat.bzl.

load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "headers",
    hdrs = [
{hdrs}
    ],
)
"""

def _include_compat_impl(repository_ctx):
    hdrs = []
    for from_header, to_header in repository_ctx.attr.forwarded_headers.items():
        guard = "SENTENCEPIECE_INCLUDE_COMPAT_%s_" % (
            from_header.replace("/", "_").replace(".", "_").upper()
        )
        include = to_header if to_header.startswith("<") else '"%s"' % to_header
        repository_ctx.file(
            from_header,
            _HEADER_TEMPLATE.format(
                from_header = from_header,
                include = include,
                guard = guard,
            ),
        )
        hdrs.append('        "%s",' % from_header)
    repository_ctx.file(
        "BUILD.bazel",
        _BUILD_TEMPLATE.format(hdrs = "\n".join(sorted(hdrs))),
    )

include_compat = repository_rule(
    implementation = _include_compat_impl,
    attrs = {
        "forwarded_headers": attr.string_dict(default = _FORWARDED_HEADERS),
    },
    doc = "Generates third_party/... forwarding headers for BCR modules.",
)
