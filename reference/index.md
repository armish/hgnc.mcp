# Package index

## Data Management

Functions for downloading, caching, and managing HGNC data

- [`load_hgnc_data()`](https://armish.github.io/hgnc.mcp/reference/load_hgnc_data.md)
  : Load HGNC data
- [`download_hgnc_data()`](https://armish.github.io/hgnc.mcp/reference/download_hgnc_data.md)
  : Download HGNC data from the official source
- [`get_hgnc_cache_info()`](https://armish.github.io/hgnc.mcp/reference/get_hgnc_cache_info.md)
  : Get cache information
- [`is_hgnc_cache_fresh()`](https://armish.github.io/hgnc.mcp/reference/is_hgnc_cache_fresh.md)
  : Check if cached HGNC data exists and is fresh
- [`get_hgnc_cache_dir()`](https://armish.github.io/hgnc.mcp/reference/get_hgnc_cache_dir.md)
  : Get HGNC cache directory
- [`clear_hgnc_cache()`](https://armish.github.io/hgnc.mcp/reference/clear_hgnc_cache.md)
  : Clear HGNC Caches

## REST API Client

Low-level functions for interacting with the HGNC REST API

- [`hgnc_rest_info_uncached()`](https://armish.github.io/hgnc.mcp/reference/hgnc_rest_info_uncached.md)
  [`hgnc_rest_info()`](https://armish.github.io/hgnc.mcp/reference/hgnc_rest_info_uncached.md)
  : Get HGNC REST API Information
- [`hgnc_rest_get()`](https://armish.github.io/hgnc.mcp/reference/hgnc_rest_get.md)
  : Base HTTP Client for HGNC REST API
- [`reset_rate_limiter()`](https://armish.github.io/hgnc.mcp/reference/reset_rate_limiter.md)
  : Reset HGNC Rate Limiter

## Gene Lookup and Resolution

Search for genes, resolve symbols, and extract information

- [`hgnc_find()`](https://armish.github.io/hgnc.mcp/reference/hgnc_find.md)
  : Search for Genes in HGNC Database
- [`hgnc_fetch()`](https://armish.github.io/hgnc.mcp/reference/hgnc_fetch.md)
  : Fetch Gene Records by Field Value
- [`hgnc_resolve_symbol()`](https://armish.github.io/hgnc.mcp/reference/hgnc_resolve_symbol.md)
  : Resolve Gene Symbol to Approved Symbol
- [`hgnc_xrefs()`](https://armish.github.io/hgnc.mcp/reference/hgnc_xrefs.md)
  : Extract Cross-References from Gene Record

## Batch Operations

Efficiently process lists of genes using local cache

- [`hgnc_normalize_list()`](https://armish.github.io/hgnc.mcp/reference/hgnc_normalize_list.md)
  : Normalize Gene Symbol List
- [`build_symbol_index()`](https://armish.github.io/hgnc.mcp/reference/build_symbol_index.md)
  : Build Symbol Index from Cached Data

## Gene Groups and Families

Discover and explore HGNC gene groups

- [`hgnc_group_members_uncached()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md)
  [`hgnc_group_members()`](https://armish.github.io/hgnc.mcp/reference/hgnc_group_members_uncached.md)
  : Get Members of a Gene Group
- [`hgnc_search_groups()`](https://armish.github.io/hgnc.mcp/reference/hgnc_search_groups.md)
  : Search for Gene Groups

## Change Tracking and Validation

Track nomenclature changes and validate gene panels

- [`hgnc_changes()`](https://armish.github.io/hgnc.mcp/reference/hgnc_changes.md)
  : Track Gene Nomenclature Changes
- [`hgnc_validate_panel()`](https://armish.github.io/hgnc.mcp/reference/hgnc_validate_panel.md)
  : Validate Gene Panel Against HGNC Policy

## MCP Server

Start and configure the Model Context Protocol server

- [`start_hgnc_mcp_server()`](https://armish.github.io/hgnc.mcp/reference/start_hgnc_mcp_server.md)
  : Start HGNC MCP Server
- [`check_mcp_dependencies()`](https://armish.github.io/hgnc.mcp/reference/check_mcp_dependencies.md)
  : Check MCP Server Dependencies

## MCP Resources

Resource functions for context injection

- [`hgnc_resources`](https://armish.github.io/hgnc.mcp/reference/hgnc_resources.md)
  : HGNC MCP Resource Helpers
- [`hgnc_get_gene_card()`](https://armish.github.io/hgnc.mcp/reference/hgnc_get_gene_card.md)
  : Get Gene Card Resource
- [`hgnc_get_group_card()`](https://armish.github.io/hgnc.mcp/reference/hgnc_get_group_card.md)
  : Get Group Card Resource
- [`hgnc_get_snapshot_metadata()`](https://armish.github.io/hgnc.mcp/reference/hgnc_get_snapshot_metadata.md)
  : Get Snapshot Metadata Resource
- [`hgnc_get_changes_summary()`](https://armish.github.io/hgnc.mcp/reference/hgnc_get_changes_summary.md)
  : Get Changes Summary Resource

## MCP Prompts

Workflow templates for multi-step tasks

- [`hgnc_prompts`](https://armish.github.io/hgnc.mcp/reference/hgnc_prompts.md)
  : MCP Prompt Helpers for HGNC Workflows
- [`prompt_normalize_gene_list()`](https://armish.github.io/hgnc.mcp/reference/prompt_normalize_gene_list.md)
  : Generate Normalize Gene List Prompt
- [`prompt_check_nomenclature_compliance()`](https://armish.github.io/hgnc.mcp/reference/prompt_check_nomenclature_compliance.md)
  : Generate Nomenclature Compliance Check Prompt
- [`prompt_what_changed_since()`](https://armish.github.io/hgnc.mcp/reference/prompt_what_changed_since.md)
  : Generate What Changed Since Prompt
- [`prompt_build_gene_set_from_group()`](https://armish.github.io/hgnc.mcp/reference/prompt_build_gene_set_from_group.md)
  : Generate Build Gene Set from Group Prompt
