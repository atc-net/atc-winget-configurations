#!/usr/bin/env python3
"""
Simple DSC v2 to v3 converter
Converts basic configurations by pattern matching
"""

import os
import re
import sys

def convert_dsc_file(input_path, output_path):
    """Convert a single DSC v2 file to DSC v3 format"""
    
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = f.readlines()
    
    # Reset file pointer for line-by-line processing
    with open(input_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    output_lines = []
    
    # Add new schema header
    output_lines.append("# yaml-language-server: $schema=https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/bundled/config/document.vscode.json\n")
    output_lines.append("$schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json\n")
    output_lines.append("\n")
    
    # Copy header comments, updating winget references
    in_header = True
    for line in lines:
        if line.strip().startswith('#') and in_header:
            if 'winget configure' in line:
                line = line.replace('winget configure', 'dsc config')
                line = line.replace('--accept-configuration-agreements', '')
            output_lines.append(line)
        elif line.strip() == '' and in_header:
            output_lines.append(line)
        elif line.strip().startswith('properties:') or line.strip().startswith('$schema:'):
            in_header = False
            break
        else:
            in_header = False
            break
    
    # Add metadata
    output_lines.append("\nmetadata:\n")
    output_lines.append("  Microsoft.DSC:\n")
    output_lines.append("    securityContext: elevated\n")
    output_lines.append("\n")
    
    # Start resources section
    output_lines.append("resources:\n")
    
    # Add Windows assertion
    output_lines.append("  - name: assert-windows\n")
    output_lines.append("    type: Microsoft.DSC/Assertion\n")
    output_lines.append("    properties:\n")
    output_lines.append("      $schema: https://aka.ms/dsc/schemas/v3/bundled/config/document.json\n")
    output_lines.append("      resources:\n")
    output_lines.append("        - name: os\n")
    output_lines.append("          type: Microsoft/OSInfo\n")
    output_lines.append("          properties:\n")
    output_lines.append("            family: Windows\n")
    output_lines.append("\n")
    
    # Parse resources from original content
    resources = []
    current_resource = None
    indent_level = 0
    in_resources = False
    in_settings = False
    settings_indent = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        if 'resources:' in line:
            in_resources = True
            continue
            
        if not in_resources:
            continue
            
        # Detect resource start
        if stripped.startswith('- resource:'):
            if current_resource:
                resources.append(current_resource)
            current_resource = {
                'resource': stripped.split(':', 1)[1].strip(),
                'id': '',
                'description': '',
                'settings': {},
                'dependsOn': []
            }
            continue
            
        if current_resource is None:
            continue
            
        # Parse resource properties
        if stripped.startswith('id:'):
            current_resource['id'] = stripped.split(':', 1)[1].strip()
        elif 'description:' in stripped and 'directives:' not in stripped:
            current_resource['description'] = stripped.split(':', 1)[1].strip()
        elif stripped.startswith('settings:'):
            in_settings = True
            settings_indent = len(line) - len(line.lstrip())
            continue
        elif stripped.startswith('dependsOn:'):
            in_settings = False
            # Parse dependencies
            j = i + 1
            while j < len(lines) and (lines[j].startswith('        -') or lines[j].strip() == ''):
                dep_line = lines[j].strip()
                if dep_line.startswith('-'):
                    dep = dep_line[1:].strip()
                    current_resource['dependsOn'].append(dep)
                j += 1
            continue
        elif in_settings and line.startswith(' ' * (settings_indent + 2)):
            # Parse settings
            if ':' in stripped:
                key, value = stripped.split(':', 1)
                current_resource['settings'][key.strip()] = value.strip()
    
    # Add the last resource
    if current_resource:
        resources.append(current_resource)
    
    # Group resources by type
    winget_resources = []
    script_resources = []
    other_resources = []
    
    for res in resources:
        if 'WinGetPackage' in res['resource']:
            winget_resources.append(res)
        elif 'PSDscResources/Script' in res['resource']:
            script_resources.append(res)
        else:
            other_resources.append(res)
    
    # Add PowerShell resource group for WinGet packages and other PowerShell resources
    if winget_resources or other_resources:
        config_name = os.path.basename(input_path).replace('-configuration.dsc.yaml', '').replace('.dsc.yaml', '')
        group_name = f"{config_name.title()} Development Tools"
        
        output_lines.append(f"  - name: {group_name}\n")
        output_lines.append("    type: Microsoft.DSC/PowerShell\n")
        output_lines.append("    properties:\n")
        output_lines.append("      resources:\n")
        
        # Add WinGet packages
        for res in winget_resources + other_resources:
            output_lines.append(f"        - name: {res['id']}\n")
            output_lines.append(f"          type: {res['resource']}\n")
            output_lines.append("          properties:\n")
            
            # Convert settings
            for key, value in res['settings'].items():
                if key == 'id' and 'WinGetPackage' in res['resource']:
                    output_lines.append(f"            Id: {value}\n")
                else:
                    output_lines.append(f"            {key}: {value}\n")
            
            # Add defaults for WinGet packages
            if 'WinGetPackage' in res['resource']:
                if 'UseLatest' not in res['settings']:
                    output_lines.append("            UseLatest: true\n")
                if 'Ensure' not in res['settings']:
                    output_lines.append("            Ensure: Present\n")
            
            # Add dependencies
            if res['dependsOn']:
                output_lines.append("          dependsOn:\n")
                for dep in res['dependsOn']:
                    if 'WinGetPackage' in res['resource']:
                        output_lines.append(f"            - \"[resourceId('Microsoft.WinGet.DSC/WinGetPackage','{dep}')]\"\n")
            
            output_lines.append("\n")
        
        output_lines.append("    dependsOn:\n")
        output_lines.append("      - \"[resourceId('Microsoft.DSC/Assertion','assert-windows')]\"\n")
        output_lines.append("\n")
    
    # Add script resources
    for res in script_resources:
        output_lines.append(f"  - name: {res['id']}\n")
        output_lines.append("    type: Microsoft.Windows/WindowsPowerShell\n")
        output_lines.append("    properties:\n")
        output_lines.append("      resources:\n")
        output_lines.append(f"        - name: {res['description'] or 'PowerShell Script'}\n")
        output_lines.append("          type: PSDesiredStateConfiguration/Script\n")
        output_lines.append("          properties:\n")
        
        # Add script properties (simplified - would need more complex parsing for real scripts)
        output_lines.append("            GetScript: |\n")
        output_lines.append("              return @{ Result = 'Not implemented' }\n")
        output_lines.append("            TestScript: |\n")
        output_lines.append("              return $false\n")
        output_lines.append("            SetScript: |\n")
        output_lines.append("              # Implementation needed\n")
        
        output_lines.append("    dependsOn:\n")
        output_lines.append("      - \"[resourceId('Microsoft.DSC/Assertion','assert-windows')]\"\n")
        
        # Add resource dependencies
        for dep in res['dependsOn']:
            output_lines.append(f"      - \"[resourceId('Microsoft.WinGet.DSC/WinGetPackage','{dep}')]\"\n")
        
        output_lines.append("\n")
    
    # Write output file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    
    print(f"Converted {input_path} -> {output_path}")

def main():
    source_dir = "configurations-dscv2-backup"
    dest_dir = "configurations"
    
    if len(sys.argv) > 1:
        # Convert specific file
        filename = sys.argv[1]
        input_path = os.path.join(source_dir, filename)
        output_path = os.path.join(dest_dir, filename)
        convert_dsc_file(input_path, output_path)
    else:
        # Convert all files
        for filename in os.listdir(source_dir):
            if filename.endswith('.dsc.yaml'):
                # Skip already converted files
                if filename in ['os-configuration.dsc.yaml', 'ai-configuration.dsc.yaml', 'dotnet-configuration.dsc.yaml']:
                    continue
                    
                input_path = os.path.join(source_dir, filename)
                output_path = os.path.join(dest_dir, filename)
                
                try:
                    convert_dsc_file(input_path, output_path)
                except Exception as e:
                    print(f"Error converting {filename}: {e}")

if __name__ == "__main__":
    main()