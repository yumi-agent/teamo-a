#!/usr/bin/env python3
"""Generate TeamoA.xcodeproj/project.pbxproj"""

import hashlib
import os

def uid(name):
    """Generate a deterministic 24-char hex ID from a name."""
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

# All source files relative to TeamoA/
sources = [
    "TeamoAApp.swift",
    "ContentView.swift",
    "Models/AgentEngine.swift",
    "Models/Project.swift",
    "Models/Goal.swift",
    "Models/Issue.swift",
    "Models/Agent.swift",
    "Models/ActivityEvent.swift",
    "Services/PTYManager.swift",
    "Services/AgentStateDetector.swift",
    "Services/NotificationService.swift",
    "Services/ProjectStore.swift",
    "Views/SidebarView.swift",
    "Views/Dashboard/DashboardView.swift",
    "Views/Dashboard/StatCard.swift",
    "Views/Dashboard/ActivityFeedView.swift",
    "Views/Goals/GoalsListView.swift",
    "Views/Goals/CreateGoalView.swift",
    "Views/Issues/IssuesListView.swift",
    "Views/Issues/IssueDetailView.swift",
    "Views/Issues/CreateIssueView.swift",
    "Views/Agents/AgentDetailView.swift",
    "Views/Terminal/SwiftTermView.swift",
    "Views/Terminal/TerminalContainerView.swift",
    "Views/Terminal/InputAreaView.swift",
    "Views/Shared/StatusBadge.swift",
    "Views/Shared/EngineIcon.swift",
]

resources = [
    "Resources/Assets.xcassets",
]

project_id = uid("project")
main_group_id = uid("main_group")
sources_group_id = uid("sources_group")
products_group_id = uid("products_group")
target_id = uid("target")
product_id = uid("product_ref")
build_config_list_project = uid("build_config_list_project")
build_config_list_target = uid("build_config_list_target")
debug_config_project = uid("debug_config_project")
release_config_project = uid("release_config_project")
debug_config_target = uid("debug_config_target")
release_config_target = uid("release_config_target")
sources_phase_id = uid("sources_phase")
resources_phase_id = uid("resources_phase")
frameworks_phase_id = uid("frameworks_phase")
package_product_dep_id = uid("package_product_dep_swiftterm")
package_ref_id = uid("package_ref_swiftterm")

models_group = uid("group_models")
services_group = uid("group_services")
views_group = uid("group_views")
dashboard_group = uid("group_dashboard")
terminal_group = uid("group_terminal")
goals_group = uid("group_goals")
issues_group = uid("group_issues")
agents_group = uid("group_agents")
shared_group = uid("group_shared")
resources_group = uid("group_resources")

file_refs = {}
build_files = {}
for src in sources:
    file_refs[src] = uid(f"fileref_{src}")
    build_files[src] = uid(f"buildfile_{src}")

res_refs = {}
res_build = {}
for res in resources:
    res_refs[res] = uid(f"fileref_{res}")
    res_build[res] = uid(f"buildfile_{res}")

info_plist_ref = uid("fileref_info_plist")
entitlements_ref = uid("fileref_entitlements")

pbx = """// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {

"""

# PBXBuildFile
pbx += "/* Begin PBXBuildFile section */\n"
for src in sources:
    n = os.path.basename(src)
    pbx += f'\t\t{build_files[src]} /* {n} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[src]} /* {n} */; }};\n'
for res in resources:
    n = os.path.basename(res)
    pbx += f'\t\t{res_build[res]} /* {n} in Resources */ = {{isa = PBXBuildFile; fileRef = {res_refs[res]} /* {n} */; }};\n'
pbx += f'\t\t{uid("buildfile_swiftterm")} /* SwiftTerm in Frameworks */ = {{isa = PBXBuildFile; productRef = {package_product_dep_id} /* SwiftTerm */; }};\n'
pbx += "/* End PBXBuildFile section */\n\n"

# PBXFileReference
pbx += "/* Begin PBXFileReference section */\n"
for src in sources:
    n = os.path.basename(src)
    pbx += f'\t\t{file_refs[src]} /* {n} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{n}"; sourceTree = "<group>"; }};\n'
for res in resources:
    n = os.path.basename(res)
    pbx += f'\t\t{res_refs[res]} /* {n} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "{n}"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{info_plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{entitlements_ref} /* TeamoA.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = "TeamoA.entitlements"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{product_id} /* TeamoA.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "TeamoA.app"; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
pbx += "/* End PBXFileReference section */\n\n"

# PBXFrameworksBuildPhase
pbx += f"""/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{uid("buildfile_swiftterm")} /* SwiftTerm in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

"""

# PBXGroup
pbx += "/* Begin PBXGroup section */\n"

pbx += f"""\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{sources_group_id} /* TeamoA */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
"""

pbx += f"""\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{product_id} /* TeamoA.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

# Categorize files
model_files = [f for f in sources if f.startswith("Models/")]
service_files = [f for f in sources if f.startswith("Services/")]
dashboard_files = [f for f in sources if f.startswith("Views/Dashboard/")]
terminal_files = [f for f in sources if f.startswith("Views/Terminal/")]
goals_files = [f for f in sources if f.startswith("Views/Goals/")]
issues_files = [f for f in sources if f.startswith("Views/Issues/")]
agents_files = [f for f in sources if f.startswith("Views/Agents/")]
shared_files = [f for f in sources if f.startswith("Views/Shared/")]

pbx += f"""\t\t{sources_group_id} /* TeamoA */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs["TeamoAApp.swift"]} /* TeamoAApp.swift */,
\t\t\t\t{file_refs["ContentView.swift"]} /* ContentView.swift */,
\t\t\t\t{models_group} /* Models */,
\t\t\t\t{services_group} /* Services */,
\t\t\t\t{views_group} /* Views */,
\t\t\t\t{resources_group} /* Resources */,
\t\t\t\t{info_plist_ref} /* Info.plist */,
\t\t\t\t{entitlements_ref} /* TeamoA.entitlements */,
\t\t\t);
\t\t\tpath = TeamoA;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

