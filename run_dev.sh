#!/bin/bash

flutter --version
flutter run -d web-server --web-renderer html --web-browser-flag "--disable-web-security"
