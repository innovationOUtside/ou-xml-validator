from lxml import etree


def apply_xslt(xml_content, xslt_path, set_root=None):
    xslt_content = open(xslt_path).read()
    params = {}
    if set_root:
        params["root_node"] = set_root
    if params:
        xslt_content = xslt_content.format(**params)
    xslt_doc = etree.fromstring(xslt_content)
    xslt_transformer = etree.XSLT(xslt_doc)
    source_doc = etree.fromstring(xml_content.encode("utf-8"))
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


def pretty_xml_from_root(xml_root):
    """Generate a normalised XML string for comparison purposes."""
    pretty_xml = etree.tostring(xml_root, pretty_print=False, encoding="utf-8").decode(
        "utf-8"
    )
    return pretty_xml
