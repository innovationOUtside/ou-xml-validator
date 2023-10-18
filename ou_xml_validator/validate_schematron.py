# Via ChatGPT
# Call as: python validate_schematron.py schemas/vle_oxygen_schematron.sch XMLFILE.xml

# python -m pip install xmlschema
from lxml import etree, isoschematron
import argparse

def validate_with_schematron(schematron_filename, xml_filename):
    schematron_doc = etree.parse(schematron_filename)
    schematron = isoschematron.Schematron(schematron_doc)
    
    xml_doc = etree.parse(xml_filename)
    is_valid = schematron.validate(xml_doc)
    
    return is_valid

def main():
    parser = argparse.ArgumentParser(description="Validate an XML file against Schematron rules.")
    parser.add_argument("schematron", help="Schematron rules XML filename")
    parser.add_argument("xml", help="XML filename to be validated")
    args = parser.parse_args()
    
    is_valid = validate_with_schematron(args.schematron, args.xml)
    
    if is_valid:
        print(f"{args.xml} is valid according to {args.schematron}.")
    else:
        print(f"{args.xml} is not valid according to {args.schematron}.")

if __name__ == "__main__":
    main()