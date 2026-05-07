library(readxl)
library(dplyr)
library(purrr)
library(readr)
library(stringr)

# ------------------------------------------------------------------------------
# File paths

app_vs_wt_path <- "File S1_AppNLGF_vs_WT_Control_Diet_DEGs_Pathways.xlsx"
pcs_vs_ctrl_path <- "File S2_PCS_vs_Control_DEGs_Pathways.xlsx"

contrasts_path <- "contrasts_new.csv"
genes_path <- "cleaned_gene_list.csv"

# ------------------------------------------------------------------------------
# Load lookup tables

contrasts <- read_csv(contrasts_path)
genes <- read_csv(genes_path) %>%
  mutate(gene_name = trimws(gene_name))

# ------------------------------------------------------------------------------
# Helper function to remove bad Ensembl rows and clean gene symbols

clean_deg_symbols <- function(df) {
  df %>%
    filter(!grepl("^ENS[A-Z]*G[0-9]+(\\.[0-9]+)?$", SYMBOL)) %>%
    mutate(SYMBOL = trimws(SYMBOL))
}

# ------------------------------------------------------------------------------
# Process APP vs WT differential expression sheets

app_sheets <- excel_sheets(app_vs_wt_path)

app_deg_sheets <- app_sheets[
  !grepl("GSEA", app_sheets) &
    !grepl("All Ages", app_sheets) &
    !grepl("^File S1$", app_sheets)
]

app_deg <- map_dfr(app_deg_sheets, function(sheet_name) {
  read_excel(app_vs_wt_path, sheet = sheet_name) %>%
    mutate(sheet_name = sheet_name)
}) %>%
  select(-...1) %>%
  mutate(
    tissue = ifelse(grepl("Cortex", sheet_name), "Cortex", "Hippocampus"),
    age = as.numeric(gsub(".* (\\d+)mo", "\\1", sheet_name))
  ) %>%
  clean_deg_symbols()

app_contrasts <- contrasts %>%
  filter(name == "APP vs WT") %>%
  select(tissue, age, contrast_id)

app_final <- app_deg %>%
  inner_join(app_contrasts, by = c("tissue", "age")) %>%
  inner_join(
    genes %>% select(gene_name, gene_id),
    by = c("SYMBOL" = "gene_name")
  ) %>%
  select(contrast_id, gene_id, log2FoldChange, padj) %>%
  group_by(contrast_id, gene_id) %>%
  slice(1) %>%
  ungroup()

# ------------------------------------------------------------------------------
# Process PCS vs Control differential expression sheets

pcs_sheets <- excel_sheets(pcs_vs_ctrl_path)

pcs_deg_sheets <- pcs_sheets[
  !grepl("G", pcs_sheets) &
    !grepl("All", pcs_sheets) &
    !grepl("^File S2$", pcs_sheets)
]

pcs_deg <- map_dfr(pcs_deg_sheets, function(sheet_name) {
  read_excel(pcs_vs_ctrl_path, sheet = sheet_name) %>%
    mutate(
      SYMBOL = if ("SYMBOL" %in% names(.)) {
        ifelse(is.na(SYMBOL), ...1, SYMBOL)
      } else {
        ...1
      },
      sheet_name = sheet_name,
      padj = as.numeric(padj),
      log2FoldChange = as.numeric(log2FoldChange)
    )
}) %>%
  select(-...1) %>%
  mutate(
    tissue = ifelse(grepl("Cortex", sheet_name), "Cortex", "Hippocampus"),
    age = as.numeric(gsub(".* (\\d+)mo", "\\1", sheet_name)),
    genotype = ifelse(grepl("APP", sheet_name), "APP", "WT")
  ) %>%
  clean_deg_symbols()

pcs_contrasts <- contrasts %>%
  mutate(
    genotype = case_when(
      grepl("^APP", name) ~ "APP",
      grepl("^WT", name) ~ "WT",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(name %in% c(
    "APP Supplemented vs APP Control",
    "WT Supplemented vs WT Control"
  )) %>%
  select(tissue, age, genotype, contrast_id)

pcs_final <- pcs_deg %>%
  inner_join(pcs_contrasts, by = c("tissue", "age", "genotype")) %>%
  inner_join(
    genes %>% select(gene_name, gene_id),
    by = c("SYMBOL" = "gene_name")
  ) %>%
  select(contrast_id, gene_id, log2FoldChange, padj) %>%
  group_by(contrast_id, gene_id) %>%
  slice(1) %>%
  ungroup()

# ------------------------------------------------------------------------------
# Final validation checks

# No missing IDs
stopifnot(sum(is.na(app_final$contrast_id)) == 0)
stopifnot(sum(is.na(app_final$gene_id)) == 0)

stopifnot(sum(is.na(pcs_final$contrast_id)) == 0)
stopifnot(sum(is.na(pcs_final$gene_id)) == 0)

# No duplicate contrast/gene combinations
stopifnot(
  app_final %>%
    count(contrast_id, gene_id) %>%
    filter(n > 1) %>%
    nrow() == 0
)

stopifnot(
  pcs_final %>%
    count(contrast_id, gene_id) %>%
    filter(n > 1) %>%
    nrow() == 0
)

# Check missing statistical values
app_final %>%
  summarise(
    rows = n(),
    log2fc_missing = sum(is.na(log2FoldChange)),
    padj_missing = sum(is.na(padj))
  )

pcs_final %>%
  summarise(
    rows = n(),
    log2fc_missing = sum(is.na(log2FoldChange)),
    padj_missing = sum(is.na(padj))
  )

# Check PCS contrast coverage
pcs_final %>%
  count(contrast_id) %>%
  arrange(contrast_id)

# ------------------------------------------------------------------------------
# Export cleaned files

write_csv(app_final, "combined_deg_with_metadata_APPvsWT.csv")
write_csv(pcs_final, "combined_deg_with_metadata_PCSvsCTRL.csv")