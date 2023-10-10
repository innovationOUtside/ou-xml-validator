import click
from .xml_validator import validate_xml

@click.group()
def cli():
	pass

@cli.command()
@click.argument('path', default='ouxml.xml', type=click.Path(exists=True))
@click.option('--schema', '-s', default=None, help="XML schema filepath")
def validate(path, schema):
	"""Validate OU-XML document against OU-XML schema."""
	validate_xml(path, schema)
