# ou-xml-validator

Simple tool to validate OU-XML files.

Install as:

`pip install https://github.com/innovationOUtside/ou-xml-validator/archive/refs/heads/main.zip`

or

`pip install git+https://github.com/innovationOUtside/ou-xml-validator.git`

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

To transform a single OU-XML file to markdown:

`ou_xml_validator transform path-to-file/content.xml`

To transform markdown files described by `_toc.yml` and configured using `_config.yml` to OU-XML;

```bash
jb build . --builder custom --custom-builder xml
ouseful_obt .
```