#!/bin/bash

# Media Cast DLNA - Pigeon Code Generator Script
# This script generates Android-specific code from the Pigeon definitions
# iOS support has been temporarily removed due to Apple privacy limitations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

print_info "Generating platform-specific code from Pigeon definitions..."

# Generate code using pigeon with explicit output paths (Android only)
dart run pigeon --input pigeons/media_cast_dlna.dart \
       --dart_out lib/src/media_cast_dlna_pigeon.dart \
       --kotlin_out android/src/main/kotlin/br/com/felnanuke2/media_cast_dlna/MediaCastDlnaPigeon.kt

if [ $? -eq 0 ]; then
    print_success "Pigeon code generation completed successfully!"
else
    print_error "Pigeon code generation failed!"
    exit 1
fi

print_success "Pigeon code generation process completed!"
