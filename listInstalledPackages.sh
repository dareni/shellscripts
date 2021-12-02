#!/usr/bin/env python3
#Packages installed manually vs automatically installed dependencies or marked by apt-mark manual xxx.

from apt import cache

manual = set(pkg for pkg in cache.Cache() if pkg.is_installed and not pkg.is_auto_installed)
depends = set(dep_pkg.name for pkg in manual for dep in pkg.installed.get_dependencies('PreDepends', 'Depends', 'Recommends') for dep_pkg in dep)

print('\n'.join(pkg.name for pkg in manual if pkg.name not in depends))
