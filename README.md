# ou-xml-validator

Command-line tools for transforming and validating OU-XML. Tools include:

- generating Markdown/MyST Markdown from OU-XML (*ouxml2myst*)
- generating OU-XML from Markdown/MyST Markdown via SphinxXML (*myst2sphinxXML* followed by *sphinxXml2ouxml*)
- validating OU-XML

A demo VLE site that renders OU-XML generated from MyST markdown is available [here](https://learn2.open.ac.uk/course/view.php?id=220999) (OU Staff only; please email `tony.hirst@open.ac.uk` for access).

Install as:

`pip install https://github.com/innovationOUtside/ou-xml-validator/archive/refs/heads/main.zip`

or

`pip install git+https://github.com/innovationOUtside/ou-xml-validator.git`

## Transforming OU-XML to Markdown/MyST

An XSLT based transformation for transforming a single OU-XML file to one or more markdown files. *A post-processor script then cleans and formats the generated markdown.*

`ou_xml_validator transform path-to-file/content.xml`

We can clean the markdown as follows:

```bash
# pip3 install mdformat mdformat-myst
mdformat src 
ou_xml_validator cleanmd PATH
# If it's simple markdown, transform to myst
jupytext --to myst src/*.md
```

## Transforming Markdown/MyST Markdown to OU-XML

Inspired by a tool originally developed by Mark Hall, transform Sphinx XML generated from markdown files described by `_toc.yml` and configured using `_config.yml`to OU-XML. Admonition extensions in the original markdown can be trasnformed using the [`innovationOUtside/sphinxcontrib-ou-xml-tags`](https://github.com/innovationOUtside/sphinxcontrib-ou-xml-tags) Sphinx plugin.

```bash
# Use Jupyter Book tools to generate Sphinx XML
jb build . --builder custom --custom-builder xml
# Transform Sphinx XML to OU-XML
ouseful_obt .
# The resulting XML should be checked using the OU-XML validator.
```

## OU-XML Validator

Simple tool to validate OU-XML files.

To validate a single file:

`ou_xml_validator validate path-to-file/testme.xml`

```text
Usage: ou_xml_validator [OPTIONS] COMMAND [ARGS]...

Options:
  --help  Show this message and exit.

Commands:
  validate  Validate OU-XML document against OU-XML schema.
```

```text
Usage: ou_xml_validator validate [OPTIONS] [PATH]

  Validate OU-XML document against OU-XML schema.

Options:
  -s, --schema TEXT  XML schema filepath
  --help             Show this message and exit.
```

## BUILD and INSTALL

`python3 -m build`

Install as:

`python3 -m pip install .`

## TESTING

Tests in progress... These are a bit congrived and hacked, with a view mainly of checking some sort of XML and MyST equivalence to support a goal of round-tripping.

More "exact" tests are needed e.g. for checking small atomic element transformations exactly.

Run as: `pytest` or `pytest -v`
