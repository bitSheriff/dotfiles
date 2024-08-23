#! /usr/bin/python3

# HELPER FOR KDE-CONNECT CLI
KDEC_CMD = "kdeconnect-cli"
 
 
import os
import sys
import argparse

def get_device_ids():
    idList=[]
    return idList

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    options = parser.add_argument_group("options")
    params = parser.add_argument_group("parameter")

     
    options.add_argument('-a', '--all', help="All devices flag", default=False, action='store_true')
    params.add_argument('send_clip', help="Send Clipboard to devive", default=False, action='store_true')

    args = parser.parse_args(arguments)

    print(args)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
