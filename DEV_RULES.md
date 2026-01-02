## QML and JSON

1. **Formatting:** Keep layout compact. No vertical whitespace inside objects or property blocks.
    
2. **Separators:** Use 'Sandwich' headers (`// ------`) with strict spacing (1 line before, 0 lines after).
    
3. **Declarative Nature:** Prefer declarative bindings (`property: value`) over imperative assignments (`id.property = value`).
    
4. **Safety:**
    
    - **QML:** Use strong typing (`int`, `bool` instead of `var` or `property alias`) where possible.
        
    - **JSON:** Ensure valid trailing commas if the parser supports them (JSONC), or strictly avoid them (Standard JSON).
        
5. **Context:** Hardcoded for AMD Ryzen 7000/Radeon 7000. No hardcoded secrets.
    
6. **Syntax:**
    
    - **QML:** Use `console.log` for output.
        
    - **JSON:** Keys must be double-quoted.
        
7. **Documentation:** Precede sections with `// Purpose` or `// Rationale`. No meta-comments inside object blocks.