import click
import mdformat
from .xml_validator import validate_xml
from .xml_xslt import transform_xml2md
from .md_tools import clean_md
from .utils import format_xml


@click.group()
def cli():
    pass


@cli.command()
@click.argument("path", default="ouxml.xml", type=click.Path(exists=True))
@click.option("--schema", "-s", default=None, help="XML schema filepath")
def validate(path, schema):
    """Validate OU-XML document against OU-XML schema."""
    validate_xml(path, schema)


@cli.command()
@click.argument("xml", default="content.xml", type=click.Path(exists=True))
@click.option("--xslt", "-x", default=None, help="XSLT filepath")
@click.option("--output_path_stub", "-o", default="", help="Output path stub")
def transform(xml, xslt, output_path_stub):
    """Transform OU-XML document using XSLT."""
    transform_xml2md(xml, xslt, output_path_stub)


@cli.command()
@click.argument("path", default=".", type=click.Path(exists=True))
def cleanmd(path):
    """Clean markdown files."""
	# TO DO - is this really a path tool?
	# Can we just get away with mdformat?
    clean_md(path)


@cli.command()
@click.argument("path", default=".", type=click.Path(exists=True))
def format_ouxml(path):
    """Use lxml prettifier to format XML file in-place."""
    format_xml(path)


@cli.command()
@click.argument("path", default=".", type=click.Path(exists=True))
def format_md(path):
	"""Use mdformat formatter to format MyST markdown file in-place."""
	# Input filepath as a string...
	mdformat.file(path)
