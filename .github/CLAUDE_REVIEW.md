# Claude Code Review System

This repository includes an on-demand Claude code review system that can be triggered for pull requests.

## How to Use

### 🚀 Quick Commands (Recommended)
Comment on any pull request with one of these commands:
- `/claude-review` or `/review-comprehensive` - Full comprehensive review
- `/review-security` - Security-focused review
- `/review-performance` - Performance analysis  
- `/review-testing` - Test coverage and quality
- `/review-godot` - Godot 4.3 best practices

### 📋 Manual Trigger
1. Go to the [Actions tab](../../actions/workflows/claude-code-review.yml)
2. Click "Run workflow"
3. Enter the PR number
4. Select review focus
5. Click "Run workflow"

## Review Focus Options

### Comprehensive
- Code quality and best practices
- Potential bugs or issues
- Performance considerations
- Security concerns
- Test coverage
- Godot 4.3 compatibility and patterns

### Security
- Input validation and sanitization
- Authentication and authorization
- Data exposure risks
- Secure coding practices
- Potential vulnerabilities

### Performance
- Algorithm efficiency
- Memory usage and leaks
- Godot-specific performance patterns
- Frame rate impact
- Resource loading optimization

### Testing
- Test coverage completeness
- Test quality and effectiveness
- Edge cases and boundary conditions
- GUT framework usage
- Test maintainability

### Godot-Specific
- Godot 4.3 API usage and best practices
- Scene structure and node organization
- Signal usage and connections
- Resource management
- GDScript coding conventions

## What Happens

1. When you trigger a review, the system will:
   - React to your comment with a 🚀 emoji
   - Post a confirmation comment
   - Start the Claude review workflow
   - Post the review results as a comment on the PR

2. The review will include:
   - Focused feedback based on your selected review type
   - Constructive suggestions for improvement
   - Code quality analysis
   - Best practices recommendations

## Requirements

- The repository must have the `ANTHROPIC_API_KEY` secret configured
- The workflows must be enabled in the repository settings
- The user triggering the review must have appropriate permissions

## Files

- `.github/workflows/claude-code-review.yml` - Main review workflow
- `.github/workflows/claude-review-trigger.yml` - Comment trigger handler
- `.github/workflows/add-review-button.yml` - Adds review instructions to PRs