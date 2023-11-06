from lxml import etree

def xpath_single(start: etree.Element, xpath: str):
    """Retrieve a single element using XPath."""
    return start.xpath(xpath)[0]