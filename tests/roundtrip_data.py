OU_XML = 0
SPHINX_XML = 1
MYST = 2

# Triple is: OU-XML, Sphinx-XML, markdown

# TO DO - the strong, emphasis, etc that must be in a para etc need test hacks.
# TO DO - tags like ou_audio and ou_video should not be parsed as self-closing
round_trip_test_list = [
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
        "<Paragraph>A line.\nAnother. With an <i>emphasised</i> word and a <b>word</b>.</Paragraph>",
        "<paragraph>A line.\nAnother. With an <emphasis>emphasised</emphasis> word and a <strong>word</strong>.</paragraph>",
        "\nA line.\nAnother. With an *emphasised* word and a __word__.\n",
    ),
    (
        "<Paragraph>A line.\nAnother. With an <i>emphasised</i> word and a <b>word</b>.</Paragraph>",
        "<paragraph>A line.\nAnother. With an <emphasis>emphasised</emphasis> word and a <strong>word</strong>.</paragraph>",
        "\nA line.\nAnother. With an *emphasised* word and a __word__.\n",
    ),
    (
        "<Paragraph>An <i>emphasised <b>word</b></i>.</Paragraph>",
        "<paragraph>An <emphasis>emphasised <strong>word</strong></emphasis>.</paragraph>",
        "\nAn *emphasised __word__*.\n",
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
    ),
    (
        """<MediaContent type="audio" src="test.mp3">\n<Caption>An audio caption.</Caption>\n</MediaContent>""",
        """<ou_audio autoplay="False" controls="True" klass="" loop="False" muted="False" preload="auto" src="test.mp3">\n<caption>An audio caption.</caption>\n</ou_audio>""",
        """\n\n```{ou-audio} test.mp3\nAn audio caption.\n\n\n```\n\n""",
    ),
    (
        """<MediaContent type="video" height="150" width="100" src="test.mp4"/>""",
        """<ou_video alt="" autoplay="False" controls="True" height="150" klass="" loop="False" muted="False" poster="" preload="auto" src="test.mp4" width="100"></ou_video>""",
        """\n\n```{ou-video} test.mp4\n:height: 150\n:width: 100\n```\n\n""",
    )
    # Add more test cases as needed
]
