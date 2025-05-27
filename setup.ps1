# Oxford College Chatbot - Automated Setup Script
# Run this script as Administrator for best results

param(
    [switch]$SkipPython,
    [switch]$SkipNode,
    [switch]$CreateReactApp,
    [switch]$Help
)

if ($Help) {
    Write-Host "Oxford College Chatbot Setup Script" -ForegroundColor Cyan
    Write-Host "Usage: .\setup.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -SkipPython      Skip Python installation check"
    Write-Host "  -SkipNode        Skip Node.js installation check"
    Write-Host "  -CreateReactApp  Create a separate React app (optional)"
    Write-Host "  -Help            Show this help message"
    Write-Host ""
    Write-Host "Example: .\setup.ps1 -CreateReactApp" -ForegroundColor Green
    exit 0
}

# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "Oxford College Chatbot - Automated Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to refresh environment variables
function Update-EnvironmentPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machinePath + ";" + $userPath
}

# Function to install Chocolatey
function Install-Chocolatey {
    Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "SUCCESS: Chocolatey installed successfully!" -ForegroundColor Green
        Update-EnvironmentPath
        return $true
    }
    catch {
        Write-Host "ERROR: Failed to install Chocolatey: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please install Chocolatey manually from https://chocolatey.org/install" -ForegroundColor Yellow
        return $false
    }
}

# Check and install Python
if (-not $SkipPython) {
    Write-Host "Checking Python installation..." -ForegroundColor Yellow
    
    if (Test-Command python) {
        $pythonVersion = python --version 2>&1
        Write-Host "SUCCESS: Python found: $pythonVersion" -ForegroundColor Green
    }
    elseif (Test-Command python3) {
        $pythonVersion = python3 --version 2>&1
        Write-Host "SUCCESS: Python3 found: $pythonVersion" -ForegroundColor Green
        # Create alias for python command
        Set-Alias -Name python -Value python3
    }
    else {
        Write-Host "ERROR: Python not found. Installing Python..." -ForegroundColor Red
        
        # Check if Chocolatey is installed
        if (-not (Test-Command choco)) {
            if (-not (Install-Chocolatey)) {
                Write-Host "ERROR: Cannot proceed without Chocolatey. Please install Python manually." -ForegroundColor Red
                exit 1
            }
        }
        
        try {
            choco install python -y
            Write-Host "SUCCESS: Python installed successfully!" -ForegroundColor Green
            Update-EnvironmentPath
        }
        catch {
            Write-Host "ERROR: Failed to install Python. Please install manually from python.org" -ForegroundColor Red
            exit 1
        }
    }
    
    # Check pip
    Write-Host "Checking pip..." -ForegroundColor Yellow
    if (Test-Command pip) {
        Write-Host "SUCCESS: pip is available" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: pip not found. Installing pip..." -ForegroundColor Red
        try {
            python -m ensurepip --upgrade
            Write-Host "SUCCESS: pip installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to install pip. Please install manually." -ForegroundColor Red
            exit 1
        }
    }
}

# Check and install Node.js (optional, for separate React app)
if (-not $SkipNode -and $CreateReactApp) {
    Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
    
    if (Test-Command node) {
        $nodeVersion = node --version
        Write-Host "SUCCESS: Node.js found: $nodeVersion" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: Node.js not found. Installing Node.js..." -ForegroundColor Red
        
        # Check if Chocolatey is installed
        if (-not (Test-Command choco)) {
            if (-not (Install-Chocolatey)) {
                Write-Host "ERROR: Cannot proceed without Chocolatey. Please install Node.js manually." -ForegroundColor Red
                exit 1
            }
        }
        
        try {
            choco install nodejs -y
            Write-Host "SUCCESS: Node.js installed successfully!" -ForegroundColor Green
            Update-EnvironmentPath
        }
        catch {
            Write-Host "ERROR: Failed to install Node.js. Please install manually from nodejs.org" -ForegroundColor Red
            exit 1
        }
    }
}

# Create virtual environment
Write-Host "Setting up Python virtual environment..." -ForegroundColor Yellow
try {
    if (Test-Path "venv") {
        Write-Host "INFO: Virtual environment already exists. Activating..." -ForegroundColor Blue
    }
    else {
        python -m venv venv
        Write-Host "SUCCESS: Virtual environment created!" -ForegroundColor Green
    }
    
    # Activate virtual environment
    & .\venv\Scripts\Activate.ps1
    Write-Host "SUCCESS: Virtual environment activated!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to create virtual environment: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Continuing with global Python installation..." -ForegroundColor Yellow
}

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Yellow
try {
    python -m pip install --upgrade pip
    Write-Host "SUCCESS: pip upgraded successfully!" -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Failed to upgrade pip" -ForegroundColor Yellow
}

