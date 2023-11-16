from lxml import etree

def apply_xslt(xml_content, xslt_path, set_root=None):
    xslt_content = open(xslt_path).read()
    if set_root:
        xslt_content = xslt_content.format(root_node=set_root)
    xslt_doc = etree.fromstring(xslt_content)
    xslt_transformer = etree.XSLT(xslt_doc)
    source_doc = etree.fromstring(xml_content.encode("utf-8"))
    result = xslt_transformer(source_doc)
    return str(result)
