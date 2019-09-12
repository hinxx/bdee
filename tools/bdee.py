#!/usr/bin/env python3.6
#

import sys
import os
import configparser


packages_config = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + '/../packages/packages.ini')


def main():
    print("arguments: %s" % sys.argv)
    print("packages config: %s" % packages_config)
    parser = configparser.ConfigParser()
    parser.read(packages_config)
    print("dump pkg file '%s' sections" % packages_config)
    print(parser.sections())
    for section in parser.sections():
        print("SECTION: %s" % section)
        print("OPTIONS:")
        for item in parser[section].items():
            print(item)


if __name__ == '__main__':
    main()