def group_block(gid, name, path, files):
    children = ",\n".join([f"\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in files])
    return f"""\t\t{gid} /* {name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children}
\t\t\t);
\t\t\tpath = {path};
\t\t\tsourceTree = "<group>";
\t\t}};
"""

pbx += group_block(models_group, "Models", "Models", model_files)
pbx += group_block(services_group, "Services", "Services", service_files)

# Views group (has subgroups)
pbx += f"""\t\t{views_group} /* Views */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_refs["Views/SidebarView.swift"]} /* SidebarView.swift */,
\t\t\t\t{dashboard_group} /* Dashboard */,
\t\t\t\t{goals_group} /* Goals */,
\t\t\t\t{issues_group} /* Issues */,
\t\t\t\t{agents_group} /* Agents */,
\t\t\t\t{terminal_group} /* Terminal */,
\t\t\t\t{shared_group} /* Shared */,
\t\t\t);
\t\t\tpath = Views;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

pbx += group_block(dashboard_group, "Dashboard", "Dashboard", dashboard_files)
pbx += group_block(goals_group, "Goals", "Goals", goals_files)
pbx += group_block(issues_group, "Issues", "Issues", issues_files)
pbx += group_block(agents_group, "Agents", "Agents", agents_files)
pbx += group_block(terminal_group, "Terminal", "Terminal", terminal_files)
pbx += group_block(shared_group, "Shared", "Shared", shared_files)

res_children = ",\n".join([f"\t\t\t\t{res_refs[f]} /* {os.path.basename(f)} */" for f in resources])
pbx += f"""\t\t{resources_group} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{res_children}
\t\t\t);
\t\t\tpath = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

pbx += "/* End PBXGroup section */\n\n"

# PBXNativeTarget
pbx += f"""/* Begin PBXNativeTarget section */
\t\t{target_id} /* TeamoA */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list_target};
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = TeamoA;
\t\t\tpackageProductDependencies = (
\t\t\t\t{package_product_dep_id} /* SwiftTerm */,
\t\t\t);
\t\t\tproductName = TeamoA;
\t\t\tproductReference = {product_id} /* TeamoA.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

"""

# PBXProject
pbx += f"""/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1430;
\t\t\t\tLastUpgradeCheck = 1430;
\t\t\t}};
\t\t\tbuildConfigurationList = {build_config_list_project};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {main_group_id};
\t\t\tpackageReferences = (
\t\t\t\t{package_ref_id} /* XCRemoteSwiftPackageReference "SwiftTerm" */,
\t\t\t);
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({target_id} /* TeamoA */);
\t\t}};
/* End PBXProject section */

"""

# Build phases
res_file_list = ",\n".join([f"\t\t\t\t{res_build[r]} /* {os.path.basename(r)} in Resources */" for r in resources])
pbx += f"""/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{res_file_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

"""

src_file_list = ",\n".join([f"\t\t\t\t{build_files[s]} /* {os.path.basename(s)} in Sources */" for s in sources])
pbx += f"""/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{src_file_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

"""

# Build configs
base_settings = """ALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;
\t\t\t\tSDKROOT = macosx;"""

target_settings = """ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = TeamoA/TeamoA.entitlements;
\t\t\t\t"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = TeamoA/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks");
\t\t\t\tMARKETING_VERSION = 0.2.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.teamolab.teamoa;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;"""

pbx += f"""/* Begin XCBuildConfiguration section */
\t\t{debug_config_project} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{base_settings}
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_project} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{base_settings}
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_config_target} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings}
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_target} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings}
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_project} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({debug_config_project} /* Debug */, {release_config_project} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{build_config_list_target} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({debug_config_target} /* Debug */, {release_config_target} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

/* Begin XCRemoteSwiftPackageReference section */
\t\t{package_ref_id} /* XCRemoteSwiftPackageReference "SwiftTerm" */ = {{
\t\t\tisa = XCRemoteSwiftPackageReference;
\t\t\trepositoryURL = "https://github.com/migueldeicaza/SwiftTerm.git";
\t\t\trequirement = {{
\t\t\t\tkind = upToNextMajorVersion;
\t\t\t\tminimumVersion = 1.0.0;
\t\t\t}};
\t\t}};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
\t\t{package_product_dep_id} /* SwiftTerm */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = {package_ref_id};
\t\t\tproductName = SwiftTerm;
\t\t}};
/* End XCSwiftPackageProductDependency section */

"""

pbx += f"""\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

proj_dir = os.path.expanduser("~/teamo-a/TeamoA/TeamoA.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)
with open(os.path.join(proj_dir, "project.pbxproj"), "w") as f:
    f.write(pbx)

print(f"Generated {proj_dir}/project.pbxproj")
print(f"Source files: {len(sources)}")
print(f"Resource files: {len(resources)}")
