# Via ChatGPT
# Call as: python xml_validator.py schemas/OUIntermediateSchema.xsd XML_FILE.xml

# python -m pip install xmlschema
import argparse
import xmlschema
import pkg_resources

def validate_xml(xml_filename, schema_filename=None):
    try:
        if schema_filename is None:
            schema_filename = pkg_resources.resource_filename(__name__, 'schemas/OUIntermediateSchema.xsd')
        xs = xmlschema.XMLSchema(schema_filename)
        if xs.is_valid(xml_filename):
            print(f"{xml_filename} is valid according to the schema.")
        else:
            print(f"{xml_filename} is not valid according to the schema I used ({schema_filename}).")
            validation_errors = xs.validate(xml_filename)
            print("Validation errors:")
            for error in validation_errors:
                print(f" - {error}")
    except xmlschema.XMLSchemaParseError as e:
        print(f"Error while parsing schema: {e}")
    except xmlschema.XMLSchemaValidationError as e:
        print(f"Validation error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Validate an XML file against an XML schema.")
    parser.add_argument("schema", help="XML schema (XSD) filename")
    parser.add_argument("xml", help="XML filename to be validated")
    args = parser.parse_args()

    validate_xml(args.schema, args.xml)

if __name__ == "__main__":
    main()