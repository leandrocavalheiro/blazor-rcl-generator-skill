#!/usr/bin/env bash
# scaffold.sh — Creates a Blazor Razor Class Library project structure
# Usage: bash scripts/scaffold.sh <PROJECT_NAME> <DOTNET_VERSION> <USE_SLNX> <CREATE_DEMO> <WORKSPACE_MODE>

set -e

PROJECT_NAME="$1"
DOTNET_VERSION="$2"
USE_SLNX="$3"
CREATE_DEMO="$4"
WORKSPACE_MODE="${5:-new}"

if [ "$WORKSPACE_MODE" = "current" ]; then
  echo "→ Using current directory as workspace"
else
  echo "→ Creating workspace: $PROJECT_NAME"
  mkdir "$PROJECT_NAME"
  cd "$PROJECT_NAME"
fi

echo "→ Initializing solution"
if [ "$USE_SLNX" = "yes" ]; then
  dotnet new sln -n "$PROJECT_NAME" -f slnx
else
  dotnet new sln -n "$PROJECT_NAME"
fi

echo "→ Creating Razor Class Library: $PROJECT_NAME.Components"
dotnet new razorclasslib -n "$PROJECT_NAME.Components" --framework "net$DOTNET_VERSION"

if [ "$USE_SLNX" = "yes" ]; then
  dotnet sln add "$PROJECT_NAME.Components/$PROJECT_NAME.Components.csproj"
else
  dotnet sln "$PROJECT_NAME.sln" add "$PROJECT_NAME.Components/$PROJECT_NAME.Components.csproj"
fi

if [ "$CREATE_DEMO" = "yes" ]; then
  echo "→ Creating Blazor demo project: $PROJECT_NAME.Demo"
  dotnet new blazor -n "$PROJECT_NAME.Demo" --framework "net$DOTNET_VERSION" --interactivity Server

  if [ "$USE_SLNX" = "yes" ]; then
    dotnet sln add "$PROJECT_NAME.Demo/$PROJECT_NAME.Demo.csproj"
  else
    dotnet sln "$PROJECT_NAME.sln" add "$PROJECT_NAME.Demo/$PROJECT_NAME.Demo.csproj"
  fi

  dotnet add "$PROJECT_NAME.Demo/$PROJECT_NAME.Demo.csproj" \
    reference "$PROJECT_NAME.Components/$PROJECT_NAME.Components.csproj"
fi

echo "→ Writing base CSS theme"
mkdir -p "$PROJECT_NAME.Components/wwwroot/themes"
cat > "$PROJECT_NAME.Components/wwwroot/themes/default.css" << 'CSSEOF'
:root {
  --lib-primary:        #0ea5e9;
  --lib-primary-hover:  #0284c7;
  --lib-surface:        #ffffff;
  --lib-surface-alt:    #f8fafc;
  --lib-border:         #e2e8f0;
  --lib-text:           #0f172a;
  --lib-text-muted:     #64748b;
  --lib-radius:         0.375rem;
  --lib-shadow:         0 1px 3px 0 rgb(0 0 0 / 0.1);
}
CSSEOF

echo "→ Removing boilerplate files"
rm -f "$PROJECT_NAME.Components/Component1.razor"
rm -f "$PROJECT_NAME.Components/Component1.razor.css"
rm -f "$PROJECT_NAME.Components/ExampleJsInterop.cs"

echo ""
echo "✅ Done! Project created at: $(pwd)"
