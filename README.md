# ou-xml-validator

Command-line tools for transforming and validating OU-XML, generating alternate views etc. Tools include:

- generating Markdown/MyST Markdown from OU-XML (*ouxml2md*)
- generating TiddlyWiki files from OU-XML (experimental)
- generating OU-XML from Markdown/MyST Markdown via SphinxXML (*myst2sphinxXML* followed by *sphinxXml2ouxml*)
- validating OU-XML
- generating interactive HTMK mindmap and treemap views

A demo VLE site that renders OU-XML generated from MyST markdown is available [here](https://learn2.open.ac.uk/course/view.php?id=220999) (OU Staff only; please email `tony.hirst@open.ac.uk` for access).

Install as:

`pip install ou-xml-validator`

For latest development version:

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

## Transforming OU-XML to TiddlyWiki

Proof of concept: convert a single OU-XML file to a Tiddlywiki format.

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

## Interactive HTML Mindmap and Treemap views

Generate interactive views over the heading structures of one or more OU-XML files:

- interactive mindmap view (using [jsmind](https://jsmind.online/#sample)):

![Example module treemap (partial)](docs/images/mindmap.png)

- interactive treemap view ([plotly treemap](https://plotly.com/python/treemaps/): note that the text layout is a bit dodgy!)

![Example module treemap (partial)](docs/images/treemap.png)

```text

Usage: ouseful_ouxml2mm [OPTIONS] SOURCE...                                    
                                                                                
 Convert an OU-XML file into markdown.                                          
                                                                                
╭─ Arguments ──────────────────────────────────────────────────────────────────╮
│ *    source      SOURCE...  Source file(s), directory, or glob pattern       │
│                             [default: None]                                  │
│                             [required]                                       │
╰──────────────────────────────────────────────────────────────────────────────╯
╭─ Options ────────────────────────────────────────────────────────────────────╮
│ --modulecode          -m      TEXT  Module code [default: MODULE]            │
│ --output              -o      FILE  Output filename or path/filename         │
│                                     [default: None]                          │
│ --use-treemap         -t            Use treemap                              │
│ --install-completion                Install completion for the current       │
│                                     shell.                                   │
│ --show-completion                   Show completion for the current shell,   │
│                                     to copy it or customize the              │
│                                     installation.                            │
│ --help                              Show this message and exit.              │
╰───────────────

```

You can enter a path to a single HTML file, a directory, or a glob pattern. Files will be further filtered to files with an `.xml` suffix.

If no filename is entered, filenames of the form `MODULECODE_xx.html` will be generated where `xx` is replace by `mm` for a mindmap, and `tm` for a treemap.

Use the `--use_treemap`/`-t`switch to generate treemap files.

Examples:

`ouseful_ouxml2mm Downloads/tm129_24j-week*.xml -m TM129 -t`

`ouseful_ouxml2mm Downloads/tm129_24j-week1.xml Downloads/tm129_24j-week2.xml`

## BUILD and INSTALL

Install as:

`python3 -m pip install .`

For PyPi releases:

- build as: `python3 -m build`
- push to PyPi: `twine upload --skip-existing dist/*`


## TESTING

Tests in progress... These are a bit contrived and hacked, with a view mainly of checking some sort of XML and MyST equivalence to support a goal of round-tripping.

More "exact" tests are needed e.g. for checking small atomic element transformations exactly.

Run as: `pytest` or `pytest -v`
