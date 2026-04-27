---
name: blazor-rcl-generator
display_name: "Blazor RCL Generator 1.3.0"
version: 1.3.0
description: Generates a complete Razor Class Library (RCL) for Blazor with professional structure, SDK validation, optional .slnx solution support, interactive demo project, and base CSS theming. Use this skill when the user requests "create blazor lib", "new RCL", "reusable blazor components", "generate component library", "blazor razor class library", or any variation of scaffolding a Blazor component library project.
---

# Blazor RCL Generator — v1.3.0

> **Version:** 1.3.0  
> **Display name (shown in /skills):** Blazor RCL Generator 1.3.0
> 
> **Important:** After reinstalling with `./install.sh`, you **must restart OpenCode** (close and reopen) for the new display name to appear. The skill version updates but the UI only refreshes on restart.

## Changelog

| Version | Changes |
|---------|---------|
| 1.3.0   | Auto-remove `Component1.razor`, `Component1.razor.css`, `ExampleJsInterop.cs` after scaffold; demo auto-wired with project reference, `@using` import, and CSS `<link>` |
| 1.2.0   | Added `WORKSPACE_MODE` parameter (`new` vs `current`) to support cloned-repo workflows |
| 1.1.0   | Added `.slnx` solution format support (`USE_SLNX`); added optional demo project (`CREATE_DEMO`) |
| 1.0.0   | Initial release — basic RCL scaffold with SDK validation and base CSS theming |

---

## Step 1: Collect parameters

Before running any commands, ask the user for the following five values and wait for their response. **Show the default in parentheses and ask for confirmation** — the user can press Enter to accept the default or type a new value.

- **DOTNET_VERSION** — the target .NET version (e.g., `8.0`, `9.0`, `10.0`)
  - **Default:** `10.0`
  - Ask: `"DOTNET_VERSION (default: 10.0):"`
- **PROJECT_NAME** — a PascalCase name with no spaces or special characters (e.g., `MyComponentLib`)
  - **Default:** (no default — user must provide a name)
  - Ask: `"PROJECT_NAME:"`
- **USE_SLNX** — whether to use the newer `.slnx` solution format (`yes` or `no`)
  - **Default:** `yes`
  - Ask: `"USE_SLNX - use .slnx format? (default: yes) [y/N]:"`
- **CREATE_DEMO** — whether to scaffold a Blazor demo app that references the library (`yes` or `no`)
  - **Default:** `yes`
  - Ask: `"CREATE_DEMO - scaffold demo project? (default: yes) [y/N]:"`
- **WORKSPACE_MODE** — how the scaffold should behave regarding the root directory:
  - `new` — create a new folder named `{PROJECT_NAME}` and scaffold everything inside it. Use this when starting from scratch on the local machine.
  - `current` — scaffold directly into the current working directory, without creating an extra root folder. Use this when the user already created and cloned a repository, so the folder for the project already exists.
  - **Default:** `new`
  - Ask: `"WORKSPACE_MODE (default: new) [new/current]:"`

Only proceed once all five values have been provided (all five confirmed, the last two can accept default by pressing Enter).

> **Tip for the user:** If you cloned a repo first (e.g., from GitHub), choose `current` so the solution and projects land directly at the repo root — no double-nested folder.

## Step 2: Validate the .NET SDK

Run `dotnet --list-sdks` and check that the requested DOTNET_VERSION appears in the output. If it does not, inform the user which versions are installed and link them to https://dotnet.microsoft.com/download so they can install the correct one. Do not continue until a valid SDK version is confirmed.

## Step 3: Scaffold the project

With valid inputs in hand, run the scaffold script:

```bash
bash scripts/scaffold.sh "{PROJECT_NAME}" "{DOTNET_VERSION}" "{USE_SLNX}" "{CREATE_DEMO}" "{WORKSPACE_MODE}"
```

The script handles all directory creation (or skips it for `current` mode), project initialization, solution wiring, boilerplate cleanup, project references, and base file generation. Review `scripts/scaffold.sh` to understand each step if you need to troubleshoot or adapt behavior.

### What each WORKSPACE_MODE does

