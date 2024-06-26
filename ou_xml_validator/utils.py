from lxml import etree
from pathlib import Path
from ou_xml_validator.xml_xslt import get_file

def flatten_to_text(element):
    """
    Recursively flatten an lxml element to text .
    """
    text_content = element.text or ""

    for child in element:
        text_content += " "+flatten_to_text(child)
        if child.tail:
            text_content += child.tail

    return text_content


def xpath_single(start: etree.Element, xpath: str):
    """Retrieve a single element using XPath."""
    return start.xpath(xpath)[0]


def is_valid_filepath(filepath):
    """Check we have a valid filepath."""
    # Create a Path object from the input string
    if filepath is None or filepath=="":
        return False
        
    path = Path(filepath)

    # Use the exists() method to check if the file exists
    return path.exists() and path.is_file()


def apply_xslt(xml_content, xslt_path, set_root=None):
    """Accept XML content and an XSLT file path and trasnform XML accordingly."""
    # Try and find the packaged XLST first
    xslt_content = get_file(xslt_path)
    params = {}
    if set_root:
        params["root_node"] = set_root
    if params:
        xslt_content = xslt_content.format(**params)
    xslt_doc = etree.fromstring(xslt_content)
    xslt_transformer = etree.XSLT(xslt_doc)
    source_doc = etree.fromstring(xml_content)#.encode("utf-8"))
    result = xslt_transformer(source_doc)
    return result


def fix_sphinxXml_nodes(node):
    """Hack fix on nodes."""
    # force some tags to include the full closing tag, eg ou_audio, ou_video
    if node.tag in ["ou_video", "ou_audio"]:
        if node.text is None or not node.text.strip():
            node.text = ""
    # hackfix extraneous leading whitespace in Sphinx-XML
    if node.tag in ["paragraph", "ou_video", "ou_audio"] and node.text:
        node.text = "\n".join([l.lstrip() for l in node.text.split("\n")])
    for child in node:
        fix_sphinxXml_nodes(child)


def root_from_xml_string(xml_string):
    """Generate etree from XML string and return root node."""
    return etree.fromstring(
        xml_string.encode("utf-8"),
        parser=etree.XMLParser(strip_cdata=False, remove_blank_text=True),
    )


def pretty_xml_from_root(xml_root, path=None):
    """Generate a normalised XML string for comparison purposes."""
    pretty_xml_bytes = etree.tostring(xml_root, pretty_print=False, encoding="utf-8")
    if is_valid_filepath(path):
        with open(path, "wb") as file:
            file.write(pretty_xml_bytes)
    return pretty_xml_bytes.decode("utf-8")


def format_xml(xml_path, inplace=True):
    """Format an XML document."""
    root = etree.parse(xml_path)
    if inplace:
        pretty_xml_from_root(root, xml_path)
