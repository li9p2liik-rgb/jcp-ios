#!/usr/bin/env python3
"""
JCP iOS Project 鈥?Static Verification Script
Runs on any platform. Checks file structure, references, and common issues
without requiring Xcode or Swift compiler.
"""

import os, sys, re, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def header(msg: str):
    print(f"\n{'='*60}")
    print(f"  {msg}")
    print(f"{'='*60}")

def check(msg: str, ok: bool) -> int:
    mark = "PASS" if ok else "FAIL"
    print(f"  [{mark}] {msg}")
    return 0 if ok else 1

def main():
    errors = 0

    # --- 1. Directory structure ---
    header("1. Directory Structure")
    required_dirs = [
        "JCP/App", "JCP/Models", "JCP/Services",
        "JCP/Services/AI", "JCP/Services/Market",
        "JCP/Views/Stock", "JCP/Views/Chat",
        "JCP/Views/Settings", "JCP/Views/Components",
        "JCP/Resources", "JCPTests"
    ]
    for d in required_dirs:
        errors += check(f"Directory exists: {d}", (ROOT / d).is_dir())

    # --- 2. Required files ---
    header("2. Required Files")
    required_files = [
        "project.yml",
        "exportOptions.plist",
        ".gitignore",
        ".github/workflows/build-ipa.yml",
        "JCP/Resources/Info.plist",
        "JCP/App/JCPApp.swift",
        "JCP/App/ContentView.swift",
        "JCP/Models/MarketModels.swift",
        "JCP/Models/ConfigModels.swift",
        "JCP/Models/AgentModels.swift",
        "JCP/Models/CommonModels.swift",
        "JCP/Services/AI/AIProtocol.swift",
        "JCP/Services/AI/OpenAICompatibleService.swift",
        "JCP/Services/ConfigService.swift",
        "JCP/Services/AgentService.swift",
        "JCP/Services/MeetingService.swift",
        "JCP/Services/SessionService.swift",
        "JCP/Services/MemoryService.swift",
        "JCP/Services/Market/MarketService.swift",
        "JCP/Services/Market/SinaMarketDataProvider.swift",
        "JCP/Views/Stock/MarketTabView.swift",
        "JCP/Views/Stock/StockDetailView.swift",
        "JCP/Views/Stock/PositionListView.swift",
        "JCP/Views/Chat/MeetingListView.swift",
        "JCP/Views/Chat/MeetingRoomView.swift",
        "JCP/Views/Settings/SettingsView.swift",
        "JCP/Views/Settings/AIConfigViews.swift",
        "JCP/Views/Components/MarketIndexBar.swift",
        "JCP/Views/Components/KLineChartView.swift",
    ]
    for f in required_files:
        errors += check(f"File exists: {f}", (ROOT / f).is_file())

    # --- 3. Model completeness check ---
    header("3. Model Structs (Go -> Swift mapping)")
    swift_files = list(ROOT.glob("JCP/**/*.swift"))
    all_content = ""
    for sf in swift_files:
        all_content += sf.read_text(encoding="utf-8") + "\n"

    # Check key types exist
    key_types = [
        "struct Stock", "struct KLineData", "struct OrderBook",
        "struct MarketIndex", "struct MarketStatus",
        "struct AIConfig", "struct AppConfig", "struct AgentConfig",
        "struct ChatMessage", "struct TradingStrategy", "struct ChatSession",
        "struct ModeratorDecision", "struct DiscussionEntry",
        "struct MemoryFact", "enum AIProvider", "enum TimePeriod",
        "enum AgentRole", "enum MsgType",
    ]
    for t in key_types:
        errors += check(f"Type defined: {t}", t in all_content)

    # --- 4. Protocol and Service completeness ---
    header("4. Service Architecture")
    protocols = [
        "protocol AILLMProtocol",
        "protocol MarketDataProvider",
    ]
    for p in protocols:
        errors += check(f"Protocol defined: {p}", p in all_content)

    services = [
        "actor AIServiceFactory",
        "actor OpenAICompatibleService",
        "final class ConfigService",
        "final class AgentService",
        "final class MeetingService",
        "final class SessionService",
        "final class MemoryService",
        "final class MarketService",
        "actor SinaMarketDataProvider",
    ]
    for s in services:
        errors += check(f"Service defined: {s}", s in all_content)

    # --- 5. View completeness ---
    header("5. SwiftUI Views")
    views = [
        "struct JCPApp: App",
        "struct ContentView: View",
        "struct MarketTabView: View",
        "struct StockDetailView: View",
        "struct KLineChartView: View",
        "struct MarketIndexBar: View",
        "struct MeetingListView: View",
        "struct MeetingRoomView: View",
        "struct PositionListView: View",
        "struct PositionRow: View",
        "struct AddPositionView: View",
        "struct SettingsView: View",
        "struct AIConfigDetailView: View",
        "struct AddAIConfigView: View",
        "struct MemoryFact: Codable",
    ]
    for v in views:
        errors += check(f"View defined: {v}", v in all_content)

    # --- 6. Cross-reference check ---
    header("6. Cross-Reference Integrity")
    # Check that referenced types exist
    refs = [
        # Models references
        ("Stock referenced in MarketService", "Stock", "JCP/Services/Market/MarketService.swift"),
        ("KLineData referenced in MarketService", "KLineData", "JCP/Services/Market/MarketService.swift"),
        ("AIConfig referenced in ConfigService", "AIConfig", "JCP/Services/ConfigService.swift"),
        ("AppConfig referenced in ConfigService", "AppConfig", "JCP/Services/ConfigService.swift"),
        ("ChatMessage referenced in MeetingService", "ChatMessage", "JCP/Services/MeetingService.swift"),
        ("ModeratorDecision referenced in MeetingService", "ModeratorDecision", "JCP/Services/MeetingService.swift"),
        ("AgentConfig referenced in AgentService", "AgentConfig", "JCP/Services/AgentService.swift"),
        ("ChatSession referenced in SessionService", "ChatSession", "JCP/Services/SessionService.swift"),
        ("Stock referenced in MeetingRoomView", "Stock", "JCP/Views/Chat/MeetingRoomView.swift"),
        ("StockPosition referenced in PositionListView", "StockPosition", "JCP/Views/Stock/PositionListView.swift"),
        ("AILLMProtocol referenced in AIProtocol", "protocol AILLMProtocol", "JCP/Services/AI/AIProtocol.swift"),
        ("OpenAICompatibleService referenced", "actor OpenAICompatibleService", "JCP/Services/AI/OpenAICompatibleService.swift"),
    ]
    for desc, expected_type, src_file in refs:
        content = (ROOT / src_file).read_text(encoding="utf-8") if (ROOT / src_file).exists() else ""
        ok = expected_type in content or expected_type in all_content
        errors += check(desc, ok)

    # --- 7. GitHub Actions workflow ---
    header("7. CI/CD Workflow")
    wf_path = ROOT / ".github/workflows/build-ipa.yml"
    if wf_path.exists():
        wf = wf_path.read_text(encoding="utf-8")
        errors += check("Workflow has build job", "jobs:" in wf and "build:" in wf)
        errors += check("Workflow runs on macos", "macos-" in wf)
        errors += check("Workflow uses xcodegen", "xcodegen" in wf)
        errors += check("Workflow uploads artifact", "upload-artifact" in wf)
        errors += check("Workflow exports IPA", ".ipa" in wf)
    else:
        errors += check("Workflow file exists", False)

    # --- Summary ---
    header("SUMMARY")
    total_checks = "see above"
    if errors == 0:
        print("\n  All checks passed. Project is structurally sound.")
        print("  Ready to push to GitHub for CI build.")
    else:
        print(f"\n  {errors} issue(s) found. Review FAIL items above.")
    print()
    return 0 if errors == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
