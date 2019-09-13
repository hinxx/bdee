#!/usr/bin/env python3
#

import sys
import os
import configparser
import pprint
import pdb
import datetime
import getpass
import socket
import shutil
import subprocess


files_path = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + '/../files')
packages_config = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + '/../packages/packages.ini')
recipes_config = os.path.realpath(os.path.dirname(os.path.realpath(__file__)) + '/../recipes/recipes.ini')
workspace_path = os.path.realpath(os.path.curdir)

# class Packages:
#     def __init__(self, config_file):
#         self._config_file = config_file
#         self._config = configparser.ConfigParser()
#         self._config.read(self._config_file)

#     def exists(self, package_name):
#         return self._config.has_section(package_name)

#     def option(self, package_name, option, default=''):
#         if self._config.has_section(package_name):
#             return self._config.get(package_name, option, fallback=default)
#         return default

#     def name(self, package_name):
#         return self.option(package_name, 'name')

#     def repo(self, package_name):
#         return self.option(package_name, 'repo')

#     def branches(self, package_name):
#         return self.option(package_name, 'branches')

#     def tags(self, package_name):
#         return self.option(package_name, 'tags')


# class Recipes:
#     def __init__(self, config_file):
#         self._config_file = config_file
#         self._config = configparser.ConfigParser()
#         self._config.read(self._config_file)

#     def exists(self, recipe_uid):
#         return self._config.has_section(recipe_uid)

#     def option(self, recipe_uid, option, default=''):
#         if self._config.has_section(recipe_uid):
#             return self._config.get(recipe_uid, option, fallback=default)
#         return default

#     def chain(self, recipe_uid):
#         items = self.option(recipe_uid, 'chain', None)
#         if items is not None:
#             return tuple(self.option(recipe_uid, 'chain').split('\n'))
#         return None


def load_packages(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)
    packages = dict()
    for section in config.sections():
        items = dict()
        for item in config[section]:
            value = config.get(section, item)
            if item in ['branches', 'tags']:
                value = tuple(value.split())
            items[item] = value
        packages[section] = items
    return packages


def load_recipes(config_file):
    config = configparser.ConfigParser()
    config.read(config_file)
    recipes = dict()
    for section in config.sections():
        items = dict()
        for item in config[section]:
            value = config.get(section, item)
            if item in ['chain']:
                value = tuple(value.split())
            items[item] = value
        recipes[section] = items
    return recipes


def sanity_check(packages, recipes, recipe_uid):
    if recipe_uid not in recipes:
        return False

    chain = recipes[recipe_uid]['chain']
    for item in chain:
        package_name, package_version = item.split(':')
        if package_name not in packages:
            return False
        package_versions = packages[package_name]['branches'] + packages[package_name]['tags']
        if package_version not in package_versions:
            return False
    return True


def recipe_chain(recipes, recipe_uid, reverse=False):
    chain = recipes[recipe_uid]['chain']
    if reverse:
        return chain[::-1]
    return chain


def load_chain(packages, recipes, recipe_uid):
    raw_chain = recipes[recipe_uid]['chain']
    chain = []
    for raw_item in raw_chain:
        name, version = raw_item.split(':')
        item = packages[name]
        item['path'] = os.path.join(workspace_path, item['name'])
        item['version'] = version
        item['want_tag'] = False
        item['want_branch'] = False
        if len(item['branches']) and version in item['branches']:
            item['want_branch'] = True
        if len(item['tags']) and version in item['tags']:
            item['want_tag'] = True

        chain.append(item)
    return chain


def prepare_workspace(packages, recipes, recipe_uid):
    release_file = open('RELEASE.local', 'w')
    for item in recipe_chain(recipes, recipe_uid):
        package_name, package_version = item.split(':')
        package_var = package_name.upper()
        package_path = os.path.join(workspace_path, package_name)
        package_str = "%s=%s" % (package_var, package_path)
        # print(package_str)
        release_file.write(package_str+'\n')
    release_file.close()


def provide_packages(packages, recipes, recipe_uid):
    for item in recipe_chain(recipes, recipe_uid):
        package_name, package_version = item.split(':')
        package_clone(packages[package_name])
        package_checkout(packages[package_name], package_version)
        package_build(packages[package_name])


def generate_meta(chain):
    meta_file = os.path.join(workspace_path, 'meta.txt')
    handle = open(meta_file, 'w')
    handle.write('date %s\n' % datetime.datetime.now())
    handle.write('user %s\n' % getpass.getuser())
    # handle.write('hostname %s\n' % socket.gethostname())
    handle.write('hostname %s\n' % socket.getfqdn())
    handle.write('number of packages %d\n' % len(chain))
    handle.write('\n')
    index = 1
    for item in chain:
        handle.write('package #%d\n' % index)
        handle.write('name %s\n' % item['name'])
        handle.write('version %s\n' % item['version'])
        handle.write('branches %s\n' % str(item['branches']))
        handle.write('tags %s\n' % str(item['tags']))
        handle.write('repo %s\n' % item['repo'])
        handle.write('path %s\n' % item['path'])
        handle.write('\n')
        index += 1
    handle.close()


def generate_release_local(chain):
    release_file = os.path.join(workspace_path, 'RELEASE.local')
    handle = open(release_file, 'w')
    for item in chain:
        line = "%s=%s" % (item['name'].upper(), item['path'])
        print('RELEASE.local line: %s' % line)
        handle.write(line + '\n')
    handle.close()


