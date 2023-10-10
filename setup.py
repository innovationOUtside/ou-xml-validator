from setuptools import setup

setup(
    name="ou_xml_validator",
    packages=['ou_xml_validator'],
    version='0.0.1',
    author="Tony Hirst",
    author_email="tony.hirst@gmail.com",
    description="Simple OU-XML document validator.",
    long_description='''
    Tools to support validate the creation of well formed OUXML.
    ''',
    long_description_content_type="text/markdown",
    install_requires=[
        'click',
        'xmlschema',
        'lxml'
    ],
    package_data={
        'ou_xml_validator': ['schemas/*.xsd', 'schemas/mathml3/xsd/*.xsd'],  # Include all XSD files in the schemas directory
    },
    entry_points='''
        [console_scripts]
        ou_xml_validator=ou_xml_validator.cli:cli
    '''

)