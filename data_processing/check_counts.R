library(readr)
library(dplyr)
library(tidyr)
library(stringr)

# ------------------------------------------------------------------------------
# 1. Load input files

metadata <- read_csv("sample_metadata.csv")
cortex_counts <- read_csv("Choline_Study_Cortex_Normalized_Counts.csv")
hippo_counts <- read_csv("Choline_Study_Hippocampus_Normalized_Counts.csv")

# ------------------------------------------------------------------------------
# 2. Basic metadata checks

stopifnot(nrow(metadata) == 96)
stopifnot(!any(is.na(metadata$mouse_id)))
stopifnot(!anyDuplicated(metadata$mouse_id))

colSums(is.na(metadata))

# note: pathology columns have NAs for WT mice, which is expected

# ------------------------------------------------------------------------------
# 3. Prepare count files

cortex_counts <- cortex_counts %>%
  rename(mouse_id = 1) %>%
  mutate(tissue = "Cortex")

hippo_counts <- hippo_counts %>%
  rename(mouse_id = 1) %>%
  mutate(tissue = "Hippocampus")

# Check that all count mouse IDs exist in metadata
stopifnot(all(cortex_counts$mouse_id %in% metadata$mouse_id))
stopifnot(all(hippo_counts$mouse_id %in% metadata$mouse_id))

# ------------------------------------------------------------------------------
# 4. Convert counts to long format

all_counts <- bind_rows(cortex_counts, hippo_counts) %>%
  pivot_longer(
    cols = -c(mouse_id, tissue),
    names_to = "gene_name",
    values_to = "normalized_value"
  )

# ------------------------------------------------------------------------------
# 5. Clean duplicate gene column suffixes

all_counts_clean <- all_counts %>%
  mutate(
    gene_name = str_replace(gene_name, "\\.\\.\\.[0-9]+$", "")
  ) %>%
  group_by(mouse_id, tissue, gene_name) %>%
  slice(1) %>%
  ungroup()

# ------------------------------------------------------------------------------
# 6. Create cleaned gene list

cleaned_gene_list <- all_counts_clean %>%
  distinct(gene_name) %>%
  arrange(gene_name) %>%
  mutate(gene_id = row_number()) %>%
  select(gene_id, gene_name)

# ------------------------------------------------------------------------------
# 7. Add gene IDs to counts table

cleaned_counts_long <- all_counts_clean %>%
  left_join(cleaned_gene_list, by = "gene_name") %>%
  select(mouse_id, gene_id, normalized_value, tissue)

# ------------------------------------------------------------------------------
# 8. Final validation checks

stopifnot(sum(is.na(cleaned_counts_long$gene_id)) == 0)
stopifnot(sum(is.na(cleaned_counts_long$normalized_value)) == 0)

# No duplicate mouse/tissue/gene rows
duplicate_rows <- cleaned_counts_long %>%
  count(mouse_id, tissue, gene_id) %>%
  filter(n > 1)

stopifnot(nrow(duplicate_rows) == 0)

# Check tissue/sample balance
cleaned_counts_long %>%
  distinct(mouse_id, tissue) %>%
  count(tissue)

# Check genes per tissue
cleaned_counts_long %>%
  distinct(tissue, gene_id) %>%
  count(tissue)

# ------------------------------------------------------------------------------
# 9. Export cleaned files

write_csv(cleaned_gene_list, "cleaned_gene_list.csv")
write_csv(cleaned_counts_long, "cleaned_normalized_counts_long.csv")