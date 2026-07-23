#!/usr/bin/env bash
#
# Converts Maven Surefire HTML report to Markdown.
# Default: ./target/reports/surefire.html -> ./target/reports/surefire.md
# Usage: ./jfrog/convertReport2Md.sh [input.html] [output.md]
#
# Note: convertXml2Json.sh converts Surefire XML -> JSON for evidence predicates.
#       This script converts the Maven site HTML report -> Markdown for review.
#

set -euo pipefail

PROJECT_ROOT="$(pwd)"
INPUT_HTML="${1:-$PROJECT_ROOT/target/reports/surefire.html}"
OUTPUT_MD="${2:-$PROJECT_ROOT/target/reports/surefire.md}"

if [ ! -f "$INPUT_HTML" ]; then
    echo "Error: HTML report does not exist: $INPUT_HTML" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to convert HTML to Markdown." >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_MD")"

python3 - "$INPUT_HTML" "$OUTPUT_MD" <<'PY'
import html
import re
import sys
from html.parser import HTMLParser

input_path, output_path = sys.argv[1], sys.argv[2]


VOID_TAGS = {
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "link", "meta", "param", "source", "track", "wbr",
}


class SurefireHtmlToMarkdown(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []
        self.skip_depth = 0
        self.capture = False  # start at "Surefire Report" heading
        self.in_th = False
        self.in_td = False
        self.in_heading = False
        self.in_toc_p = False
        self.heading_level = 1
        self.heading_buf = []
        self.toc_buf = []
        self.row_cells = []
        self.row_is_header = False
        self.cell_buf = []
        self.pending_blank = False

    def _emit(self, text: str) -> None:
        if not text or not self.capture:
            return
        self.pending_blank = False
        self.parts.append(text)

    def _emit_line(self, text: str = "") -> None:
        if not self.capture:
            return
        self.parts.append(text.rstrip() + "\n")
        self.pending_blank = False

    def _ensure_blank(self) -> None:
        if not self.capture or not self.parts or self.pending_blank:
            return
        if not self.parts[-1].endswith("\n\n"):
            if self.parts[-1].endswith("\n"):
                self.parts.append("\n")
            else:
                self.parts.append("\n\n")
        self.pending_blank = True

    def _flush_cell(self) -> None:
        text = html.unescape("".join(self.cell_buf))
        text = re.sub(r"\s+", " ", text).strip()
        text = text.replace("|", "\\|")
        self.row_cells.append(text or " ")
        self.cell_buf = []

    def _flush_row(self) -> None:
        if not self.row_cells or not self.capture:
            self.row_cells = []
            self.row_is_header = False
            return
        cells = self.row_cells
        line = "| " + " | ".join(cells) + " |"
        self._emit_line(line)
        if self.row_is_header:
            self._emit_line("| " + " | ".join("---" for _ in cells) + " |")
        self.row_cells = []
        self.row_is_header = False

    def _start_skip(self):
        self.skip_depth = 1

    def _icon_token(self, src: str) -> str:
        if "icon_success" in src:
            return "PASS"
        if "icon_warning" in src:
            return "WARN"
        if "icon_error" in src or "icon_failure" in src:
            return "FAIL"
        return ""

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        attrs_dict = dict(attrs)

        if self.skip_depth:
            if tag not in VOID_TAGS:
                self.skip_depth += 1
            return

        # Ignore Maven Fluido chrome / JS detail toggles.
        if tag in {"script", "style", "head", "header", "nav", "footer"}:
            self._start_skip()
            return
        if tag == "div" and attrs_dict.get("class") == "detailToggle":
            self._start_skip()
            return

        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            self.in_heading = True
            self.heading_level = int(tag[1])
            self.heading_buf = []
            return

        if not self.capture:
            return

        # Drop TOC jumplinks paragraphs: [Summary] [Package List] ...
        if tag == "p":
            self.in_toc_p = True
            self.toc_buf = []
            return

        if tag == "tr":
            self.row_cells = []
            self.row_is_header = False
            return
        if tag == "th":
            self.in_th = True
            self.row_is_header = True
            self.cell_buf = []
            return
        if tag == "td":
            self.in_td = True
            self.cell_buf = []
            return
        if tag == "img":
            token = self._icon_token(attrs_dict.get("src", ""))
            if token and (self.in_th or self.in_td):
                self.cell_buf.append(token)
            return

    def handle_startendtag(self, tag, attrs):
        # XHTML void tags like <img ... /> / <br />
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag):
        tag = tag.lower()
        if self.skip_depth:
            if tag not in VOID_TAGS:
                self.skip_depth -= 1
            return

        if tag in {"h1", "h2", "h3", "h4", "h5", "h6"}:
            text = re.sub(r"\s+", " ", "".join(self.heading_buf)).strip()
            self.in_heading = False
            self.heading_buf = []
            if not text:
                return
            if not self.capture and text == "Surefire Report":
                self.capture = True
            if not self.capture:
                return
            self._ensure_blank()
            self._emit_line("#" * self.heading_level + " " + text)
            self._ensure_blank()
            return

        if not self.capture:
            return

        if tag == "p":
            text = re.sub(r"\s+", " ", "".join(getattr(self, "toc_buf", []))).strip()
            self.in_toc_p = False
            self.toc_buf = []
            # Skip TOC jumplink lines and empty notes.
            if not text or re.fullmatch(r"(\[[^\]]+\]\s*)+", text):
                return
            if text.startswith("©"):
                return
            self._ensure_blank()
            self._emit_line(text)
            self._ensure_blank()
            return

        if tag == "th":
            self._flush_cell()
            self.in_th = False
            return
        if tag == "td":
            self._flush_cell()
            self.in_td = False
            return
        if tag == "tr":
            self._flush_row()
            return
        if tag == "table":
            self._ensure_blank()
            return

    def handle_data(self, data):
        if self.skip_depth:
            return
        if self.in_heading:
            self.heading_buf.append(data)
            return
        if not self.capture:
            return
        if getattr(self, "in_toc_p", False):
            self.toc_buf.append(data)
            return
        if self.in_th or self.in_td:
            self.cell_buf.append(data)

    def output(self) -> str:
        text = "".join(self.parts)
        text = re.sub(r"[ \t]+\n", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip() + "\n"


with open(input_path, "r", encoding="utf-8", errors="replace") as fh:
    raw = fh.read()

parser = SurefireHtmlToMarkdown()
parser.feed(raw)
parser.close()
md = parser.output()
if not md.strip():
    raise SystemExit(f"Error: no Surefire Report content found in {input_path}")

with open(output_path, "w", encoding="utf-8") as fh:
    fh.write(md)

print(f"Surefire report converted to Markdown: {output_path}")
PY

echo "Input : $INPUT_HTML"
echo "Output: $OUTPUT_MD"
