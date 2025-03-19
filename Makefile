# Makefile with checksum-based dependencies for jfk_text/ input and jfk_text_summaries/ output

INPUT_DIR := jfk_text
SUMMARIES_OUTPUT_DIR := jfk_text_summaries
MD_FILES := $(wildcard $(INPUT_DIR)/*.md)
CGPT_BACKEND := googleai
CGPT_MODEL := gemini-2.0-flash
SUMMARIES := $(patsubst $(INPUT_DIR)/%.md,$(SUMMARIES_OUTPUT_DIR)/%.summary.md,$(MD_FILES))
CHECKSUM_FILE := .checksums
CGPT := go tool cgpt
MAP_FILE := filename_map.txt

# Function to calculate SHA1 checksum
sha1sum = sha1sum $< | cut -d' ' -f1

# Create the output directory if it doesn't exist
$(SUMMARIES_OUTPUT_DIR):
	@mkdir -p $@

# Rule to create a summary file
$(SUMMARIES_OUTPUT_DIR)/%.summary.md: $(INPUT_DIR)/%.md | $(SUMMARIES_OUTPUT_DIR)
	@echo "Summarizing $<..."
	CGPT_BACKEND=$(CGPT_BACKEND) CGPT_MODEL=$(CGPT_MODEL) $(CGPT) \
				 -t 8192 \
				 -s "Output a summary of this document, retain people, events, nations, any organizations and religous groups, and conclusions" -f "$<" | tee "$@"

# Rule to create a symlink with {date}-{topic}.txt format using a mapping or fallback
$(SUMMARIES_OUTPUT_DIR)/%.txt: $(SUMMARIES_OUTPUT_DIR)/%.summary.md
	@echo "Creating symlink for $<..."
	@if [ -f $(MAP_FILE) ] && grep -q "$<" $(MAP_FILE); then \
		MAPPED_NAME=$$(sed -n "s|^$<:\s*\(.*\)$$|\1|p" $(MAP_FILE)); \
		ln -sf $(notdir $<) $(SUMMARIES_OUTPUT_DIR)/$${MAPPED_NAME}.txt; \
	else \
		ln -sf $(notdir $<) $(SUMMARIES_OUTPUT_DIR)/$*.txt; \
	fi

.PHONY: map-semantic-filenames
map-semantic-filenames:
	while read -r source target; do ln -s "../jfk_text/$$source" "jfk_text_semantic_names/$$target"; done < metadata/.semantic-filenames

$(SUMMARIES_OUTPUT_DIR)/.hist-semantic-filenames: scripts/create-semantic-filename.sh prompts/file-naming-prompt.txt
	ls jfk_text_summaries |xargs -L1 ./scripts/create-semantic-filename.sh |tee -a $@

# Dependency rule that checks checksums
$(INPUT_DIR)/%.md:
	@if [ "$(shell $(sha1sum) )" != "$(shell sed -n 's/^$(<): //p' $(CHECKSUM_FILE) )" ]; then \
		echo "Checksum mismatch for $<.  Rebuilding."; \
	else \
		echo "Checksum match for $<.  Skipping rebuild."; \
		exit 1; \
	fi

SYMLINKS := $(patsubst $(INPUT_DIR)/%.md,$(SUMMARIES_OUTPUT_DIR)/%.txt,$(MD_FILES))
# Target to build both summaries and symlinks
all: $(SUMMARIES) $(SYMLINKS)

# Create or update the checksum file
update_checksums: $(MD_FILES)
	@echo "Updating checksums..."
	@rm -f $(CHECKSUM_FILE).tmp
	@for file in $^; do \
		echo "$$file: $$(sha1sum $$file | cut -d' ' -f1)" >> $(CHECKSUM_FILE).tmp; \
	done
	@mv $(CHECKSUM_FILE).tmp $(CHECKSUM_FILE)

.PHONY: all clean update_checksums

clean:
	@echo "Cleaning up summary files..."
	@rm -f $(SUMMARIES)

# Delete target files on error
.DELETE_ON_ERROR:


#$(MAP_FILE): .cgpt-hist-$(MAP_FILE)
#	cat $< | go tool yq .messages[-1].text 
#	#go tool txtar -x

#.cgpt-hist-$(MAP_FILE): $(SUMMARIES) prompts/mapping-file-prompt.txt
#	go tool ctx-exec go tool txtar Makefile $(SUMMARIES_OUTPUT_DIR)/*md | \
#		CGPT_BACKEND=$(CGPT_BACKEND) CGPT_MODEL=$(CGPT_MODEL) $(CGPT) \
#		-t 8192 \
#		-s "$(shell cat prompts/mapping-file-prompt.txt)" -O $@

