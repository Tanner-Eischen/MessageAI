#!/usr/bin/env bash
set -e
npm --prefix contracts run validate
npm --prefix contracts run gen:dart
echo "Generated Dart client to /frontend/lib/gen/api"
