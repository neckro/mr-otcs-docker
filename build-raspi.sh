#!/bin/bash
set -ex

time docker build --platform=linux/arm/v7 -t neckro/mr-otcs-raspi .
