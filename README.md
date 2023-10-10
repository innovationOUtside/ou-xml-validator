# ou-xml-validator

Simple tool to validate OU-XML files.

Install as:

`pip install https://github.com/innovationOUtside/ou-xml-validator/archive/refs/heads/main.zip`

or

`pip install git+https://github.com/innovationOUtside/ou-xml-validator.git`

To validate a single file:

`ou_xml_validator validate  path./testme.xml`

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