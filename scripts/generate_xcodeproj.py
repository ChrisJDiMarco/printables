#!/usr/bin/env python3
"""Generate an Xcode .xcodeproj for the Printables iOS app.

Deterministic — the same input always yields the same UUIDs, so the
project.pbxproj is diffable in git.
"""

from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_DIR = ROOT / "Printables"
PROJECT_NAME = "Printables"
BUNDLE_ID = "com.printables.little-learners"
ORG_NAME = "Printables"
DEPLOYMENT_TARGET = "17.0"
SWIFT_VERSION = "5.9"


def uuid_for(key: str) -> str:
    """Return a deterministic 24-char hex UUID for a logical key."""
    return hashlib.sha1(key.encode("utf-8")).hexdigest()[:24].upper()


def list_swift_files() -> list[Path]:
    files: list[Path] = []
    for root, _, names in os.walk(APP_DIR):
        for name in sorted(names):
            if name.endswith(".swift"):
                files.append(Path(root) / name)
    return sorted(files)


def relative_path(file: Path) -> str:
    return str(file.relative_to(APP_DIR))


def group_path(file: Path) -> str:
    rel = file.relative_to(APP_DIR)
    return str(rel.parent) if rel.parent != Path(".") else ""


def build_pbxproj() -> str:
    swift_files = list_swift_files()
    info_plist = APP_DIR / "Resources" / "Info.plist"
    assets = APP_DIR / "Resources" / "Assets.xcassets"
    file_refs: dict[str, dict[str, str]] = {}
    build_files: dict[str, dict[str, str]] = {}

    for file in swift_files:
        ref_key = f"ref::{relative_path(file)}"
        bf_key = f"bf::{relative_path(file)}"
        ref_uuid = uuid_for(ref_key)
        bf_uuid = uuid_for(bf_key)
        file_refs[ref_uuid] = {
            "name": file.name,
            "path": relative_path(file),
            "type": "sourcecode.swift",
            "sourceTree": "<group>",
        }
        build_files[bf_uuid] = {
            "fileRef": ref_uuid,
            "phase": "sources",
        }

    info_ref = uuid_for("ref::Resources/Info.plist")
    file_refs[info_ref] = {
        "name": "Info.plist",
        "path": "Resources/Info.plist",
        "type": "text.plist.xml",
        "sourceTree": "<group>",
    }

    assets_ref = uuid_for("ref::Resources/Assets.xcassets")
    file_refs[assets_ref] = {
        "name": "Assets.xcassets",
        "path": "Resources/Assets.xcassets",
        "type": "folder.assetcatalog",
        "sourceTree": "<group>",
    }
    assets_bf = uuid_for("bf::Resources/Assets.xcassets")
    build_files[assets_bf] = {
        "fileRef": assets_ref,
        "phase": "resources",
    }

    privacy_ref = uuid_for("ref::Resources/PrivacyInfo.xcprivacy")
    file_refs[privacy_ref] = {
        "name": "PrivacyInfo.xcprivacy",
        "path": "Resources/PrivacyInfo.xcprivacy",
        "type": "text.plist.xml",
        "sourceTree": "<group>",
    }
    privacy_bf = uuid_for("bf::Resources/PrivacyInfo.xcprivacy")
    build_files[privacy_bf] = {
        "fileRef": privacy_ref,
        "phase": "resources",
    }

    product_ref = uuid_for("product::Printables.app")
    file_refs[product_ref] = {
        "name": "Printables.app",
        "path": "Printables.app",
        "type": "wrapper.application",
        "sourceTree": "BUILT_PRODUCTS_DIR",
    }

    project_uuid = uuid_for("project::Printables")
    main_group_uuid = uuid_for("group::main")
    products_group_uuid = uuid_for("group::Products")
    app_group_uuid = uuid_for("group::Printables")
    target_uuid = uuid_for("target::Printables")
    sources_phase_uuid = uuid_for("phase::sources")
    resources_phase_uuid = uuid_for("phase::resources")
    frameworks_phase_uuid = uuid_for("phase::frameworks")
    project_config_list_uuid = uuid_for("xcconfig::project")
    target_config_list_uuid = uuid_for("xcconfig::target")
    project_debug_uuid = uuid_for("config::projectDebug")
    project_release_uuid = uuid_for("config::projectRelease")
    target_debug_uuid = uuid_for("config::targetDebug")
    target_release_uuid = uuid_for("config::targetRelease")

    folder_groups: dict[str, dict] = {}
    for file in swift_files:
        parts = relative_path(file).split("/")
        accum = ""
        for part in parts[:-1]:
            accum = f"{accum}/{part}" if accum else part
            if accum not in folder_groups:
                folder_groups[accum] = {
                    "uuid": uuid_for(f"group::{accum}"),
                    "name": part,
                    "path": part,
                    "children": [],
                }

    for file in swift_files:
        ref_uuid = uuid_for(f"ref::{relative_path(file)}")
        parts = relative_path(file).split("/")
        if len(parts) == 1:
            app_children_root.append(ref_uuid) if False else None
        accum = "/".join(parts[:-1])
        if accum:
            folder_groups[accum]["children"].append(ref_uuid)

    def folder_path(group_key: str) -> tuple[str, str | None]:
        parts = group_key.split("/")
        return parts[-1], None

    for key, group in folder_groups.items():
        parts = key.split("/")
        if len(parts) > 1:
            parent_key = "/".join(parts[:-1])
            folder_groups[parent_key]["children"].append(group["uuid"])

    resources_group_key = "Resources"
    if resources_group_key not in folder_groups:
        folder_groups[resources_group_key] = {
            "uuid": uuid_for(f"group::{resources_group_key}"),
            "name": "Resources",
            "path": "Resources",
            "children": [],
        }
    folder_groups[resources_group_key]["children"].extend([info_ref, privacy_ref, assets_ref])

    top_level_group_keys: list[str] = []
    for key in folder_groups:
        if "/" not in key:
            top_level_group_keys.append(key)

    app_group_children: list[str] = []
    seen_groups = set()
    ordered_keys = ["App", "Models", "Services", "Views", "Resources"]
    for key in ordered_keys:
        if key in folder_groups and key not in seen_groups:
            app_group_children.append(folder_groups[key]["uuid"])
            seen_groups.add(key)
    for key in top_level_group_keys:
        if key not in seen_groups:
            app_group_children.append(folder_groups[key]["uuid"])
            seen_groups.add(key)

    lines: list[str] = []
    lines.append("// !$*UTF8*$!")
    lines.append("{")
    lines.append("\tarchiveVersion = 1;")
    lines.append("\tclasses = {")
    lines.append("\t};")
    lines.append("\tobjectVersion = 56;")
    lines.append("\tobjects = {")
    lines.append("")

    lines.append("/* Begin PBXBuildFile section */")
    for uuid, info in sorted(build_files.items()):
        ref_uuid = info["fileRef"]
        ref_name = file_refs[ref_uuid]["name"]
        phase_name = "Resources" if info["phase"] == "resources" else "Sources"
        lines.append(f"\t\t{uuid} /* {ref_name} in {phase_name} */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {ref_name} */; }};")
    lines.append("/* End PBXBuildFile section */")
    lines.append("")

    lines.append("/* Begin PBXFileReference section */")
    for uuid, info in sorted(file_refs.items()):
        name = info["name"]
        path = info["path"]
        type_ = info["type"]
        source_tree = info["sourceTree"]
        if source_tree == "<group>":
            source_tree_str = "\"<group>\""
        else:
            source_tree_str = source_tree
        if name == "Printables.app":
            lines.append(f"\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; explicitFileType = {type_}; includeInIndex = 0; path = {path}; sourceTree = {source_tree_str}; }};")
        else:
            lines.append(f"\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {type_}; path = \"{path.split('/')[-1]}\"; sourceTree = {source_tree_str}; }};")
    lines.append("/* End PBXFileReference section */")
    lines.append("")

    lines.append("/* Begin PBXFrameworksBuildPhase section */")
    lines.append(f"\t\t{frameworks_phase_uuid} /* Frameworks */ = {{")
    lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXFrameworksBuildPhase section */")
    lines.append("")

    lines.append("/* Begin PBXGroup section */")
    lines.append(f"\t\t{main_group_uuid} = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{app_group_uuid} /* Printables */,")
    lines.append(f"\t\t\t\t{products_group_uuid} /* Products */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    lines.append(f"\t\t{products_group_uuid} /* Products */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{product_ref} /* Printables.app */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Products;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    lines.append(f"\t\t{app_group_uuid} /* Printables */ = {{")
    lines.append("\t\t\tisa = PBXGroup;")
    lines.append("\t\t\tchildren = (")
    for child in app_group_children:
        lines.append(f"\t\t\t\t{child},")
    lines.append("\t\t\t);")
    lines.append("\t\t\tpath = Printables;")
    lines.append("\t\t\tsourceTree = \"<group>\";")
    lines.append("\t\t};")

    for key, group in sorted(folder_groups.items()):
        lines.append(f"\t\t{group['uuid']} /* {group['name']} */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for child in group["children"]:
            lines.append(f"\t\t\t\t{child},")
        lines.append("\t\t\t);")
        lines.append(f"\t\t\tpath = {group['path']};")
        lines.append("\t\t\tsourceTree = \"<group>\";")
        lines.append("\t\t};")

    lines.append("/* End PBXGroup section */")
    lines.append("")

    lines.append("/* Begin PBXNativeTarget section */")
    lines.append(f"\t\t{target_uuid} /* Printables */ = {{")
    lines.append("\t\t\tisa = PBXNativeTarget;")
    lines.append(f"\t\t\tbuildConfigurationList = {target_config_list_uuid} /* Build configuration list for PBXNativeTarget \"Printables\" */;")
    lines.append("\t\t\tbuildPhases = (")
    lines.append(f"\t\t\t\t{sources_phase_uuid} /* Sources */,")
    lines.append(f"\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,")
    lines.append(f"\t\t\t\t{resources_phase_uuid} /* Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tbuildRules = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdependencies = (")
    lines.append("\t\t\t);")
    lines.append("\t\t\tname = Printables;")
    lines.append("\t\t\tproductName = Printables;")
    lines.append(f"\t\t\tproductReference = {product_ref} /* Printables.app */;")
    lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    lines.append("\t\t};")
    lines.append("/* End PBXNativeTarget section */")
    lines.append("")

    lines.append("/* Begin PBXProject section */")
    lines.append(f"\t\t{project_uuid} /* Project object */ = {{")
    lines.append("\t\t\tisa = PBXProject;")
    lines.append("\t\t\tattributes = {")
    lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    lines.append("\t\t\t\tLastSwiftUpdateCheck = 1640;")
    lines.append("\t\t\t\tLastUpgradeCheck = 1640;")
    lines.append(f"\t\t\t\tORGANIZATIONNAME = \"{ORG_NAME}\";")
    lines.append("\t\t\t\tTargetAttributes = {")
    lines.append(f"\t\t\t\t\t{target_uuid} = {{")
    lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;")
    lines.append("\t\t\t\t\t};")
    lines.append("\t\t\t\t};")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tbuildConfigurationList = {project_config_list_uuid} /* Build configuration list for PBXProject \"Printables\" */;")
    lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    lines.append("\t\t\tdevelopmentRegion = en;")
    lines.append("\t\t\thasScannedForEncodings = 0;")
    lines.append("\t\t\tknownRegions = (")
    lines.append("\t\t\t\ten,")
    lines.append("\t\t\t\tBase,")
    lines.append("\t\t\t);")
    lines.append(f"\t\t\tmainGroup = {main_group_uuid};")
    lines.append(f"\t\t\tproductRefGroup = {products_group_uuid} /* Products */;")
    lines.append("\t\t\tprojectDirPath = \"\";")
    lines.append("\t\t\tprojectRoot = \"\";")
    lines.append("\t\t\ttargets = (")
    lines.append(f"\t\t\t\t{target_uuid} /* Printables */,")
    lines.append("\t\t\t);")
    lines.append("\t\t};")
    lines.append("/* End PBXProject section */")
    lines.append("")

    lines.append("/* Begin PBXResourcesBuildPhase section */")
    lines.append(f"\t\t{resources_phase_uuid} /* Resources */ = {{")
    lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    lines.append(f"\t\t\t\t{assets_bf} /* Assets.xcassets in Resources */,")
    lines.append(f"\t\t\t\t{privacy_bf} /* PrivacyInfo.xcprivacy in Resources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXResourcesBuildPhase section */")
    lines.append("")

    lines.append("/* Begin PBXSourcesBuildPhase section */")
    lines.append(f"\t\t{sources_phase_uuid} /* Sources */ = {{")
    lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
    lines.append("\t\t\tbuildActionMask = 2147483647;")
    lines.append("\t\t\tfiles = (")
    for uuid, info in sorted(build_files.items()):
        if info["phase"] == "sources":
            ref_uuid = info["fileRef"]
            ref_name = file_refs[ref_uuid]["name"]
            lines.append(f"\t\t\t\t{uuid} /* {ref_name} in Sources */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    lines.append("\t\t};")
    lines.append("/* End PBXSourcesBuildPhase section */")
    lines.append("")

    lines.append("/* Begin XCBuildConfiguration section */")

    def append_project_config(uuid: str, name: str, debug: bool) -> None:
        lines.append(f"\t\t{uuid} /* {name} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
        lines.append("\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
        lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
        lines.append("\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;")
        lines.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
        lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
        lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
        lines.append("\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;")
        lines.append("\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;")
        lines.append("\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_COMMA = YES;")
        lines.append("\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;")
        lines.append("\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;")
        lines.append("\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;")
        lines.append("\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;")
        lines.append("\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;")
        lines.append("\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;")
        lines.append("\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;")
        lines.append("\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;")
        lines.append("\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;")
        lines.append("\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;")
        lines.append("\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;")
        lines.append("\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;")
        lines.append("\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;")
        lines.append("\t\t\t\tCOPY_PHASE_STRIP = NO;")
        lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";" if not debug else "\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
        if debug:
            lines.append("\t\t\t\tENABLE_TESTABILITY = YES;")
        lines.append("\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;")
        lines.append("\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;")
        lines.append("\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;")
        if debug:
            lines.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
            lines.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
            lines.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\",);")
        lines.append("\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;")
        lines.append("\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;")
        lines.append("\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;")
        lines.append("\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;")
        lines.append("\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;")
        lines.append("\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;")
        lines.append("\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;")
        lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};")
        lines.append("\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;")
        lines.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = " + ("INCLUDE_SOURCE" if debug else "NO") + ";")
        lines.append("\t\t\t\tMTL_FAST_MATH = YES;")
        if not debug:
            lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        lines.append("\t\t\t\tONLY_ACTIVE_ARCH = " + ("YES" if debug else "NO") + ";")
        lines.append("\t\t\t\tSDKROOT = iphoneos;")
        if debug:
            lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = (\"DEBUG\", \"$(inherited)\",);")
            lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
        else:
            lines.append("\t\t\t\tVALIDATE_PRODUCT = YES;")
        lines.append(f"\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {name};")
        lines.append("\t\t};")

    append_project_config(project_debug_uuid, "Debug", debug=True)
    append_project_config(project_release_uuid, "Release", debug=False)

    def append_target_config(uuid: str, name: str) -> None:
        lines.append(f"\t\t{uuid} /* {name} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
        lines.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
        lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
        lines.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
        lines.append("\t\t\t\tENABLE_PREVIEWS = YES;")
        lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
        lines.append("\t\t\t\tINFOPLIST_FILE = Printables/Resources/Info.plist;")
        lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
        lines.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;")
        lines.append("\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;")
        lines.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
        lines.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;")
        lines.append(f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};")
        lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\",);")
        lines.append("\t\t\t\tMARKETING_VERSION = 1.0.0;")
        lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"{BUNDLE_ID}\";")
        lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
        lines.append("\t\t\t\tSUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";")
        lines.append("\t\t\t\tSUPPORTS_MACCATALYST = NO;")
        lines.append("\t\t\t\tSUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;")
        lines.append("\t\t\t\tSUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;")
        lines.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
        lines.append(f"\t\t\t\tSWIFT_VERSION = {SWIFT_VERSION};")
        lines.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {name};")
        lines.append("\t\t};")

    append_target_config(target_debug_uuid, "Debug")
    append_target_config(target_release_uuid, "Release")
    lines.append("/* End XCBuildConfiguration section */")
    lines.append("")

    lines.append("/* Begin XCConfigurationList section */")
    lines.append(f"\t\t{project_config_list_uuid} /* Build configuration list for PBXProject \"Printables\" */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{project_debug_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{project_release_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")

    lines.append(f"\t\t{target_config_list_uuid} /* Build configuration list for PBXNativeTarget \"Printables\" */ = {{")
    lines.append("\t\t\tisa = XCConfigurationList;")
    lines.append("\t\t\tbuildConfigurations = (")
    lines.append(f"\t\t\t\t{target_debug_uuid} /* Debug */,")
    lines.append(f"\t\t\t\t{target_release_uuid} /* Release */,")
    lines.append("\t\t\t);")
    lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    lines.append("\t\t\tdefaultConfigurationName = Release;")
    lines.append("\t\t};")
    lines.append("/* End XCConfigurationList section */")
    lines.append("")

    lines.append("\t};")
    lines.append(f"\trootObject = {project_uuid} /* Project object */;")
    lines.append("}")
    return "\n".join(lines) + "\n"


app_children_root: list[str] = []


def main() -> None:
    proj_dir = ROOT / "Printables.xcodeproj"
    proj_dir.mkdir(exist_ok=True)
    pbxproj_path = proj_dir / "project.pbxproj"
    pbxproj_path.write_text(build_pbxproj(), encoding="utf-8")
    print(f"Wrote {pbxproj_path} ({pbxproj_path.stat().st_size // 1024} KB)")

    workspace_dir = proj_dir / "project.xcworkspace"
    workspace_dir.mkdir(exist_ok=True)
    (workspace_dir / "contents.xcworkspacedata").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Workspace version="1.0">\n'
        '   <FileRef location="self:"></FileRef>\n'
        '</Workspace>\n',
        encoding="utf-8",
    )
    (workspace_dir / "xcshareddata").mkdir(exist_ok=True)
    (workspace_dir / "xcshareddata" / "IDEWorkspaceChecks.plist").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0">\n<dict>\n'
        '\t<key>IDEDidComputeMac32BitWarning</key>\n\t<true/>\n'
        '</dict>\n</plist>\n',
        encoding="utf-8",
    )
    print(f"Wrote {workspace_dir}/contents.xcworkspacedata")


if __name__ == "__main__":
    main()
