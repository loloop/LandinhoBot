#!/usr/bin/env python3
"""Inspect metadata from the shipping app build, not the evidence harness."""
import json
import pathlib
import plistlib
import subprocess
import sys

app = pathlib.Path(sys.argv[1])
with (app / "Info.plist").open("rb") as source:
    info = plistlib.load(source)
assert info["CFBundleDevelopmentRegion"].replace("_", "-") == "pt-BR", info["CFBundleDevelopmentRegion"]
localization = app / "pt-BR.lproj" / "AppShortcuts.strings"
assert localization.is_file(), "Brazilian Portuguese shortcut phrases are not bundled"
compiled = json.loads(subprocess.check_output(["plutil", "-convert", "json", "-o", "-", str(localization)]))
# Xcode encodes AppShortcuts string-set keys as #!SET#!_<key>[index].
phrases = list(compiled.values())
assert len(phrases) == 5, phrases
assert all("${applicationName}" in phrase for phrase in phrases), phrases
assert "Quando é a próxima corrida no ${applicationName}" in phrases, phrases
assert "Quando é a próxima sessão no ${applicationName}" in phrases, phrases
path = app / "Metadata.appintents" / "extract.actionsdata"
with path.open() as source:
    metadata = json.load(source)
action = metadata["actions"]["AskNextRacingSessionIntent"]
assert action["isDiscoverable"] is True, action
assert action["openAppWhenRun"] is False, action
parameters = {parameter["name"]: parameter for parameter in action["parameters"]}
assert parameters["category"]["isOptional"] is True, parameters
assert parameters["sessionKind"]["isOptional"] is False, parameters
session_defaults = parameters["sessionKind"]["typeSpecificMetadata"]
default_index = session_defaults.index("LNValueTypeSpecificMetadataKeyDefaultValue")
assert session_defaults[default_index + 1] == {"string": {"wrapper": "race"}}, session_defaults
assert "RacingCategoryEntity" in metadata["entities"], metadata["entities"]
shortcuts = metadata["autoShortcuts"]
assert len(shortcuts) == 2, shortcuts
assert {shortcut["actionIdentifier"] for shortcut in shortcuts} == {"AskNextRacingSessionIntent", "AskNextSessionTimeIntent"}, shortcuts
session_action = metadata["actions"]["AskNextSessionTimeIntent"]
assert session_action["parameters"][0]["isOptional"] is True, session_action
shortcut_text = json.dumps(shortcuts, ensure_ascii=False)
assert "Próxima corrida" in shortcut_text and "Próxima sessão" in shortcut_text, shortcuts
assert "applicationName" in shortcut_text, shortcuts
assert all(phrase in shortcut_text for phrase in phrases), "Localized phrase keys are missing from extracted metadata"
training = (app / "Metadata.appintents" / "root.ssu.yaml").read_text()
assert "locale: pt-BR" in training and "locale: en" not in training, training
assert "Quando é a próxima corrida" in training and "Quando é a próxima sessão" in training, training
assert "name: AskNextRacingSessionIntent_" in training and "name: AskNextSessionTimeIntent_" in training, training
assert (app / "PlugIns" / "WidgetsExtension.appex").is_dir(), "Embedded Widget is missing"
clips = list((app / "AppClips").glob("*.app"))
assert len(clips) == 1, "Embedded App Clip is missing"
print(json.dumps({
    "shippingApp": str(app),
    "action": action["identifier"],
    "optionalCategory": parameters["category"]["isOptional"],
    "defaultSessionKind": "race",
    "shortcuts": len(shortcuts),
    "phraseLanguage": info["CFBundleDevelopmentRegion"],
    "bundledPortuguesePhrases": len(phrases),
    "embeddedWidget": True,
    "embeddedAppClip": clips[0].name,
}, ensure_ascii=False, indent=2))
