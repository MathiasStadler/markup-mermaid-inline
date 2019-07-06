#!/bin/bash
rm -rf output

bats test/02_markdown_mermaid_inline.bats
