#!/usr/bin/env python3
"""Inspect metadata from the shipping app build, not the evidence harness."""
import json
import pathlib
import sys

app = pathlib.Path(sys.argv[1])
path = app / "Metadata.appintents" / "extract.actionsdata"
with path.open() as source:
    metadata = json.load(source)
action = metadata["actions"]["AskNextRacingSessionIntent"]
assert action["isDiscoverable"] is True, action
assert action["openAppWhenRun"] is False, action
parameters = {parameter["name"]: parameter for parameter in action["parameters"]}
assert parameters["category"]["isOptional"] is True, parameters
assert parameters["sessionKind"]["isOptional"] is False, parameters
assert "RacingCategoryEntity" in metadata["entities"], metadata["entities"]
shortcuts = metadata["autoShortcuts"]
assert len(shortcuts) == 2, shortcuts
shortcut_text = json.dumps(shortcuts, ensure_ascii=False)
assert "Próxima corrida" in shortcut_text and "Próxima sessão" in shortcut_text, shortcuts
assert "applicationName" in shortcut_text, shortcuts
assert (app / "PlugIns" / "WidgetsExtension.appex").is_dir(), "Embedded Widget is missing"
clips = list((app / "AppClips").glob("*.app"))
assert len(clips) == 1, "Embedded App Clip is missing"
print(json.dumps({
    "shippingApp": str(app),
    "action": action["identifier"],
    "optionalCategory": parameters["category"]["isOptional"],
    "shortcuts": len(shortcuts),
    "embeddedWidget": True,
    "embeddedAppClip": clips[0].name,
}, ensure_ascii=False, indent=2))
