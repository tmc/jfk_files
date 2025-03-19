# Makefile with checksum-based dependencies for jfk_text/ input and jfk_text_summaries/ output

INPUT_DIR := jfk_text
SUMMARIES_OUTPUT_DIR := jfk_text_summaries
MD_FILES := $(wildcard $(INPUT_DIR)/*.md)
CGPT_BACKEND := googleai
CGPT_MODEL := gemini-2.0-flash
SUMMARIES := $(patsubst $(INPUT_DIR)/%.md,$(SUMMARIES_OUTPUT_DIR)/%.summary.md,$(MD_FILES))
CHECKSUM_FILE := .checksums
CGPT := go tool cgpt

# Function to calculate SHA1 checksum
sha1sum = sha1sum $< | cut -d' ' -f1

# Create the output directory if it doesn't exist
$(SUMMARIES_OUTPUT_DIR):
	@mkdir -p $@

# Rule to create a summary file
$(SUMMARIES_OUTPUT_DIR)/%.summary.md: $(INPUT_DIR)/%.md | $(SUMMARIES_OUTPUT_DIR)
	@echo "Summarizing $<..."
	CGPT_BACKEND=$(CGPT_BACKEND) CGPT_MODEL=$(CGPT_MODEL) $(CGPT) -s "Output a summary of this document, retain people, events, nations, any organizations and religous groups, and conclusions" -f "$<" | tee "$@"

# Dependency rule that checks checksums
$(INPUT_DIR)/%.md:
	@if [ "$(shell $(sha1sum) )" != "$(shell sed -n 's/^$(<): //p' $(CHECKSUM_FILE) )" ]; then \
		echo "Checksum mismatch for $<.  Rebuilding."; \
	else \
		echo "Checksum match for $<.  Skipping rebuild."; \
		exit 1; \
	fi

all: $(SUMMARIES)

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
