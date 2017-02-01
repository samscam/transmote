#!/usr/bin/python

import os, sys, argparse
from appcast import Appcast, Delta
import urlparse

import datetime
import time
import json
from subprocess import Popen, PIPE

# -----------------

def sign_update(file = '', private_key_path = ''):
    sign_update_script = os.path.join(SPARKLE_BIN_PATH , "sign_update")
    sign_update_call = [sign_update_script, file, private_key_path]
    process = Popen(sign_update_call, stdout=PIPE)
    (output, err) = process.communicate()
    exit_code = process.wait()
    return output.rstrip()

# -----------------


# Parse incoming arguments

parser = argparse.ArgumentParser(description='Generate sparkle appcast!')
parser.add_argument('config_file')
parser.add_argument('input_archive')
parser.add_argument('-v', '--version', help='the target version number')
parser.add_argument('-vv', '--verbose', action="store_true")

parser.add_argument('output_file')
args = parser.parse_args()

# Are we verbose?

VERBOSE = args.verbose

# Resolve paths
cwd = os.getcwd()
input_archive = os.path.join(cwd,args.input_archive)
config_file = os.path.join(cwd,args.config_file)
output_file = os.path.join(cwd,args.output_file)

# What version is this
version = args.version

if VERBOSE:
    print 'Input archive: ', input_archive
    print 'Version: ', version
    print 'Config: ', config_file

# Read config file

with open(config_file) as data_file:
    data = json.load(data_file)


SPARKLE_BIN_PATH        = os.path.join(cwd,data["SPARKLE_BIN_PATH"])
PRIVATE_KEY_PATH        = os.path.join(cwd,data["PRIVATE_KEY_PATH"])
if VERBOSE:
    print '-- sparkle bin: ', SPARKLE_BIN_PATH
    print '-- private key path: ', PRIVATE_KEY_PATH


APPCAST_URL = urlparse.urljoin(data["APPCAST_BASE_URL"],data["APPCAST_FILE_NAME"])
if VERBOSE:
    print 'APPCAST_URL: ', APPCAST_URL

(_,input_archive_filename) = os.path.split(input_archive)
if VERBOSE:
    print '-- input_archive_filename: ', input_archive_filename
APPCAST_LATEST_VERSION_URL = urlparse.urljoin(data["APPCAST_BASE_URL"],data["RELEASES_DIR"])
APPCAST_LATEST_VERSION_URL = urlparse.urljoin(APPCAST_LATEST_VERSION_URL,input_archive_filename)
if VERBOSE:
    print '-- APPCAST_LATEST_VERSION_URL: ', APPCAST_LATEST_VERSION_URL

DSA_SIGNATURE = sign_update(file = input_archive, private_key_path = PRIVATE_KEY_PATH)

if VERBOSE:
    print "DSA Signature: ", DSA_SIGNATURE

APP_SIZE = os.path.getsize(input_archive)

APPCAST_PUBDATE = time.strftime("%a, %d %b %G %T %z")

## ACTUALLY CREATE THE APPCAST

appcast = Appcast()

appcast.title                               = data["APPCAST_TITLE"]
appcast.app_name                            = data["APP_NAME"]
appcast.appcast_url                         = APPCAST_URL
appcast.appcast_description                 = data["APPCAST_DESCRIPTION"]
# if APPCAST_RELEASE_NOTES_FILE:
#     appcast.release_notes_file              = APPCAST_RELEASE_NOTES_FILE
appcast.launguage                           = data["APPCAST_LANGUAGE"]
appcast.latest_version_number               = version
appcast.short_version_string                = version
appcast.latest_version_update_description   = data["APPCAST_LATEST_VERSION_UPDATE_DESCRIPTION"]
appcast.pub_date                            = APPCAST_PUBDATE
appcast.latest_version_url                  = APPCAST_LATEST_VERSION_URL #format_url(url=APPCAST_LATEST_VERSION_URL, title=LATEST_APP_ARCHIVE)

appcast.latest_version_size                 = APP_SIZE
appcast.latest_version_dsa_key              = DSA_SIGNATURE

## write out the appcast
appcast_xml =  appcast.render()
with open(output_file, 'w') as f:
    f.write(appcast_xml)
# log("create {}".format(output_file))
