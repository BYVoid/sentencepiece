# Building SentencePiece with Bazel

In addition to the [CMake build](cli.md), SentencePiece can be built with
[Bazel](https://bazel.build). All third-party dependencies are resolved
through the [Bazel Central Registry](https://registry.bazel.build):

- [abseil-cpp](https://github.com/abseil/abseil-cpp), at the same version as
  the `GIT_TAG` pinned in `CMakeLists.txt`;
- [protobuf](https://github.com/protocolbuffers/protobuf): the protobuf code
  is regenerated from `src/*.proto` at build time, matching the
  `SPM_PROTOBUF_PROVIDER=package` CMake configuration (CMake defaults to the
  vendored protobuf-lite runtime instead);
- [darts-clone](https://github.com/s-yata/darts-clone), as the
  `0.32h.bcr.1` module that carries the compatibility helpers of the
  vendored copy.

The vendored `third_party/darts_clone`, `third_party/protobuf-lite`, and
`src/builtin_pb` sources are only used by CMake.

## Prerequisites

- Bazel 7.1 or later (bzlmod is used; installing via
  [Bazelisk](https://github.com/bazelbuild/bazelisk) is recommended)
- A C++17 compiler

## Building

Build the libraries and all command line tools:

```bash
bazel build //...
```

The main targets are:

| Target | Description |
| --- | --- |
| `//src:sentencepiece` (alias `//:sentencepiece`) | Runtime library (encode/decode) |
| `//src:sentencepiece_train` (alias `//:sentencepiece_train`) | Trainer library |
| `//src:spm_train` | Model trainer CLI |
| `//src:spm_encode` | Encoder CLI |
| `//src:spm_decode` | Decoder CLI |
| `//src:spm_normalize` | Text normalizer CLI |
| `//src:spm_export_vocab` | Vocabulary exporter CLI |

Run a tool directly:

```bash
bazel run //src:spm_train -- \
  --input=$(pwd)/data/botchan.txt --model_prefix=$(pwd)/m --vocab_size=8000
echo "Hello world." | bazel-bin/src/spm_encode --model=m.model
```

## Running the unit tests

The unit tests are a single test binary, like the `spm_test` target that
CMake builds with `-DSPM_BUILD_TEST=ON`:

```bash
bazel test //src:spm_test
```

## Notes

- The optional CMake features `SPM_ENABLE_NFKC_COMPILE` (ICU),
  `SPM_ENABLE_TCMALLOC`, `SPM_ENABLE_BENCHMARK`, and `SPM_NLCODEC_BPE` have no
  Bazel equivalent yet.
- The SentencePiece sources include third-party headers with paths such as
  `third_party/absl/...` and `darts_clone/darts.h`. CMake satisfies these
  includes with checkouts or vendored copies under `third_party/`; the Bazel
  build instead forwards them to the Bazel Central Registry modules through
  forwarding headers that the repository rule in `bazel/include_compat.bzl`
  generates at fetch time (the `@include_compat` repository). No third-party
  code is vendored into the Bazel build.
- To use SentencePiece as a dependency in another Bazel module:

  ```starlark
  bazel_dep(name = "sentencepiece", version = "0.2.2")
  ```

  and depend on `@sentencepiece//:sentencepiece` (and
  `@sentencepiece//:sentencepiece_train` for training support).
