# Contributing

## Git Commit Message Standards

Following [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New feature for the user (correlates with MINOR in SemVer)
- **fix**: Bug fix (correlates with PATCH in SemVer)
- **docs**: Documentation changes only
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without feature changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Breaking Changes

- Add `!` after type/scope: `feat!:` or `feat(api)!:`
- Or add footer: `BREAKING CHANGE: description`

### Scope Examples (Optional)

- `feat(auth):` - Authentication module
- `fix(receipt):` - Receipt module
- `docs(api):` - API documentation
- `feat(backend):` - Backend changes
- `feat(mobile):` - Flutter/mobile changes
- `feat(database):` - Database changes

### Examples

```bash
# Feature
feat(auth): add Firebase JWT verification

# Bug fix
fix(receipt): prevent duplicate OCR processing

# Breaking change
feat(api)!: change receipt status enum values

BREAKING CHANGE: status field now uses UPPERCASE values

# Documentation
docs: update README with Firebase setup instructions

# Refactoring
refactor(service): extract warranty calculation to utility

# Performance
perf(database): add index on warranty_expiry_date

# Multiple paragraphs
fix(upload): prevent racing of S3 upload requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Refs: #123
```

### Best Practices

1. **Use lowercase** for type and scope
2. **No period** at the end of the description
3. **Use imperative mood**: "add" not "added" or "adds"
4. **Keep first line under 72 characters**
5. **Reference issues** in footer: `Refs: #123`
6. **One commit per logical change**
7. **Separate subject from body** with a blank line

### Revert Example

```bash
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```
