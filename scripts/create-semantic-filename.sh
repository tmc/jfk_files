#!/bin/bash
f="${1}"
base_filename="$(basename "${f}")"
CGPT_BACKEND=googleai
CGPT_MODEL=gemini-2.0-flash

echo | (cd jfk_text_summaries; txtar "${base_filename}") | cgpt -b ${CGPT_BACKEND} -m ${CGPT_MODEL} -t 8192 -T0 \
  -s "$(cat prompts/file-naming-prompt.txt)"
