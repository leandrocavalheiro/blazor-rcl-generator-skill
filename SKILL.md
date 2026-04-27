---
name: blazor-rcl-generator
description: Generates a complete Razor Class Library (RCL) for Blazor with professional structure, SDK validation, optional .slnx solution support, interactive demo project, and base CSS theming. Use this skill when the user requests "create blazor lib", "new RCL", "reusable blazor components", "generate component library", "blazor razor class library", or any variation of scaffolding a Blazor component library project.
---

# Blazor RCL Generator

This skill scaffolds a production-ready Razor Class Library for Blazor, including solution setup, optional demo project, and a base theming file. The result is a well-structured starting point for building reusable Blazor UI components.

## Step 1: Collect parameters

Before running any commands, ask the user for the following four values and wait for their response:

- **DOTNET_VERSION** — the target .NET version (e.g., `8.0`, `9.0`, `10.0`)
- **PROJECT_NAME** — a PascalCase name with no spaces or special characters (e.g., `MyComponentLib`)
- **USE_SLNX** — whether to use the newer `.slnx` solution format (`yes` or `no`)
- **CREATE_DEMO** — whether to scaffold a Blazor demo app that references the library (`yes` or `no`)

Only proceed once all four values have been provided.

## Step 2: Validate the .NET SDK

Run `dotnet --list-sdks` and check that the requested DOTNET_VERSION appears in the output. If it does not, inform the user which versions are installed and link them to https://dotnet.microsoft.com/download so they can install the correct one. Do not continue until a valid SDK version is confirmed.

## Step 3: Scaffold the project

With valid inputs in hand, run the scaffold script:

```bash
bash scripts/scaffold.sh "{PROJECT_NAME}" "{DOTNET_VERSION}" "{USE_SLNX}" "{CREATE_DEMO}"
```

The script handles all directory creation, project initialization, solution wiring, and base file generation. Review `scripts/scaffold.sh` to understand each step if you need to troubleshoot or adapt behavior.

## Step 4: Confirm and summarize

After the script completes successfully, tell the user what was created. Include the directory layout, how to run the demo (if created), and the next suggested steps — such as adding their first component to `{PROJECT_NAME}.Components/Components/` and importing the CSS theme in the demo's `App.razor`.

If the script fails at any step, report the exact error and suggest a fix before offering to retry.

## Notes on the generated structure

The RCL is created with `dotnet new razorclasslib`, which includes a default `ExampleJsInterop.cs` and `Component1.razor` that the user will likely delete or replace. The base CSS file at `wwwroot/themes/default.css` uses CSS custom properties so consumers can override the design tokens without modifying the library source. The demo project uses Blazor Server interactivity for simplicity, but this can be changed to WebAssembly or Auto after generation.
