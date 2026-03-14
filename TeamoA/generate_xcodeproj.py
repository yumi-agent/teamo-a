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
    "Models/SessionState.swift",
    "Models/AgentSession.swift",
    "Services/PTYManager.swift",
    "Services/AgentStateDetector.swift",
    "Services/NotificationService.swift",
    "Services/SessionStore.swift",
    "Views/SidebarView.swift",
    "Views/Dashboard/DashboardView.swift",
    "Views/Dashboard/SessionCard.swift",
    "Views/Terminal/SwiftTermView.swift",
    "Views/Terminal/TerminalContainerView.swift",
    "Views/Terminal/InputAreaView.swift",
    "Views/Session/CreateSessionView.swift",
    "Views/Session/SessionDetailView.swift",
    "Views/Shared/StatusBadge.swift",
    "Views/Shared/EngineIcon.swift",
]

resources = [
    "Resources/Assets.xcassets",
]

# Generate IDs
project_id = uid("project")
main_group_id = uid("main_group")
sources_group_id = uid("sources_group")
products_group_id = uid("products_group")
frameworks_group_id = uid("frameworks_group")
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
package_dep_id = uid("package_dep_swiftterm")
package_product_dep_id = uid("package_product_dep_swiftterm")
package_ref_id = uid("package_ref_swiftterm")

# Groups for organizing
models_group = uid("group_models")
services_group = uid("group_services")
views_group = uid("group_views")
dashboard_group = uid("group_dashboard")
terminal_group = uid("group_terminal")
session_group = uid("group_session")
shared_group = uid("group_shared")
resources_group = uid("group_resources")

# File references and build files
file_refs = {}
build_files = {}
for src in sources:
    fr_id = uid(f"fileref_{src}")
    bf_id = uid(f"buildfile_{src}")
    file_refs[src] = fr_id
    build_files[src] = bf_id

res_refs = {}
res_build = {}
for res in resources:
    fr_id = uid(f"fileref_{res}")
    bf_id = uid(f"buildfile_{res}")
    res_refs[res] = fr_id
    res_build[res] = bf_id

info_plist_ref = uid("fileref_info_plist")
entitlements_ref = uid("fileref_entitlements")

# Build the pbxproj
pbx = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

"""

# PBXBuildFile section
pbx += "/* Begin PBXBuildFile section */\n"
for src in sources:
    name = os.path.basename(src)
    pbx += f'\t\t{build_files[src]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[src]} /* {name} */; }};\n'
for res in resources:
    name = os.path.basename(res)
    pbx += f'\t\t{res_build[res]} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {res_refs[res]} /* {name} */; }};\n'
# SwiftTerm package product
pbx += f'\t\t{uid("buildfile_swiftterm")} /* SwiftTerm in Frameworks */ = {{isa = PBXBuildFile; productRef = {package_product_dep_id} /* SwiftTerm */; }};\n'
pbx += "/* End PBXBuildFile section */\n\n"

# PBXFileReference section
pbx += "/* Begin PBXFileReference section */\n"
for src in sources:
    name = os.path.basename(src)
    pbx += f'\t\t{file_refs[src]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>"; }};\n'
for res in resources:
    name = os.path.basename(res)
    pbx += f'\t\t{res_refs[res]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "{name}"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{info_plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{entitlements_ref} /* TeamoA.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = "TeamoA.entitlements"; sourceTree = "<group>"; }};\n'
pbx += f'\t\t{product_id} /* TeamoA.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "TeamoA.app"; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
pbx += "/* End PBXFileReference section */\n\n"

# PBXFrameworksBuildPhase
pbx += "/* Begin PBXFrameworksBuildPhase section */\n"
pbx += f"""\t\t{frameworks_phase_id} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{uid("buildfile_swiftterm")} /* SwiftTerm in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
pbx += "/* End PBXFrameworksBuildPhase section */\n\n"

# PBXGroup section
pbx += "/* Begin PBXGroup section */\n"

