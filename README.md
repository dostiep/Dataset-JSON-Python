# Dataset-JSON Python Application

## Description

The main purpose is to create Dataset-JSON from SAS7BDAT or XPT datasets.

The Python application can be launched by executing Dataset-JSON.pyw in a Windows environment.

A valid Define.xml file should be selected using the first Browse button. The second Browse button should be used to select the folder where the files to convert are located. The third Browse button should be used to select the folder where the Dataset-JSON files will be created. 

You can select the option of converting SAS7BDAT or XPT files using the Radio Button option.

Click on Submit button to generate the Dataset-JSON files.

The Examples folder contains example files that can be used to test the application.

The Schema folder contains the Dataset-JSON schema to make sure each file is compliant.

The Stylesheet folder contains the XSLT stylesheet that is used to read Define.xml information into Dataset-JSON files.

Required Python modules are available in requirements.txt file. You will need to updagre PySimpleGUI module by submitting this line of code: python -m PySimpleGUI.PySimpleGUI upgrade
A pop-up window will appear asking to if you want to update this release of PySimpleGUI. Click Yes for the latest release to be installed.

This is a first draft version and comments are welcomed.
