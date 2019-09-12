#!/usr/bin/env python3.6
#

import sys
import os
import configparser
import pprint
import pdb

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


def prepare_workspace(packages, recipes, recipe_uid):
    release_str = ""
    for item in recipe_chain(recipes, recipe_uid):
        package_name, package_version = item.split(':')
        package_var = package_name.upper()
        package_path = os.path.join(workspace_path, package_name)
        package_str = "%s=%s" % (package_var, package_path)
        print(package_str)
        release_str += package_str + "\n"

    release_file = open('RELEASE.local', 'w')
    release_file.write(release_str)
    release_file.close()


def provide_packages(packages, recipes, recipe_uid):
    for item in recipe_chain(recipes, recipe_uid):
        package_name, package_version = item.split(':')
        package_clone(packages[package_name])
        package_checkout(packages[package_name], package_version)
        package_build(packages[package_name])


def package_clone(package):
    name = package['name']
    repo = package['repo']
    print("git clone %s %s" % (repo, name))


def package_checkout(package, version):
    name = package['name']
    path = os.path.join(workspace_path, name)
    print("git -C %s checkout %s" % (path, version))


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

    chain = recipe_chain(recipes, recipe_uid)
    print("CHAIN " + str(chain))

    reverse_chain = recipe_chain(recipes, recipe_uid, True)
    print("REVERSED CHAIN " + str(reverse_chain))

    prepare_workspace(packages, recipes, recipe_uid)


if __name__ == '__main__':
    main()
