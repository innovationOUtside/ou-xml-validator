# Transforming OU-XML to Markdown/MyST

An XSLT based transformation for transforming a single OU-XML file to one or more markdown files. *A post-processor script then cleans and formats the generated markdown.*

`ou_xml_validator transform path-to-file/content.xml`

We can clean the markdown as follows:

```bash
# pip3 install mdformat mdformat-myst
mdformat src 
ou_xml_validator cleanmd PATH
# If it's simple markdown, transform to myst
jupytext --to myst src/*.md
```

