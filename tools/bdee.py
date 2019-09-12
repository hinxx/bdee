#!/usr/bin/env python3.6
#

import sys
import os
import configparser


packages_dir = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + '/../packages')


def main():
    print("arguments: %s" % sys.argv)
    print("packages folder: %s" % packages_dir)
    package_files = []
    for name in os.listdir(packages_dir):
        if name.endswith('.pkg'):
            package_files.append(name)
    print("package files: %s" % package_files)
    parser = configparser.ConfigParser()
    for name in package_files:
        pkg_file = os.path.join(packages_dir, name)
        parser.read(pkg_file)
        print("dump pkg file '%s'" % pkg_file)
        print(parser)

if __name__ == '__main__':
    main()
