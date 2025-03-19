#!/bin/bash

arg1="${1:-}"
CGPT_BACKEND=googleai
CGPT_MODEL=gemini-2.0-flash

if [ -n "${arg1}" ] && [ "${arg1}" = "continue" ]; then
cgpt -b ${CGPT_BACKEND} -m ${CGPT_MODEL} -t 81920 -T0 \
  -I .cgpt-hist-aianalysis-1 \
  -O .cgpt-hist-aianalysis-1 \
  -i "continue" \
  | tee -a .ai-analysis-1.txtar
  exit 0
fi


echo | (cd jfk_text_summaries_semantic_names/; txtar *) | cgpt -b ${CGPT_BACKEND} -m ${CGPT_MODEL} -t 81920 -T0 \
  -s "$(cat prompts/ai-analysis-prompt-1.txt)" -O .cgpt-hist-aianalysis-1 | tee .ai-analysis-1.txtar
