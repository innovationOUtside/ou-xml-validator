from setuptools import setup

setup(
    name="ou_xml_validator",
    packages=["ou_xml_validator"],
    version="0.0.3",
    author="Tony Hirst",
    author_email="tony.hirst@gmail.com",
    description="Simple OU-XML document validator.",
    long_description="""
    Tools to support validate the creation of well formed OUXML.
    """,
    long_description_content_type="text/markdown",
    install_requires=[
        "click",
        "xmlschema",
        "lxml",
        "pyyaml",
        "rich",
        "typer[all]",
        "mdformat",
        "mdformat-myst",
        "mdformat-tables",
        "mdformat-web",
        "plotly",
    ],
    package_data={
        "ou_xml_validator": [
            "xslt/*.xsl",
            "xslt/*.xslt",
            "templates/*.xml",
            "templates/*.xslt",
            "schemas/*.xsd",
            "schemas/mathml3/xsd/*.xsd",
            "mermaid-cli/*json",
        ],  # Include all XSD files in the schemas directory
    },
    entry_points="""
        [console_scripts]
        ou_xml_validator=ou_xml_validator.cli:cli
        ouseful_obt=ou_xml_validator.obt:main
        ouseful_ouxml2md=ou_xml_validator.ouxml2md:main
        ouseful_ouxml2tw=ou_xml_validator.ouxml2tw:main
        ouseful_ipynb2md=ou_xml_validator.ouxml2md:main
        ouseful_ouxml2mm=ou_xml_validator.ouxml2mm:main
    """,
)