# Install Python packages
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow

$packages = @(
    "Flask==2.3.3",
    "Flask-CORS==4.0.0",
    "numpy>=1.24.0",
    "google-generativeai",
    "python-dotenv",
    "sentence-transformers",
    "lightrag-hku",
    "nest-asyncio"
)

$failedPackages = @()

foreach ($package in $packages) {
    Write-Host "  Installing $package..." -ForegroundColor White
    try {
        python -m pip install $package
        Write-Host "  SUCCESS: $package installed" -ForegroundColor Green
    }
    catch {
        Write-Host "  ERROR: Failed to install $package" -ForegroundColor Red
        $failedPackages += $package
    }
}

# Check for failed packages
if ($failedPackages.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Some packages failed to install:" -ForegroundColor Yellow
    foreach ($pkg in $failedPackages) {
        Write-Host "  - $pkg" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Trying to install failed packages individually..." -ForegroundColor Yellow
    
    foreach ($pkg in $failedPackages) {
        Write-Host "Retrying $pkg..." -ForegroundColor White
        try {
            python -m pip install $pkg --no-cache-dir
            Write-Host "SUCCESS: $pkg installed on retry" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: $pkg still failed. You may need to install it manually." -ForegroundColor Red
        }
    }
}

# Create React app (optional)
if ($CreateReactApp) {
    Write-Host ""
    Write-Host "Creating React application..." -ForegroundColor Yellow
    
    if (Test-Command npx) {
        try {
            npx create-react-app oxford-chatbot
            Set-Location oxford-chatbot
            npm install lucide-react
            Write-Host "SUCCESS: React app created successfully!" -ForegroundColor Green
            Write-Host "INFO: React app location: $(Get-Location)" -ForegroundColor Blue
            Set-Location ..
        }
        catch {
            Write-Host "ERROR: Failed to create React app: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "ERROR: npx not found. Cannot create React app." -ForegroundColor Red
    }
}

# Create .env template
Write-Host ""
Write-Host "Creating .env template..." -ForegroundColor Yellow

$envTemplate = @"
# Oxford College Chatbot Environment Variables
# Copy this file and rename to '.env' then fill in your actual values

# Required: Your Google Gemini API Key
GEMINI_API_KEY=your_gemini_api_key_here

# Optional: Flask configuration
FLASK_ENV=development
FLASK_DEBUG=True

# Optional: Custom ports
FLASK_PORT=5000
REACT_PORT=3000
"@

try {
    $envTemplate | Out-File -FilePath ".env.template" -Encoding UTF8
    Write-Host "SUCCESS: .env template created!" -ForegroundColor Green
    Write-Host "INFO: Please copy .env.template to .env and add your GEMINI_API_KEY" -ForegroundColor Blue
}
catch {
    Write-Host "WARNING: Could not create .env template" -ForegroundColor Yellow
}

# Final summary
Write-Host ""
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy .env.template to .env and add your GEMINI_API_KEY" -ForegroundColor White
Write-Host "2. Place your rag.py file in this directory" -ForegroundColor White
Write-Host "3. Place app.py (Flask backend) in this directory" -ForegroundColor White
Write-Host "4. Run: python app.py" -ForegroundColor White

if ($CreateReactApp) {
    Write-Host "5. For React app: cd oxford-chatbot && npm start" -ForegroundColor White
}
else {
    Write-Host "5. Use the React component in Claude's interface" -ForegroundColor White
}

Write-Host ""
Write-Host "To activate virtual environment later, run:" -ForegroundColor Yellow
Write-Host "   .\venv\Scripts\Activate.ps1" -ForegroundColor White
Write-Host ""
Write-Host "For troubleshooting, see the setup instructions document" -ForegroundColor Blue

# Test installations
Write-Host ""
Write-Host "Testing installations..." -ForegroundColor Yellow

Write-Host "Python version: " -NoNewline
try {
    python --version
}
catch {
    Write-Host "ERROR: Python test failed" -ForegroundColor Red
}

Write-Host "Pip version: " -NoNewline
try {
    python -m pip --version
}
catch {
    Write-Host "ERROR: Pip test failed" -ForegroundColor Red
}

if ($CreateReactApp -and (Test-Command node)) {
    Write-Host "Node.js version: " -NoNewline
    node --version
    Write-Host "NPM version: " -NoNewline
    npm --version
}

Write-Host ""
Write-Host "Ready to launch your Oxford College Chatbot!" -ForegroundColor Green