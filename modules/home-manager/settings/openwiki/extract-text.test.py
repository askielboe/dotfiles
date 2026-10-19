import importlib.util
import io
import pathlib
import unittest
import zipfile
from unittest.mock import patch

from defusedxml.common import EntitiesForbidden

SPEC = importlib.util.spec_from_file_location("extract_text", pathlib.Path(__file__).with_name("extract-text.py"))
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Text extractor is unavailable")
extractor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(extractor)


def archive(files):
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w") as zipped:
        for name, value in files.items():
            zipped.writestr(name, value)
    return output.getvalue()


class TextExtractionTests(unittest.TestCase):
    def test_word_paragraphs_and_headers(self):
        data = archive({
            "word/document.xml": '<document><p><r><t>First paragraph</t></r></p><p><r><t>Second paragraph</t></r></p></document>',
            "word/header1.xml": '<header><p><t>Header</t></p></header>',
        })
        text = extractor.extract(data, "office")
        self.assertIn("First paragraph\nSecond paragraph", text)
        self.assertIn("Header", text)

    def test_all_spreadsheet_sheets_and_formula_caches(self):
        data = archive({
            "xl/workbook.xml": '<workbook xmlns:r="urn:relations"><sheets><sheet name="First" r:id="r1"/><sheet name="Second" r:id="r2"/></sheets></workbook>',
            "xl/_rels/workbook.xml.rels": '<Relationships><Relationship Id="r1" Target="worksheets/sheet1.xml"/><Relationship Id="r2" Target="/xl/worksheets/sheet2.xml"/></Relationships>',
            "xl/sharedStrings.xml": '<sst><si><t>Shared value</t></si></sst>',
            "xl/worksheets/sheet1.xml": '<worksheet><row><c r="A1" t="s"><v>0</v></c></row></worksheet>',
            "xl/worksheets/sheet2.xml": '<worksheet><row><c r="B2"><f>1+2</f><v>3</v></c><c r="A3" t="inlineStr"><is><t>Inline value</t></is></c></row></worksheet>',
        })
        text = extractor.extract(data, "office")
        for value in ["# Sheet: First", "# Sheet: Second", "Shared value", "=1+2 [cached: 3]", "Inline value"]:
            self.assertIn(value, text)

    def test_spreadsheet_rows_stream_without_the_archive_expansion_limit(self):
        rows = "".join(f'<row><c r="A{row}"><v>{row}</v></c></row>' for row in range(1, 10001))
        data = archive({
            "xl/workbook.xml": '<workbook xmlns:r="urn:relations"><sheets><sheet name="All rows" r:id="r1"/></sheets></workbook>',
            "xl/_rels/workbook.xml.rels": '<Relationships><Relationship Id="r1" Target="worksheets/sheet1.xml"/></Relationships>',
            "xl/worksheets/sheet1.xml": f'<worksheet><sheetData>{rows}</sheetData></worksheet>',
        })
        info = zipfile.ZipInfo("xl/worksheets/sheet1.xml")
        info.file_size = 300 * 1024 * 1024
        with patch.object(zipfile.ZipFile, "infolist", return_value=[info]):
            lines = extractor.extract(data, "office").splitlines()
        self.assertEqual(len(lines), 10001)
        self.assertEqual(lines[1], "A1\t1")
        self.assertEqual(lines[-1], "A10000\t10000")

    def test_spreadsheet_shared_strings_keep_the_expansion_limit(self):
        data = archive({
            "xl/workbook.xml": '<workbook/>',
            "xl/sharedStrings.xml": '<sst><si><t>Value</t></si></sst>',
        })
        info = zipfile.ZipInfo("xl/sharedStrings.xml")
        info.file_size = 300 * 1024 * 1024
        with patch.object(zipfile.ZipFile, "infolist", return_value=[info]):
            with self.assertRaisesRegex(ValueError, "extraction memory budget"):
                extractor.extract(data, "office")

    def test_slide_notes_follow_relationships_not_slide_numbers(self):
        data = archive({
            "ppt/slides/slide1.xml": '<slide><p><t>Slide title</t></p></slide>',
            "ppt/slides/_rels/slide1.xml.rels": '<Relationships><Relationship Type="http://example/notesSlide" Target="../notesSlides/notesSlide7.xml"/></Relationships>',
            "ppt/notesSlides/notesSlide7.xml": '<notes><p><t>Correct notes</t></p></notes>',
        })
        text = extractor.extract(data, "office")
        self.assertIn("Slide title", text)
        self.assertIn("Correct notes", text)

    def test_xml_entities_are_rejected(self):
        data = archive({"word/document.xml": '<!DOCTYPE doc [<!ENTITY injected "malicious">]><doc><p><t>&injected;</t></p></doc>'})
        with self.assertRaises(EntitiesForbidden):
            extractor.extract(data, "office")

    def test_unknown_archive_is_not_silently_empty(self):
        with self.assertRaises(ValueError):
            extractor.extract(archive({"unknown.xml": "<root/>"}), "office")


if __name__ == "__main__":
    unittest.main()
