#!/usr/bin/python

from __future__ import print_function
import argparse
import os
import json as simplejson
import yaml

def yaml_to_json(yaml_file, json_file, source_dir, target_dir, verbose):
    if target_dir:
        # convert explicit files
        if yaml_file and json_file:
            print_verbose(verbose, 'Explicit convertion of given file')
            for current_dir, _, sub_files in os.walk(source_dir):
                for current_file in sub_files:
                    if current_file == str(yaml_file):
                        convert(current_file, target_dir, json_file, current_dir)
        # convert all json
        else:
            print_verbose(verbose, 'Converting all YAML files found in source directory')
            for current_dir, _, sub_files in os.walk(source_dir):
                for current_file in sub_files:
                    if '.yml' in current_file:
                        print("Converting "+current_file)
                        convert(current_file, target_dir, os.path.splitext(current_file)[0], current_dir)
    else:
        print('No paths given')
        return False

def convert(current_file, target_dir, json_file, current_dir):
    origin_file = open(current_dir+'/'+current_file)
    yaml_content = yaml.load(origin_file)
    newfile = open(str(current_dir)+'/'+str(json_file)+'.json', mode='w+')
    ## convert into json
    simplejson.dump(yaml_content, newfile)
    newfile.close()
    origin_file.close()

def print_verbose(verbose, string):
    if verbose:
        print(string)


def cli_parse():
    """Start the CLI interface."""
    ## Define CLI arguments
    parser = argparse.ArgumentParser(description='Convert a given YAML file to compressed JSON.')
    parser.add_argument('-sd', '--source-dir', action='store', dest='source_dir', required=True, help='Set the directory where YAML files are stored that should be converted. Can contain sub directories.')
    parser.add_argument('-td', '--target-dir', action='store', dest='target_dir', required=True, help='Set the directory where converted JSON files are saved, per convention.')
    parser.add_argument('-sf', '--source-file', action='store', dest='source_file', help='Optionally set the YAML file that should be converted.')
    parser.add_argument('-tf', '--target-file', action='store', dest='target_file', help='Optionally set the desired name for target JSON file. If the file exists, it\'s contents will be overwritten.')
    parser.add_argument('-v', '--verbose', action='store_true', dest='verbose', help='Set to verbose.')
    args = parser.parse_args()

    if not args.source_file:
        args.source_file = None
    if not args.target_file:
        args.target_file = None

    yaml_to_json(args.source_file, args.target_file, args.source_dir, args.target_dir, args.verbose)

cli_parse()
