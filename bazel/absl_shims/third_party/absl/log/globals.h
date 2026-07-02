// Forwarding header that maps the "third_party/absl/..." include paths used
// by the SentencePiece sources to the abseil-cpp Bazel module. This plays
// the same role as the third_party/absl symlink created by the CMake build.
#ifndef SENTENCEPIECE_BAZEL_ABSL_SHIMS_LOG_GLOBALS_H_
#define SENTENCEPIECE_BAZEL_ABSL_SHIMS_LOG_GLOBALS_H_

#include "absl/log/globals.h"

#endif  // SENTENCEPIECE_BAZEL_ABSL_SHIMS_LOG_GLOBALS_H_