| Mode      | Behavior |
|-----------|----------|
| `new`     | Creates `./{PROJECT_NAME}/`, then scaffolds the solution and all projects inside it. Equivalent to the previous default. |
| `current` | Uses the current directory (`.`) as the solution root. No extra folder is created. Ideal for cloned repositories. |

## Step 4: Post-scaffold automatic actions

The script **always** performs these steps regardless of `CREATE_DEMO`, because they clean up the RCL itself:

### 4a — Remove boilerplate from the component library

After `dotnet new razorclasslib` runs, immediately delete the generated placeholders:

```
{PROJECT_NAME}.Components/Component1.razor
{PROJECT_NAME}.Components/Component1.razor.css
{PROJECT_NAME}.Components/ExampleJsInterop.cs
```

These files are never useful to consumers and clutter the library from the start.

### 4b — Wire the demo project to the library (only when CREATE_DEMO=yes)

Perform these three wiring steps in order:

**1. Add project reference**

```bash
dotnet add "{PROJECT_NAME}.Demo/{PROJECT_NAME}.Demo.csproj" \
  reference "{PROJECT_NAME}.Components/{PROJECT_NAME}.Components.csproj"
```

**2. Register the component namespace in `_Imports.razor`**

Append to `{PROJECT_NAME}.Demo/_Imports.razor`:

```razor
@using {PROJECT_NAME}.Components
```

**3. Import the library CSS theme**

The correct injection point depends on the demo's render mode:

| Demo type          | File to edit                                 | Where to add the `<link>`                     |
|--------------------|----------------------------------------------|-----------------------------------------------|
| Blazor Server      | `{PROJECT_NAME}.Demo/Components/App.razor`   | Inside `<head>`, after existing `<link>` tags |
| Blazor WebAssembly | `{PROJECT_NAME}.Demo/wwwroot/index.html`     | Inside `<head>`, after existing `<link>` tags |

Add this line in the appropriate file:

```html
<link rel="stylesheet" href="_content/{PROJECT_NAME}.Components/themes/default.css" />
```

> The `_content/{LibraryName}/` path is the standard ASP.NET Core static asset convention for RCL packages. The filename must match the one generated under `wwwroot/themes/default.css`.

## Step 5: Confirm and summarize

After the script completes successfully, tell the user what was created. Include:

- The directory layout relative to the solution root
- Confirmation that `Component1.razor`, `Component1.razor.css`, and `ExampleJsInterop.cs` were removed
- If demo was created: confirmation that the project reference, `@using` import, and CSS `<link>` are already wired up
- How to run the demo (if created): `dotnet run --project {PROJECT_NAME}.Demo`
- Next suggested steps:
  - Create the first real component under `{PROJECT_NAME}.Components/Components/`
  - Use it directly in the demo's pages — no extra setup needed, namespaces and CSS are already imported

If the script fails at any step, report the exact error and suggest a fix before offering to retry.

## Notes on the generated structure

The base CSS file at `wwwroot/themes/default.css` uses CSS custom properties so consumers can override the design tokens without modifying the library source. The demo project uses Blazor Server interactivity for simplicity, but this can be changed to WebAssembly or Auto after generation — just update the CSS `<link>` injection point accordingly (see table in Step 4b).

When `WORKSPACE_MODE=current`, the script must **not** create a subdirectory for the solution — it runs `dotnet new sln` (or `dotnet new slnx`) directly in the current directory. All project folders (`{PROJECT_NAME}.Components`, `{PROJECT_NAME}.Demo`) are still created as subdirectories of wherever the script runs.

---

## Versioning guide (for skill maintainers)

When updating this skill, bump the version following **semver**:

- **Patch (x.x.X)** — typo fixes, clarifications, no behavioral change
- **Minor (x.X.0)** — new optional parameter, new step, backward-compatible addition
- **Major (X.0.0)** — breaking change to parameters, scaffold structure, or script interface

Update **all three** locations together:
1. `version:` field in the YAML frontmatter
2. `display_name:` field in the YAML frontmatter → `"Blazor RCL Generator X.X.X"`
3. The `# Blazor RCL Generator — vX.X.X` heading at the top of the body
4. Add a new row at the top of the **Changelog** table