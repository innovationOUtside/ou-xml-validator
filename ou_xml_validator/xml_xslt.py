from lxml import etree
from pathlib import Path

import os
import pkg_resources


# If it looks like the file is down a directory path, make sure the path is there
# If it isn't, the XSLT won't work when it tries to write the output files...
def check_outdir(output_path_stub):
    if not output_path_stub:
        return
    path = output_path_stub.split("/")
    if len(path) > 1:
        dirpath = "/".join(path[:-1])
        if not os.path.exists(dirpath):
            os.makedirs(dirpath)


def get_file(fn):
    """Get file content from local store."""
    # This should work locally or in package
    if Path(fn).is_file():
        txt = open(fn).read()
    else:
        try:
            fn = pkg_resources.resource_filename(__name__, fn)
            txt = open(fn).read()
        except:
            txt = None
    return txt


def transform_xml2md(xml, xslt=None, output_path_stub=""):
    """Take an OU-XML document as a string
    and transform the document to one or more markdown files."""
    if xslt is None:
        xslt = "xslt/ouxml2myst.xslt"

    if xml.endswith(".xml") and Path(xml).is_file():
        with open(xml, "r") as f:
            xml = f.read()

    check_outdir(output_path_stub)

    _xslt = get_file(xslt)

    xslt_doc = etree.fromstring(_xslt)
    xslt_transformer = etree.XSLT(xslt_doc)

    source_doc = etree.fromstring(xml.encode("utf-8"))

    # It would be handy if we could also retrieve what files the transformer generated?
    # One way of doing this might be to pop everything into a temporary directory
    # and then parse the contents of that directory into a database table?
    output_doc = xslt_transformer(
        source_doc, filestub=etree.XSLT.strparam("{}".format(output_path_stub))
    )