# Main group
pbx += f"""\t\t{main_group_id} = {{
			isa = PBXGroup;
			children = (
				{sources_group_id} /* TeamoA */,
				{products_group_id} /* Products */,
			);
			sourceTree = "<group>";
		}};
"""

# Products group
pbx += f"""\t\t{products_group_id} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_id} /* TeamoA.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
"""

# Source group (TeamoA/)
model_files = [f for f in sources if f.startswith("Models/")]
service_files = [f for f in sources if f.startswith("Services/")]
dashboard_files = [f for f in sources if f.startswith("Views/Dashboard/")]
terminal_files = [f for f in sources if f.startswith("Views/Terminal/")]
session_files = [f for f in sources if f.startswith("Views/Session/")]
shared_files = [f for f in sources if f.startswith("Views/Shared/")]
root_files = [f for f in sources if "/" not in f or f.startswith("Views/Sidebar")]

pbx += f"""\t\t{sources_group_id} /* TeamoA */ = {{
			isa = PBXGroup;
			children = (
				{file_refs["TeamoAApp.swift"]} /* TeamoAApp.swift */,
				{file_refs["ContentView.swift"]} /* ContentView.swift */,
				{models_group} /* Models */,
				{services_group} /* Services */,
				{views_group} /* Views */,
				{resources_group} /* Resources */,
				{info_plist_ref} /* Info.plist */,
				{entitlements_ref} /* TeamoA.entitlements */,
			);
			path = TeamoA;
			sourceTree = "<group>";
		}};
"""

# Models group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in model_files])
pbx += f"""\t\t{models_group} /* Models */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Models;
			sourceTree = "<group>";
		}};
"""

# Services group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in service_files])
pbx += f"""\t\t{services_group} /* Services */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Services;
			sourceTree = "<group>";
		}};
"""

# Views group
pbx += f"""\t\t{views_group} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{file_refs["Views/SidebarView.swift"]} /* SidebarView.swift */,
				{dashboard_group} /* Dashboard */,
				{terminal_group} /* Terminal */,
				{session_group} /* Session */,
				{shared_group} /* Shared */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
"""

# Dashboard group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in dashboard_files])
pbx += f"""\t\t{dashboard_group} /* Dashboard */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Dashboard;
			sourceTree = "<group>";
		}};
"""

# Terminal group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in terminal_files])
pbx += f"""\t\t{terminal_group} /* Terminal */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Terminal;
			sourceTree = "<group>";
		}};
"""

# Session group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in session_files])
pbx += f"""\t\t{session_group} /* Session */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Session;
			sourceTree = "<group>";
		}};
"""

# Shared group
children = ", ".join([f"\n\t\t\t\t{file_refs[f]} /* {os.path.basename(f)} */" for f in shared_files])
pbx += f"""\t\t{shared_group} /* Shared */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Shared;
			sourceTree = "<group>";
		}};
"""

# Resources group
children = ", ".join([f"\n\t\t\t\t{res_refs[f]} /* {os.path.basename(f)} */" for f in resources])
pbx += f"""\t\t{resources_group} /* Resources */ = {{
			isa = PBXGroup;
			children = ({children}
			);
			path = Resources;
			sourceTree = "<group>";
		}};
"""

pbx += "/* End PBXGroup section */\n\n"

# PBXNativeTarget
pbx += "/* Begin PBXNativeTarget section */\n"
pbx += f"""\t\t{target_id} /* TeamoA */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {build_config_list_target} /* Build configuration list for PBXNativeTarget "TeamoA" */;
			buildPhases = (
				{sources_phase_id} /* Sources */,
				{frameworks_phase_id} /* Frameworks */,
				{resources_phase_id} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TeamoA;
			packageProductDependencies = (
				{package_product_dep_id} /* SwiftTerm */,
			);
			productName = TeamoA;
			productReference = {product_id} /* TeamoA.app */;
			productType = "com.apple.product-type.application";
		}};
"""
pbx += "/* End PBXNativeTarget section */\n\n"

