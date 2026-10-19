import io
import os
import re
import subprocess
import sys
import zipfile

from defusedxml import ElementTree as ET


def text_nodes(element):
    return "".join(node.text or "" for node in element.iter() if node.tag.rsplit("}", 1)[-1] == "t")


def archive_text(data):
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        names = archive.namelist()
        streamed_workbook = "xl/workbook.xml" in names
        if sum(item.file_size for item in archive.infolist()
               if not (streamed_workbook and re.match(r"xl/worksheets/[^/]+\.xml$", item.filename))) > 256 * 1024 * 1024:
            raise ValueError("Expanded office archive exceeds extraction memory budget")
        if "word/document.xml" in names:
            paths = ["word/document.xml"] + sorted(name for name in names if re.match(r"word/(header|footer|footnotes|endnotes).*\.xml$", name))
            for path in paths:
                root = ET.fromstring(archive.read(path))
                for element in root.iter():
                    if element.tag.rsplit("}", 1)[-1] == "p":
                        yield text_nodes(element)
        elif "xl/workbook.xml" in names:
            shared = []
            if "xl/sharedStrings.xml" in names:
                with archive.open("xl/sharedStrings.xml") as source:
                    context = ET.iterparse(source, events=("start", "end"))
                    _, root = next(context)
                    for event, item in context:
                        if event == "end" and item.tag.rsplit("}", 1)[-1] == "si":
                            shared.append(text_nodes(item))
                            root.clear()
            workbook = ET.fromstring(archive.read("xl/workbook.xml"))
            relations = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
            targets = {item.attrib["Id"]: item.attrib["Target"] for item in relations}
            for sheet in workbook.iter():
                if sheet.tag.rsplit("}", 1)[-1] != "sheet":
                    continue
                relation = next(value for key, value in sheet.attrib.items() if key.endswith("}id"))
                target = targets[relation]
                path = target.lstrip("/") if target.startswith("/") else "xl/" + target
                path = os.path.normpath(path)
                if not path.startswith("xl/worksheets/"):
                    raise ValueError("Unsupported workbook sheet target")
                yield "# Sheet: " + sheet.attrib["name"]
                with archive.open(path) as source:
                    rows = None
                    for event, cell in ET.iterparse(source, events=("start", "end")):
                        kind = cell.tag.rsplit("}", 1)[-1]
                        if event == "start":
                            if kind == "sheetData":
                                rows = cell
                            continue
                        if kind == "row" and rows is not None:
                            rows.clear()
                        if kind != "c":
                            continue
                        values = {child.tag.rsplit("}", 1)[-1]: child for child in cell}
                        value = values.get("v")
                        content = value.text or "" if value is not None else ""
                        if cell.attrib.get("t") == "s":
                            content = shared[int(content)]
                        elif cell.attrib.get("t") == "inlineStr":
                            content = text_nodes(cell)
                        formula = values.get("f")
                        if formula is not None:
                            content = "=" + (formula.text or "") + " [cached: " + content + "]"
                        yield cell.attrib.get("r", "") + "\t" + content
                        cell.clear()
        elif any(name.startswith("ppt/slides/slide") for name in names):
            paths = sorted((name for name in names if re.match(r"ppt/slides/slide\d+\.xml$", name)), key=lambda name: int(name.rsplit("slide", 1)[1].split(".")[0]))
            for path in paths:
                yield "# " + path
                root = ET.fromstring(archive.read(path))
                for element in root.iter():
                    if element.tag.rsplit("}", 1)[-1] == "p":
                        yield text_nodes(element)
                relations_path = path.replace("slides/", "slides/_rels/") + ".rels"
                if relations_path in names:
                    relations = ET.fromstring(archive.read(relations_path))
                    for relation in relations:
                        if not relation.attrib.get("Type", "").endswith("/notesSlide"):
                            continue
                        note_path = os.path.normpath("ppt/slides/" + relation.attrib["Target"])
                        if not note_path.startswith("ppt/notesSlides/"):
                            raise ValueError("Unsupported presentation notes target")
                        yield "# Speaker notes"
                        yield text_nodes(ET.fromstring(archive.read(note_path)))
        elif "content.xml" in names:
            root = ET.fromstring(archive.read("content.xml"))
            for element in root.iter():
                if element.tag.rsplit("}", 1)[-1] in {"p", "h"}:
                    yield "".join(element.itertext())
        else:
            raise ValueError("Office archive has no supported text content")


def extract(data, mime):
    if mime == "application/pdf":
        result = subprocess.run([os.environ.get("OPENWIKI_PDFTOTEXT", "pdftotext"), "-layout", "-", "-"], input=data, capture_output=True, timeout=90, check=True)
        return result.stdout.decode("utf-8")
    return "\n".join(archive_text(data))


if __name__ == "__main__":
    try:
        sys.stdout.write(extract(sys.stdin.buffer.read(), sys.argv[1]))
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
