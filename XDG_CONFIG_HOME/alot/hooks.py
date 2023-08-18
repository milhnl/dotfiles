import tempfile
import webbrowser
from alot.helper import string_decode, string_sanitize


def open_in_browser(ui=None):
    for part in ui.current_buffer.get_selected_message().get_email().walk():
        if part.get_content_type() != "text/html":
            continue
        if part.get('Content-Disposition', '').startswith('attachment'):
            continue
        e = part.get_content_charset() or 'utf-8'
        r = string_sanitize(string_decode(part.get_payload(decode=True), e))
        temp = tempfile.NamedTemporaryFile(suffix=".html", delete=False)
        temp.write(r.encode('utf-8'))
        temp.flush()
        temp.close()
        webbrowser.open(temp.name)
        ui.notify("Opened email in browser")
        return
    ui.notify("No html part in email")
