"""
Simple tests of mapping OU-XML to desired markdown output.
"""
import pytest
from utils import apply_xslt
from roundtrip_data import round_trip_test_list, OU_XML, SPHINX_XML, MYST

XSLT_PATH = "ou_xml_validator/xslt/ouxml2md.xslt"

test_list = [(i[OU_XML], i[MYST]) for i in round_trip_test_list]


@pytest.mark.parametrize(
    "xml_content, expected_output",
    (test_list),
)
def test_apply_xslt(xml_content, expected_output, xslt_path=XSLT_PATH):
    result = apply_xslt(xml_content, xslt_path)
    assert result == expected_output
