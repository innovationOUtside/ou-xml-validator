OU_XML = 0
SPHINX_XML = 1
MYST = 2

round_trip_test_list = [
    (
        "<b>This is my text</b>",
        "<strong>This is my text</strong>",
        "__This is my text__",
    ),
    (
        "<i>This is my text</i>",
        "<emphasis>This is my text</emphasis>",
        "*This is my text*",
    ),
    (
        "<Paragraph>A line.\nAnother.</Paragraph>",
        "<paragraph>A line.\nAnother.</paragraph>",
        "\nA line.\nAnother.\n",
    ),
    (
        "<Paragraph>A line.\nAnother. With an <i>emphasised</i> word.</Paragraph>",
        "<paragraph>A line.\nAnother. With an <emphasis>emphasised</emphasis> word.</paragraph>",
        "\nA line.\nAnother. With an *emphasised* word.\n",
    ),
    (
        """<BulletedList>
            <ListItem>
                <Paragraph>item 1</Paragraph>
            </ListItem>
            <ListItem>
                <Paragraph>item 2</Paragraph>
            </ListItem>
        </BulletedList>""",
        """<bullet_list bullet="-">
            <list_item>
                <paragraph>item 1</paragraph>
            </list_item>
            <list_item>
                <paragraph>item 2</paragraph>
            </list_item>
        </bullet_list>""",
        "\n- item 1\n\n- item 2\n",
    )
    # Add more test cases as needed
]
