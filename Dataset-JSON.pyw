import os
import PySimpleGUI as sg
import pandas as pd
import pyreadstat
import saxonche
import datetime
import time
import json
import jsonschema

# Global Variable Path
path = os.path.abspath(".")

# Datetime to Integer Function
def datetime_to_integer(dt):
    if isinstance(dt, datetime.date):
        # For date objects, convert to SAS date representation
        days_since_epoch = (dt - datetime.date(1960, 1, 1)).days
        return days_since_epoch
    elif isinstance(dt, datetime.datetime):
        # For datetime objects, convert to SAS date representation
        days_since_epoch = (dt.date() - datetime.date(1960, 1, 1)).days
        seconds_since_midnight = (dt.hour * 3600 + dt.minute * 60 + dt.second + dt.microsecond / 1e6)
        return days_since_epoch + seconds_since_midnight / 86400
    elif isinstance(dt, datetime.time):
        # For time objects, convert to SAS date representation (time-only)
        seconds_since_midnight = (dt.hour * 3600 + dt.minute * 60 + dt.second + dt.microsecond / 1e6)
        return seconds_since_midnight / 86400
    
# Main Function
def main():

    # Create window
    layout = [
              [sg.Text("Define.xml", size=(17, 1)), 
               sg.InputText(key="-define-",enable_events=True, readonly=True, size=(65, 1)), 
               sg.FileBrowse(target="-define-", file_types=(("XML Files", "*.xml"),))],
              [sg.Text("SAS Datasets Library", size=(17, 1)), 
               sg.InputText(key="-library-", readonly=True, size=(65, 1)), 
               sg.FolderBrowse()],
              [sg.Text("Dataset-JSON Folder", size=(17, 1)), 
               sg.InputText(key="-folder-", readonly=True, size=(65, 1)), 
               sg.FolderBrowse()],
              [sg.Radio("SAS7BDAT", "radio_group", default=True, key="-sas-"), sg.Radio("XPT", "radio_group", default=False, key="-xpt-")],
              [sg.Submit(), sg.Cancel()]
             ]

    window = sg.Window("Dataset-JSON Creation (Beta Version 0.01)", layout)

    while True:             
        event, values = window.read()

        # Close application using X or Cancel button
        if event == sg.WIN_CLOSED or event == "Cancel":
            break

        define = values["-define-"]
        library = values["-library-"]
        folder = values["-folder-"]
        sas = values["-sas-"]
        xpt = values["-xpt-"]

        # Submit application using Submit button
        if event == "Submit":

            # Popup error window when required fields are not filled out
            if any((define == "", library == "", folder == "")):
                sg.Popup("Please fill out required fields", title = "", button_color = "red", custom_text = " Error ", button_justification = "center")

            # Check if Dataset-JSON stylesheet exists where it should. 
            elif not (os.path.isfile(os.path.join(path,"Stylesheet\\Dataset-JSON.xsl"))):
                sg.Popup("Stylesheet Dataset-JSON.xsl file not found. Make sure it is located in a subfolder Stylesheet.", title = "", button_color = "red", custom_text = " Error ", button_justification = "center")

            # Check if Dataset-JSON schema exists where it should. 
            elif not (os.path.isfile(os.path.join(path,"Schema\\dataset.schema.json"))):
                sg.Popup("Schema dataset.schema.json file not found. Make sure it is located in a subfolder Schema.", title = "", button_color = "red", custom_text = " Error ", button_justification = "center")

            # Create Dataset-JSON files    
            else:

                # Load Dataset-JSON Schema
                with open(os.path.join(path,"Schema\\dataset.schema.json")) as schemajson:
                    schema = schemajson.read()
                schema = json.loads(schema)

                # Initialize list of files either not JSON compliant with nor compliant with Dataset-JSON schema
                error_files = []
                
                # Build JSON files from SAS/XPT datasets
                files = [file for file in os.listdir(library) if file.endswith(".sas7bdat")] if sas else [file for file in os.listdir(library) if file.endswith(".xpt")] if xpt else []

                if files:
                    sg.popup_no_wait("Processing....", non_blocking=True, button_type=5, keep_on_top=True, no_titlebar=True, auto_close=True, modal=True)
                    
                    for file in files:

                        # Extract data and metadata from either SAS or XPT datasets
                        if sas:
                            df, meta = pyreadstat.read_sas7bdat(os.path.join(library,file))
                        elif xpt:
                            df, meta = pyreadstat.read_xport(os.path.join(library,file))

                        dsname = file.upper().rsplit('.', 1)[0]

                        # Extract Dataset-JSON metadata from Define.xml
                        processor = saxonche.PySaxonProcessor(license=False)
                        xslt = processor.new_xslt30_processor()
                        xslt.set_parameter("dsName", processor.make_string_value(dsname))
                        xslt.set_parameter("creationDateTime", processor.make_string_value(datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")))
                        xslt.set_parameter("nbRows", processor.make_integer_value(meta.number_rows))
                        result = xslt.transform_to_string(source_file=define, stylesheet_file=os.path.join(path,"Stylesheet\\Dataset-JSON.xsl"))
                        json_data = json.loads(result)
                        items = json_data["clinicalData"]["itemGroupData"][dsname]["items"]
                        pairs = {item["name"]: item["type"] for item in items if item["name"] != "ITEMGROUPDATASEQ"}

                        # Extract Dataset-JSON data from each SAS or XPT datasets
                        records = ''
                        if meta.number_rows > 0:
                            for index, row in df.iterrows():
                                if index > 0:
                                    records += ','
                                records += '[' + str(index + 1)
                                for column in df.columns:
                                    type = pairs[column]
                                    value = row[column]
                                    records += ','
                                    if isinstance(value, (datetime.date, datetime.datetime, datetime.time)):
                                        records += str(datetime_to_integer(value))
                                    elif type == "string":
                                        records += '"' + value +  '"' 
                                    elif type == "integer":
                                        if pd.isna(value):
                                            records += "null"
                                        else:
                                            records += str(int(value))
                                    else:
                                        if pd.isna(value):
                                            records += "null"
                                        else:
                                            records += str(value)
                                records += ']'
                        json_data["clinicalData"]["itemGroupData"][dsname]["itemData"] = json.loads("[" + records + "]")

                        # Check if JSON file is valid against the Dataset-JSON schema
                        error = False
                        try:
                            jsonschema.validate(json_data, schema)
                        except:
                            error = True

                        # Save Dataset-JSON files
                        if not error:
                            try:
                                with open(os.path.join(folder,dsname)+".json", "w") as json_file:
                                    json.dump(json_data, json_file)
                            except:
                                error = True

                        # Add the SAS or XPT files that are not compliant with either JSON or Dataset-JSON schema
                        if error:
                            error_files.append(file)

                    # Pop-up an error window listing all files that are not compliant with either JSON or Dataset-JSON schema
                    if error_files:
                        msgfiles = '\n'.join(error_files)   
                        time.sleep(3)                 
                        sg.Popup("The following JSON files are not compliant with Dataset-JSON schema:\n" + msgfiles, 
                                title = "", button_color = "red", custom_text = " Error ", button_justification = "center")
                        
                    # Pop-up when all files are compliant with Dataset-JSON standard
                    else:
                        time.sleep(3)
                        sg.Popup("Dataset-JSON files created.", title = "", button_color = "green", custom_text = "  OK  ", button_justification = "center")

                else:
                    sg.Popup("No datasets found in the selected directory. Please check.", title = "", button_color = "red", custom_text = " Error ", button_justification = "center")

if __name__ == '__main__':
    main()


