#!/usr/bin/env python3


def print_tree(tree, indent):
    print(' ' * indent + '* ' + str(tree.id), str(tree.name), tree.type)
    for node in tree.nodes:
        print_tree(node, indent + 4)


def is_floating(container):
    if container.type == 'floating_con':
        return True
    if not container.parent:
        return False
    return container.parent.type == 'floating_con'
