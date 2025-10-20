#!/bin/bash

# Icon Generator Setup Script
# This script sets up the environment for the icon generator

set -e  # Exit on any error

echo "🚀 Setting up Icon Generator environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python 3 is installed
print_status "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Python $PYTHON_VERSION found"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is not installed. Please install pip3."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    print_status "Creating virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install requirements
print_status "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    print_success "Dependencies installed successfully"
else
    print_error "requirements.txt not found!"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found in scripts directory"
    if [ -f "../.env.example" ]; then
        print_status "Copying .env.example to .env..."
        cp ../.env.example .env
        print_warning "Please edit .env file and add your Google API key"
    else
        print_status "Creating basic .env file..."
        cat > .env << EOF
# Google Generative AI API Key
GOOGLE_API_KEY=your_api_key_here

# Icon Generator Settings
ICON_OUTPUT_DIR=generated_icons
ICON_SIZE=512
ICON_STYLE=modern
EOF
        print_warning "Please edit .env file and add your Google API key"
    fi
else
    print_success ".env file already exists"
fi

# Create output directory
print_status "Creating output directory..."
mkdir -p ../generated_icons
print_success "Output directory created"

# Test the installation
print_status "Testing installation..."
if python3 -c "import google.generativeai; import PIL; import dotenv; print('All imports successful')" 2>/dev/null; then
    print_success "All dependencies are working correctly"
else
    print_error "Some dependencies are not working correctly"
    exit 1
fi

echo ""
print_success "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .env file and add your Google API key"
echo "2. Run the icon generator:"
echo "   cd scripts"
echo "   source venv/bin/activate"
echo "   python3 icon_generator_v2.py"
echo ""
echo "To deactivate the virtual environment later, run: deactivate"