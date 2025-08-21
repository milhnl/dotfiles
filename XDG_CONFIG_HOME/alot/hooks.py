import tempfile
import asyncio
import subprocess
import webbrowser
from alot.helper import string_decode, string_sanitize


def open_in_browser(ui=None):
    for part in ui.current_buffer.get_selected_message().get_email().walk():
        if part.get_content_type() != "text/html":
            continue
        if part.get("Content-Disposition", "").startswith("attachment"):
            continue
        e = part.get_content_charset() or "utf-8"
        r = string_sanitize(string_decode(part.get_payload(decode=True), e))
        temp = tempfile.NamedTemporaryFile(suffix=".html", delete=False)
        temp.write(r.encode("utf-8"))
        temp.flush()
        temp.close()
        webbrowser.open(temp.name)
        ui.notify("Opened email in browser")
        return
    ui.notify("No html part in email")


async def sync(ui=None):
    notification = ui.notify("Fetching mail...", timeout=-1)
    notmuch_new = await asyncio.create_subprocess_exec(
        "notmuch", "new", stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )

    out, err = await notmuch_new.communicate()
    ui.clear_notify([notification])
    if notmuch_new.returncode:
        ui.notify("Fetching mail failed")
    else:
        ui.notify("Mail fetched")
        ui.current_buffer.rebuild()
