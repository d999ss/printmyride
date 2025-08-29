#!/usr/bin/env python3
import os, json, re, subprocess, tempfile, pathlib, sys, textwrap, shlex

# ======= CONFIG =======
PROJECT = "PrintMyRide.xcodeproj"
SCHEME    = "PrintMyRide"
DEST      = "platform=iOS Simulator,name=iPhone 16 Pro"
RESULT_BUNDLE = "build/Build.xcresult"
ALLOWED_EDIT_DIRS = [
    "PrintMyRide/Features/Editor",
    "PrintMyRide/Features/Render",
    "PrintMyRide/GPX",
    "PrintMyRide/Utilities",
    "PrintMyRideTests",
    "PrintMyRideUITests",
]
# Canonical, hands-off files (your guards)
BLOCKED_PATHS = [
    "PrintMyRide/Models/PosterDesign.swift",
    "PrintMyRide/Features/Render/GridOverlay.swift",
    "PrintMyRide/PreBuildCheck.sh",
]
# Provider: "openai" or "anthropic"
PROVIDER = os.getenv("PROVIDER", "openai")  # change if you prefer
MODEL    = os.getenv("MODEL", "gpt-4")      # set your deployed model name

# ======= SHELL HELPERS =======
def run(cmd, check=True, capture=True, env=None):
    print("→", " ".join(cmd))
    res = subprocess.run(cmd, capture_output=capture, text=True, env=env)
    if check and res.returncode != 0:
        print(res.stdout)
        print(res.stderr)
        raise RuntimeError(f"Command failed: {' '.join(cmd)}")
    return (res.stdout or "") + (res.stderr or "")

def build():
    pathlib.Path("build").mkdir(exist_ok=True)
    cmd = [
        "xcodebuild",
        "-project", PROJECT,
        "-scheme", SCHEME,
        "-destination", DEST,
        "-resultBundlePath", RESULT_BUNDLE,
        "clean", "build",
        "-quiet",
    ]
    return run(cmd, check=False)

def test():
    cmd = [
        "xcodebuild",
        "-project", PROJECT,
        "-scheme", SCHEME,
        "-destination", DEST,
        "-resultBundlePath", RESULT_BUNDLE,
        "test",
        "-quiet",
    ]
    return run(cmd, check=False)

# ======= DIAGNOSTICS FROM .XCRESULT =======
def xcresult_issues(path=RESULT_BUNDLE):
    try:
        raw = run(["xcrun","xcresulttool","get","--format","json","--path", path])
        j = json.loads(raw)
    except Exception:
        return []

    issues = []
    # errorSummaries and warningSummaries both live under 'issues'
    for bag in ("errorSummaries","warningSummaries","testFailureSummaries"):
        arr = (j.get("issues", {}) or {}).get(bag, {}).get("_values", []) or []
        for item in arr:
            msg = item.get("message", {}).get("_value") or ""
            loc = item.get("documentLocationInCreatingWorkspace", {}).get("_value") or ""
            # Location string looks like: "file:///.../Foo.swift#CharacterRangeLen=...,StartingLineNumber=12,EndingLineNumber=12"
            mfile = re.search(r"file://([^#]+)", loc)
            mline = re.search(r"StartingLineNumber=(\d+)", loc)
            fpath = mfile.group(1) if mfile else None
            line  = int(mline.group(1)) if mline else None
            if fpath and os.path.exists(fpath):
                issues.append({"path": fpath, "line": line, "message": msg})
    return issues

def read_snippet(path, line, context=20):
    try:
        lines = pathlib.Path(path).read_text().splitlines()
        i0 = max(0, (line or 1) - 1 - context)
        i1 = min(len(lines), (line or 1) - 1 + context)
        snippet = "\n".join(f"{idx+1:5d}  {lines[idx]}" for idx in range(i0, i1))
        return snippet
    except Exception:
        return ""