# PBXProject
pbx += "/* Begin PBXProject section */\n"
pbx += f"""\t\t{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1430;
				LastUpgradeCheck = 1430;
			}};
			buildConfigurationList = {build_config_list_project} /* Build configuration list for PBXProject "TeamoA" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_id};
			packageReferences = (
				{package_ref_id} /* XCRemoteSwiftPackageReference "SwiftTerm" */,
			);
			productRefGroup = {products_group_id} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* TeamoA */,
			);
		}};
"""
pbx += "/* End PBXProject section */\n\n"

# PBXResourcesBuildPhase
pbx += "/* Begin PBXResourcesBuildPhase section */\n"
res_files = ", ".join([f"\n\t\t\t\t{res_build[r]} /* {os.path.basename(r)} in Resources */" for r in resources])
pbx += f"""\t\t{resources_phase_id} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = ({res_files}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
pbx += "/* End PBXResourcesBuildPhase section */\n\n"

# PBXSourcesBuildPhase
pbx += "/* Begin PBXSourcesBuildPhase section */\n"
src_files = ", ".join([f"\n\t\t\t\t{build_files[s]} /* {os.path.basename(s)} in Sources */" for s in sources])
pbx += f"""\t\t{sources_phase_id} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = ({src_files}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
"""
pbx += "/* End PBXSourcesBuildPhase section */\n\n"

# XCBuildConfiguration
pbx += "/* Begin XCBuildConfiguration section */\n"

# Project-level Debug
pbx += f"""\t\t{debug_config_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
"""

# Project-level Release
pbx += f"""\t\t{release_config_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			}};
			name = Release;
		}};
"""

# Target-level Debug
pbx += f"""\t\t{debug_config_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = TeamoA/TeamoA.entitlements;
				"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";
				CODE_SIGN_STYLE = Manual;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = TeamoA/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright 2026 Teamo Lab";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.teamolab.teamoa;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
"""

# Target-level Release
pbx += f"""\t\t{release_config_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = TeamoA/TeamoA.entitlements;
				"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";
				CODE_SIGN_STYLE = Manual;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = TeamoA/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright 2026 Teamo Lab";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.teamolab.teamoa;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
"""
pbx += "/* End XCBuildConfiguration section */\n\n"

# XCConfigurationList
pbx += "/* Begin XCConfigurationList section */\n"
pbx += f"""\t\t{build_config_list_project} /* Build configuration list for PBXProject "TeamoA" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_config_project} /* Debug */,
				{release_config_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{build_config_list_target} /* Build configuration list for PBXNativeTarget "TeamoA" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_config_target} /* Debug */,
				{release_config_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
"""
pbx += "/* End XCConfigurationList section */\n\n"

# XCRemoteSwiftPackageReference
pbx += "/* Begin XCRemoteSwiftPackageReference section */\n"
pbx += f"""\t\t{package_ref_id} /* XCRemoteSwiftPackageReference "SwiftTerm" */ = {{
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/migueldeicaza/SwiftTerm.git";
			requirement = {{
				kind = upToNextMajorVersion;
				minimumVersion = 1.0.0;
			}};
		}};
"""
pbx += "/* End XCRemoteSwiftPackageReference section */\n\n"

# XCSwiftPackageProductDependency
pbx += "/* Begin XCSwiftPackageProductDependency section */\n"
pbx += f"""\t\t{package_product_dep_id} /* SwiftTerm */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {package_ref_id} /* XCRemoteSwiftPackageReference "SwiftTerm" */;
			productName = SwiftTerm;
		}};
"""
pbx += "/* End XCSwiftPackageProductDependency section */\n\n"

# Close
pbx += f"""	}};
	rootObject = {project_id} /* Project object */;
}}
"""

# Write the file
proj_dir = os.path.expanduser("~/teamo-a/TeamoA/TeamoA.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)
with open(os.path.join(proj_dir, "project.pbxproj"), "w") as f:
    f.write(pbx)

print(f"Generated {proj_dir}/project.pbxproj")
print(f"Source files: {len(sources)}")
print(f"Resource files: {len(resources)}")
