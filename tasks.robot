*** Settings ***
Documentation   
...             
...             
...             
...  
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         RPA.core.notebook          
Library         RPA.Browser.Selenium
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP

# #Steps- followed.
# Here steps followed are :
# 1. Open the website
# 2. Open a dialogbox asking for url for downloading the csv file
# 3. Use the csv file and use its each row to create the robot details in website
# 4. After dataentry operations, save the reciept in pdf file format 
# 5. Take the screenshot of Robot and add the robot to given pdf file.
# 6. Finally zip all receipts and save in output directory
# 7. Close the website


*** Variables ***
${website_robots}            https://robotsparebinindustries.com/#/robot-order

${output_folder}  ${CURDIR}${/} output

${zip_file}       ${output_folder}${/}pdf_archive.zip

*** Tasks ***
Order Processing Bot 
    Intializing steps
    
    Download csv 
    ${data}=  Read the order file
    Open the website
    Processing the orders  ${data}
    Zip the reciepts folder
    [Teardown]  Close Browser











***Keywords***
Open the website
    ${website_robots}=  Get Secret  pagedata
    Open Available Browser  ${website_robots}[website_url]
    
   




***Keywords***
Intializing steps   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}reciepts
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}robots
    Run Keyword If  '${reciept_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}reciepts  ELSE  Create Directory  ${CURDIR}${/}reciepts
    Run Keyword If  '${robots_folder}'=='True'  Remove and add empty directory  ${CURDIR}${/}robots  ELSE  Create Directory  ${CURDIR}${/}robots

# +
***Keywords***
Remove and add empty directory
    [Arguments]  ${folder}
    Remove Directory  ${folder}  True
    Create Directory  ${folder}
    
    
# -

***Keywords***
Read the order file
    [Documentation] 
    ${orders} =  Read Table From Csv  ${CURDIR}${/}orders.csv  header=True
    Return From Keyword  ${orders}


***Keywords***
Data Entry for each order
    [Arguments]  ${row}
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    Click Element  //input[@value="${row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  5 seconds
    Click Button  //button[@id="order"]
    Sleep  5 seconds


***Keywords***
Close and start Browser prior to another transaction
    Close Browser
    Open the website
    Continue For Loop

*** Keywords ***
Checking Receipt data processed or not 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 


***Keywords***
Processing Receipts in final
    [Arguments]  ${order_number} 
    Sleep  5 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}reciepts${/}${order_number}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${order_number}[Order number].png 
    Set Local Variable    ${file_path}    ${CURDIR}${/}robot_preview_image_${order_number}.png
    Add Watermark Image To Pdf  ${CURDIR}${/}robots${/}${order_number}[Order number].png  ${CURDIR}${/}reciepts${/}${order_number}[Order number].pdf  ${CURDIR}${/}reciepts${/}${order_number}[Order number].pdf 
    Click Button  //button[@id="order-another"]
    [Return]    ${file_path}

***Keywords***
Processing the orders
    [Arguments]  ${data}
    FOR  ${row}  IN  @{data}    
        Data Entry for each order  ${row}
        Checking Receipt data processed or not 
        Processing Receipts in final  ${row}      
    END  

# +
***Keywords***
Download csv 
    ${css_url}=  Get Value From User  Please enter the csv file url  https://robotsparebinindustries.com/orders.csv  
    Download  ${css_url}  orders.csv
    Sleep  3 seconds
    
    
# -


***Keywords***
Zip the reciepts folder
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}PDF_archive.zip  recursive=True  include=*.pdf  exclude=/.png
