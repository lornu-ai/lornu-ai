# Coding Rules & Conventions

## General
- **Clarity over Cleverness**: Write code that is easy for an LLM to read. Verbose variable names are preferred.
- **Strong Typing**: Use TypeScript or Python type hints everywhere.
- **Documentation**: All public functions must have docstrings.

## Patterns
- **Functional**: Prefer pure functions where possible.
- **Composition**: Prefer composition over inheritance.

## Testing
- Write tests for all core logic.

## Tooling
- **JavaScript/TypeScript**: Always use **Bun** for dependency management and package execution.
- **Python**: Always use **uv** for dependency management and virtual environments.