# ======= LLM CALL (PATCH CONTRACT) =======
def ask_llm(errors, files):
    """
    errors: list of {path, line, message}
    files: list of {path, snippet}
    Returns: unified diff patch text (no prose)
    """
    instructions = f"""
You are a surgical Swift/Xcode fixer. Produce a single unified diff (git patch) that fixes the build.
HARD RULES:
- Edit only within these directories: {ALLOWED_EDIT_DIRS}.
- Never modify these files: {BLOCKED_PATHS}.
- Do not invent new types (e.g., Size, RGBAColor); use CGSize and PosterDesign.ColorData.
- PosterPreview(design: PosterDesign, route: GPXRoute?) expects a VALUE design, not Binding.
- Use binding projection ($design.foo) only inside SwiftUI controls; elsewhere use value reads.
- If a parameter like `onExport` is required, make it optional with a default and gate calls.
- If dynamic-member or type-check timeouts occur, break large SwiftUI bodies into smaller views.
- Output ONLY a valid unified diff starting with lines like: diff --git a/... b/...

Context errors:
{json.dumps(errors, indent=2)}

Snippets (read-only context):
{json.dumps(files, indent=2)}
"""
    if PROVIDER.lower().startswith("openai"):
        from openai import OpenAI
        client = OpenAI()
        r = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role":"system","content":"Return ONLY a unified diff. No explanations."},
                {"role":"user","content":instructions},
            ],
            temperature=0
        )
        return r.choices[0].message.content.strip()
    else:
        import anthropic
        client = anthropic.Anthropic()
        r = client.messages.create(
            model=os.getenv("ANTHROPIC_MODEL","claude-3-7-sonnet"),
            max_tokens=4000,
            temperature=0,
            system="Return ONLY a unified diff. No explanations.",
            messages=[{"role":"user","content":instructions}],
        )
        # anthropic returns content list
        txt = "".join(block.text for block in r.content if block.type=="text")
        return txt.strip()

# ======= PATCH APPLICATION + SAFETY =======
def patch_touches_blocked(patch_text):
    for bp in BLOCKED_PATHS:
        if f" a/{bp}" in patch_text or f" b/{bp}" in patch_text:
            return True
    # also reject edits outside allowlist
    for line in patch_text.splitlines():
        if line.startswith(("+++ b/","--- a/")):
            p = line.split("\t")[0].split(" ",2)[-1]
            p = p.replace("a/","").replace("b/","")
            if not any(p.startswith(d + "/") or p == d for d in ALLOWED_EDIT_DIRS):
                return True
    return False

def apply_patch(patch_text):
    if not patch_text or "diff --git" not in patch_text:
        return False, "No diff found"
    if patch_touches_blocked(patch_text):
        return False, "Patch attempted to modify blocked or disallowed files"
    with tempfile.NamedTemporaryFile("w", delete=False, suffix=".diff") as f:
        f.write(patch_text)
        patch_path = f.name
    try:
        run(["git","apply","--whitespace=fix",patch_path])
        run(["git","add","-A"])
        run(["git","commit","-m","auto: apply LLM fix"])
        return True, None
    except Exception as e:
        return False, str(e)

# ======= MAIN LOOP =======
def main():
    # new branch safety
    try:
        run(["git","rev-parse","--git-dir"])
        run(["git","checkout","-B","llm-fix-loop"])
    except Exception:
        pass

    iteration = 0
    while True:
        iteration += 1
        print(f"\n==== Iteration {iteration} ====\n")
        build_log = build()
        issues = xcresult_issues()
        if not issues:
            print("✅ Build succeeded.")
            test_log = test()
            if "** TEST FAILED **" in test_log:
                print("⚠️ tests failed, continuing loop"); 
            else:
                print("✅ Tests passed. Done.")
                break

        # collect distinct files for context
        file_context = []
        seen = set()
        for it in issues:
            p = it["path"]; ln = it["line"]
            if p not in seen:
                file_context.append({"path": p, "snippet": read_snippet(p, ln)})
                seen.add(p)

        patch = ask_llm(issues, file_context)
        ok, err = apply_patch(patch)
        if not ok:
            print("Patch rejected:", err)
            print("First 200 chars of patch for debug:\n", patch[:200])
            break

if __name__ == "__main__":
    main()