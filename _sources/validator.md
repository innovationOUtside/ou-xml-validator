# OU-XML Validator

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
