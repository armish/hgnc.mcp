# Tests for HGNC MCP Prompt Helpers
#
# This test suite covers:
# - prompt_normalize_gene_list(): Generate gene list normalization workflow prompts
# - prompt_check_nomenclature_compliance(): Generate compliance check prompts
# - prompt_what_changed_since(): Generate change tracking prompts
# - prompt_build_gene_set_from_group(): Generate gene set building prompts
#
# These prompts provide structured workflow guidance for AI assistants
# to use multiple HGNC tools together effectively.

test_that("prompt_normalize_gene_list generates valid prompt", {
  # Test with specified arguments
  prompt <- prompt_normalize_gene_list(
    gene_list = "BRCA1, TP53, EGFR",
    strictness = "lenient",
    return_xrefs = TRUE
  )

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Gene List Normalization Workflow")
  expect_match(prompt, "BRCA1, TP53, EGFR")
  expect_match(prompt, "normalize_list")
  expect_match(prompt, "lenient")
})

test_that("prompt_normalize_gene_list works with default arguments", {
  prompt <- prompt_normalize_gene_list()

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Gene List Normalization Workflow")
  expect_match(prompt, "normalize_list")
})

test_that("prompt_normalize_gene_list handles strictness parameter", {
  prompt_lenient <- prompt_normalize_gene_list(strictness = "lenient")
  prompt_strict <- prompt_normalize_gene_list(strictness = "strict")

  expect_match(prompt_lenient, "lenient")
  expect_match(prompt_strict, "strict")
})

test_that("prompt_normalize_gene_list handles return_xrefs parameter", {
  prompt_with_xrefs <- prompt_normalize_gene_list(return_xrefs = TRUE)
  prompt_without_xrefs <- prompt_normalize_gene_list(return_xrefs = FALSE)

  expect_match(prompt_with_xrefs, "Include cross-references: Yes")
  expect_match(prompt_without_xrefs, "Include cross-references: No")
})

test_that("prompt_check_nomenclature_compliance generates valid prompt", {
  # Test with panel text
  prompt <- prompt_check_nomenclature_compliance(
    panel_text = "BRCA1, BRCA2, TP53"
  )

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Nomenclature Compliance Check")
  expect_match(prompt, "BRCA1, BRCA2, TP53")
  expect_match(prompt, "validate_panel")
})

test_that("prompt_check_nomenclature_compliance works with file_uri", {
  prompt <- prompt_check_nomenclature_compliance(
    file_uri = "file:///path/to/panel.txt"
  )

  expect_type(prompt, "character")
  expect_match(prompt, "file:///path/to/panel.txt")
  expect_match(prompt, "Input Panel \\(File\\)")
})

test_that("prompt_check_nomenclature_compliance works with default arguments", {
  prompt <- prompt_check_nomenclature_compliance()

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Nomenclature Compliance Check")
})

test_that("prompt_what_changed_since generates valid prompt", {
  # Test with specified date
  prompt <- prompt_what_changed_since(since = "2024-01-01")

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "HGNC Nomenclature Changes Report")
  expect_match(prompt, "2024-01-01")
  expect_match(prompt, "changes")
})

test_that("prompt_what_changed_since works with default date", {
  prompt <- prompt_what_changed_since()

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "HGNC Nomenclature Changes Report")
  expect_match(prompt, "30 days ago")
})

test_that("prompt_what_changed_since includes expected sections", {
  prompt <- prompt_what_changed_since(since = "2024-01-01")

  expect_match(prompt, "Symbol Changes")
  expect_match(prompt, "Status Changes")
  expect_match(prompt, "Name Changes")
})

test_that("prompt_build_gene_set_from_group generates valid prompt", {
  # Test with query
  prompt <- prompt_build_gene_set_from_group(group_query = "kinase")

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Build Gene Set from HGNC Gene Group")
  expect_match(prompt, "kinase")
  expect_match(prompt, "search_groups")
  expect_match(prompt, "group_members")
})

test_that("prompt_build_gene_set_from_group works with default arguments", {
  prompt <- prompt_build_gene_set_from_group()

  expect_type(prompt, "character")
  expect_gt(nchar(prompt), 100)
  expect_match(prompt, "Build Gene Set from HGNC Gene Group")
})

test_that("prompt_build_gene_set_from_group includes output format guidance", {
  prompt <- prompt_build_gene_set_from_group(group_query = "kinase")

  expect_match(prompt, "Simple symbol list")
  expect_match(prompt, "Tab-separated table")
  expect_match(prompt, "Structured JSON")
})

test_that("all prompts return non-empty strings", {
  prompts <- list(
    prompt_normalize_gene_list(),
    prompt_check_nomenclature_compliance(),
    prompt_what_changed_since(),
    prompt_build_gene_set_from_group()
  )

  for (prompt in prompts) {
    expect_type(prompt, "character")
    expect_gt(nchar(prompt), 100)
  }
})

test_that("prompts contain workflow guidance keywords", {
  prompts <- list(
    list(
      fn = prompt_normalize_gene_list,
      keywords = c("Step", "workflow", "normalize")
    ),
    list(
      fn = prompt_check_nomenclature_compliance,
      keywords = c("Step", "validate", "compliance")
    ),
    list(
      fn = prompt_what_changed_since,
      keywords = c("Step", "changes", "since")
    ),
    list(
      fn = prompt_build_gene_set_from_group,
      keywords = c("Step", "group", "gene set")
    )
  )

  for (prompt_info in prompts) {
    prompt_text <- prompt_info$fn()
    for (keyword in prompt_info$keywords) {
      expect_match(prompt_text, keyword, ignore.case = TRUE)
    }
  }
})
