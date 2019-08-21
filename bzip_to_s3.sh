function handler () {
    # Always should be first line --> Ensures script fails if error occurs
    set -e
  
    # Event Data is sent as the first parameter
    EVENT_DATA=$1

    # Converting event into JSON Object
    EVENT_JSON=$(echo "${EVENT_DATA}" | jq '.[]')
    
    # Getting Bucket Name
    BUCKET_NAME=$(echo $EVENT_JSON | jq '.[] | .s3 | .bucket | .name')
    
    #Remove quotes from bucket name
    BUCKET="${BUCKET_NAME%\"}"      #Remove leading quotation mark
    BUCKET="${BUCKET#\"}"           #Remove trailing quotation mark
   
    #Getting FilePath
    FILE_PATH=$(echo "${EVENT_JSON}" | jq '.[] | .s3 | .object | .key')
    
    #Sub_Recipe Folder
    SUB_RECIPE=$(echo $FILE_PATH | cut -d'/' -f 2)
    SUB_RECIPE_FOLDER_NAME="${SUB_RECIPE%\"}"
    SUB_RECIPE_FOLDER_NAME="${SUB_RECIPE_FOLDER_NAME#\"}"
    
    # Zip file name to be used as upload
    ZIP_FILE="${SUB_RECIPE_FOLDER_NAME}.tar.bz2"
    
    #PATH TO PUT EVENT --> TO BE USED TO CONSTRUCT UPLOAD PATH -------------------------------------------------------
    FOLDER=$(echo $FILE_PATH | cut -d'/' -f 1)
    FOLDER_NAME="${FOLDER%\"}"      #Remove leading quotation mark
    FOLDER_NAME="${FOLDER_NAME#\"}" #Remove trailing quotation mark
    
    #Version Number (VERSION FOLDER OF RECIPE)
    VERSION=$(echo $FILE_PATH | cut -d'/' -f 3)
    VERSION_FOLDER="${VERSION%\"}"
    VERSION_FOLDER="${VERSION_FOLDER#\"}"
    
    #Path to upload (PATH WHERE EVENT OCCURS => PATH TO UPLOAD TO)
    UPLOAD_PATH="s3://$BUCKET/$FOLDER_NAME/$SUB_RECIPE_FOLDER_NAME/$VERSION_FOLDER/" # Used to download to temp dir aswell

    # Checking if file exists in the dir, if exists => exit
    # --bucket tag: Looks for file in specified bucket
    # --key: The path to where the file will be found if it exists
    
    NOT_EXIST=false
    aws s3api head-object --bucket $BUCKET --key $FOLDER_NAME/$SUB_RECIPE_FOLDER_NAME/$VERSION_FOLDER/$ZIP_FILE || NOT_EXIST=true
    if [ "$NOT_EXIST" = false ]; then
        echo FILE EXISTS, 
        exit 0;
    fi
    
    # Download folder to tmp directory using aws command    
    #aws s3 cp $UPLOAD_PATH /tmp/$SUB_RECIPE_FOLDER_NAME/$VERSION_FOLDER --recursive --exclude "*." --include "*bsc.docx" --include "*metu.pdf"
    aws s3 cp $UPLOAD_PATH /tmp/$SUB_RECIPE_FOLDER_NAME/$VERSION_FOLDER --recursive --exclude "*" --include "*.json" --include "*tft.png" --include "*tft-thumbnail.png"
    
    #change into temp dir for tar process
    cd /tmp/
    
    #Zip folder
    #zip -r $ZIP_FILE $SUB_RECIPE_FOLDER_NAME
    tar cjvf $ZIP_FILE $SUB_RECIPE_FOLDER_NAME
    
    #Upload to S3
    #aws s3 cp $ZIP_FILE "s3://wildrydes-talha-zeeshan/"
    aws s3 cp $ZIP_FILE $UPLOAD_PATH
    
    # Clean up
    rm $ZIP_FILE
    rm -r $SUB_RECIPE_FOLDER_NAME
    
    # This is the return value because it's being sent to stderr (>&2)
    echo "{\"success\": true}" >&2
    
}
