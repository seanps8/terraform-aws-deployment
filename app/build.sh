#!/bin/bash

ZIP_NAME="lambda.zip"

rm -rf python $ZIP_NAME

mkdir -p python
pip install -r requirements-lambda.txt -t python/

cp lambda_function.py python/

cd python
zip -r ../$ZIP_NAME .
cd ..

rm -rf python

echo "Lambda function zip created"