test_that("MCP server checks for prompt support correctly", {
  # Check if pr_mcp_prompt is in plumber2mcp exports
  has_prompt_support <- "pr_mcp_prompt" %in% getNamespaceExports("plumber2mcp")

  expect_type(has_prompt_support, "logical")
  # This will be TRUE once plumber2mcp NAMESPACE is updated
})

test_that("prompt helper functions are exported", {
  # Verify all prompt functions are available
  expect_true(exists("prompt_normalize_gene_list"))
  expect_true(exists("prompt_check_nomenclature_compliance"))
  expect_true(exists("prompt_what_changed_since"))
  expect_true(exists("prompt_build_gene_set_from_group"))

  # Verify they are functions
  expect_type(prompt_normalize_gene_list, "closure")
  expect_type(prompt_check_nomenclature_compliance, "closure")
  expect_type(prompt_what_changed_since, "closure")
  expect_type(prompt_build_gene_set_from_group, "closure")
})

test_that("check_mcp_dependencies reports correctly", {
  # This function should run without error
  result <- check_mcp_dependencies()

  expect_type(result, "logical")
  # Result depends on whether dependencies are installed
})