def generate_config_site_local():
    output_file = os.path.join(workspace_path, 'CONFIG_SITE.local')
    input_file = os.path.join(files_path, 'CONFIG_SITE.local')
    shutil.copyfile(input_file, output_file)


def handle_chain(chain):
    for item in chain:
        package_clone(item)
        package_checkout(item)
        package_configure(item)


def package_clone(package):
    if not os.path.isdir(package['path']):
        print("git clone %s %s" % (package['repo'], package['name']))
        subprocess.run(['git', 'clone', package['repo'], package['name']])
    else:
        print("already cloned %s into %s" % (package['name'], package['path']))


def package_checkout(package):
    if not os.path.isdir(package['path']):
        print("package %s path %s does not exists!" % (package['name'], package['path']))
    else:
        print("git -C %s checkout %s" % (package['path'], package['version']))
        subprocess.run(['git', '-C', package['path'], 'checkout', package['version']])


def package_configure(package):
    if not os.path.isdir(package['path']):
        print("package %s path %s does not exists!" % (package['name'], package['path']))
    else:
        release_file = os.path.join(package['path'], 'configure', 'RELEASE')
        handle = open(release_file, 'r')
        lines = handle.readlines()
        for line in lines:
            if not line.startswith('#'):
                print('LINE: ' + line)
        handle.close()



def package_build(package):
    name = package['name']
    path = os.path.join(workspace_path, name)
    print("make -C %s all -j" % (path))


def package_clean(package):
    name = package['name']
    path = os.path.join(workspace_path, name)
    print("make -C %s clean -j" % (path))


def package_distclean(package):
    name = package['name']
    path = os.path.join(workspace_path, name)
    print("make -C %s distclean -j" % (path))














def main():
    print("arguments: %s" % sys.argv)
    if len(sys.argv) == 1:
        print("Missing argument!")
        exit(1)

    print("packages config: %s" % packages_config)
    print("recipes config: %s" % recipes_config)

    # pkgs = configparser.ConfigParser()
    # pkgs.read(packages_config)
    # print("dump pkg file '%s' sections" % packages_config)
    # print(pkgs.sections())
    # for section in pkgs.sections():
    #     print("SECTION: %s" % section)
    #     print("OPTIONS:")
    #     for item in pkgs[section].items():
    #         print(item)

    # rcps = configparser.ConfigParser()
    # rcps.read(recipes_config)
    # print("dump rcp file '%s' sections" % recipes_config)
    # print(rcps.sections())
    # for section in rcps.sections():
    #     print("SECTION: %s" % section)
    #     print("OPTIONS:")
    #     for item in rcps[section].items():
    #         print(item)

    # recipe_name = sys.argv[1]
    # print("want recipe: %s CHAIN %s" % (rcps[recipe_name], dict(rcps[recipe_name].items())))

    # packages = Packages(packages_config)
    # for p in ['foo', 'asyn']:
    #     if packages.exists(p):
    #         print("package " + p + " exists!")
    #     else:
    #         print("package " + p + " DOES NOT exists!")

    # for p in ['foo', 'asyn']:
    #     print("package " + p + " NAME = '" + packages.name(p) + "'")
    #     print("package " + p + " FOO = '" + packages.name(p) + "'")

    # recipes = Recipes(recipes_config)
    # for p in ['foo', 'asyn']:
    #     if recipes.exists(p):
    #         print("recipe " + p + " exists!")
    #     else:
    #         print("recipe " + p + " DOES NOT exists!")

    # for p in ['foo:bar', 'busy:master']:
    #     print("recipe " + p + " CHAIN = '" + str(recipes.chain(p)) + "'")

    # recipe_uid = sys.argv[1]
    # ok = sanity_check(packages, recipes, recipe_uid)
    # print("SANE " + str(ok))

    # chain = recipe_chain(recipes, recipe_uid)
    # print("CHAIN " + str(chain))

    # if chain:
    #     for item in chain:
    #         print("CHAIN ITEM " + item)
    #         package_name, package_version = item.split(':')
    #         print("PACKAGE NAME " + packages.name(package_name))
    #         print("PACKAGE REPO " + packages.repo(package_name))
    #         print("PACKAGE TAGS " + packages.tags(package_name))

    packages = load_packages(packages_config)
    print("packages:")
    pprint.pprint(packages)

    recipes = load_recipes(recipes_config)
    print("recipes:")
    pprint.pprint(recipes)

    recipe_uid = sys.argv[1]
    ok = sanity_check(packages, recipes, recipe_uid)
    print("SANE " + str(ok))

    # chain = recipe_chain(recipes, recipe_uid)
    # print("CHAIN " + str(chain))

    # reverse_chain = recipe_chain(recipes, recipe_uid, True)
    # print("REVERSED CHAIN " + str(reverse_chain))

    # prepare_workspace(packages, recipes, recipe_uid)

    chain = load_chain(packages, recipes, recipe_uid)
    print("LOADED CHAIN:")
    pprint.pprint(chain)

    generate_meta(chain)
    generate_release_local(chain)
    generate_config_site_local()

    handle_chain(chain)


if __name__ == '__main__':
    main()
