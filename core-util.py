#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# Copyright (c) 2017, Vencore Labs
# All rights reserved.
#-------------------------------------------------------------------------------
from __future__ import print_function

import argparse
import io
import os
import subprocess
import sys
import tarfile

import docker
import inquirer
#-------------------------------------------------------------------------------
__author__ = 'Daniel R. Kerr'
__email__ = 'daniel.r.kerr@gmail.com'
#-------------------------------------------------------------------------------
def get_core_envs(label):
    ctr_list_kwargs = dict()
    if label is not None:
        ctr_list_kwargs['filters'] = dict(label=label)

    client = docker.from_env()
    return {c.name: c for c in client.containers.list(**ctr_list_kwargs)}

def get_core_env(label):
    ctrs = get_core_envs(label)

    if len(ctrs) == 0:
        pass
    elif len(ctrs) == 1:
        return list(ctrs.values())[0]
    else:
        return ctrs[inquirer.prompt([
            inquirer.List(
                'ctr_name',
                message='Which core env would you like to use?',
                choices=list(sorted(ctrs.keys())),
            ),
        ])['ctr_name']]

def run_command(label, private_key, host, port, command):
    key_path = os.path.expanduser(private_key)
    assert os.path.exists(key_path)
    assert os.path.isfile(key_path)

    ctr = get_core_env(label)
    if port is None:
        port = ctr.attrs['NetworkSettings']['Ports']['22/tcp'][0]['HostPort']

    cmd = 'ssh'
    cmd += ' -i {0}'.format(key_path)
    cmd += ' -t'
    cmd += ' -o StrictHostKeyChecking=no'
    cmd += ' -o UserKnownHostsFile=/dev/null'
    cmd += ' -o XAuthLocation=/opt/X11/bin/xauth'
    cmd += ' -p {0}'.format(port)
    cmd += ' -X'
    cmd += ' root@{0}'.format(host)
    cmd += ' {0}'.format(command)

    subprocess.run(cmd, shell=True)
#-------------------------------------------------------------------------------
def cli_build_func(args):
    client = docker.from_env()

    client.images.build(
        path='.',
        dockerfile='Dockerfile',
        tag='{0}:{1}'.format(args.image, args.tag),
        pull=args.pull,
        nocache=args.nocache,
        rm=True,
        forcerm=True,
    )

def cli_up_func(args):
    key_path = os.path.expanduser(args.public_key)

    client = docker.from_env()

    volumes = {
        '/lib/modules': {
            'bind': '/lib/modules',
            'mode': 'rw',
        }
    }

    if args.pull:
        client.images.pull(name=args.image, tag=args.tag)

    ctr = client.containers.run(
        image='{0}:{1}'.format(args.image, args.tag),
        cap_add=['ALL'],
        detach=True,
        labels=[
            args.label,
        ],
        privileged=True,
        publish_all_ports=True,
        volumes=volumes,
    )

    if os.path.exists(key_path) and os.path.isfile(key_path):
        io_bytes = io.BytesIO()
        with tarfile.open(fileobj=io_bytes, mode='w') as fd:
            fd.add(key_path, 'authorized_keys')
            ctr.put_archive('/root/.ssh', io_bytes.getvalue())
            ctr.exec_run('chmod 600 /root/.ssh/authorized_keys')
            ctr.exec_run('chown root:root /root/.ssh/authorized_keys')
            ctr.exec_run('supervisorctl restart sshd')

    print (ctr.name)

def cli_down_func(args):
    ctr = get_core_env(args.label)

    if ctr is None:
        print ('no active core env found')
    else:
        ctr.stop(timeout=args.timeout)

        if args.remove:
            ctr.remove(force=True)

def cli_ps_func(args):
    msg = '{0:20s} {1:20s} {2:20s} {3:20s}'

    print (msg.format('Name', 'ID', 'Status', 'Image'))
    print (msg.format('=' * 20, '=' * 20, '=' * 20, '=' * 20))

    ctrs = get_core_envs(args.label)
    for name in sorted(ctrs.keys()):
        ctr = ctrs[name]
        print (msg.format(ctr.name, ctr.id[:10], ctr.status, ctr.image.tags[0]))
    return True

def cli_ssh_func(args):
    run_command(args.label, args.private_key,
                args.host, args.port,
                args.shell)

def cli_gui_func(args):
    run_command(args.label, args.private_key,
                args.host, args.port,
                'core-gui')

def cli_pygui_func(args):
    run_command(args.label, args.private_key,
                args.host, args.port,
                'core-pygui')
#-------------------------------------------------------------------------------
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--host', default='127.0.0.1')
    parser.add_argument('-P', '--port', type=int)
    parser.add_argument('--label', default='devdkerr')
    subparser = parser.add_subparsers()

    build_parser = subparser.add_parser('build')
    build_parser.add_argument('--image', default='devdkerr/core')
    build_parser.add_argument('--nocache', action='store_true')
    build_parser.add_argument('--pull', action='store_true')
    build_parser.add_argument('--tag', default='latest')
    build_parser.set_defaults(func=cli_build_func)

    up_parser = subparser.add_parser('up')
    up_parser.add_argument('--image', default='devdkerr/core')
    up_parser.add_argument('--tag', default='latest')
    up_parser.add_argument('--public-key', default='~/.ssh/id_rsa.pub')
    up_parser.add_argument('--pull', action='store_true')
    up_parser.set_defaults(func=cli_up_func)

    down_parser = subparser.add_parser('down')
    down_parser.add_argument('--remove', '-rm', action='store_true')
    down_parser.add_argument('--timeout', default=10, type=int)
    down_parser.set_defaults(func=cli_down_func)

    ps_parser = subparser.add_parser('ps')
    ps_parser.set_defaults(func=cli_ps_func)

    ssh_parser = subparser.add_parser('ssh')
    ssh_parser.add_argument('--private-key', default='~/.ssh/id_rsa')
    ssh_parser.add_argument('--shell', default='bash')
    ssh_parser.set_defaults(func=cli_ssh_func)

    gui_parser = subparser.add_parser('gui')
    gui_parser.add_argument('--private-key', default='~/.ssh/id_rsa')
    gui_parser.set_defaults(func=cli_gui_func)

    pygui_parser = subparser.add_parser('pygui')
    pygui_parser.add_argument('--private-key', default='~/.ssh/id_rsa')
    pygui_parser.set_defaults(func=cli_pygui_func)

    args = parser.parse_args()
    #---------------------------------------
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()
    #---------------------------------------
    sys.exit()
#-------------------------------------------------------------------------------
