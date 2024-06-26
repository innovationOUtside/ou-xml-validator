
# Transforming Markdown/MyST Markdown to OU-XML

Inspired by a tool originally developed by Mark Hall, transform Sphinx XML generated from markdown files described by `_toc.yml` and configured using `_config.yml`to OU-XML. Admonition extensions in the original markdown can be trasnformed using the [`innovationOUtside/sphinxcontrib-ou-xml-tags`](https://github.com/innovationOUtside/sphinxcontrib-ou-xml-tags) Sphinx plugin.

```bash
# Use Jupyter Book tools to generate Sphinx XML
jb build . --builder custom --custom-builder xml
# Transform Sphinx XML to OU-XML
ouseful_obt .
# The resulting XML should be checked using the OU-XML validator.
```
