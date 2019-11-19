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
    
    #PARSING PATH TO PUT EVENT --> TO BE USED TO CONSTRUCT UPLOAD PATH -------------------------------------------------------
    # Sub_Folder_1
    SUB_FOLDER_1=$(echo $FILE_PATH | cut -d'/' -f 1)
    SUB_FOLDER_1_NAME="${SUB_FOLDER_1%\"}"      #Remove leading quotation mark
    SUB_FOLDER_1_NAME="${SUB_FOLDER_1_NAME#\"}" #Remove trailing quotation mark
    
    #Sub_Folder_2
    SUB_FOLDER_2=$(echo $FILE_PATH | cut -d'/' -f 2)    # Parse the file path two get the sub folder name
    SUB_FOLDER_2_NAME="${SUB_FOLDER_2%\"}"              # Remove Quotation Marks
    SUB_FOLDER_2_NAME="${SUB_FOLDER_2_NAME#\"}"
   
    #Sub_Folder_3 ==> Inner most Folder ==> where event occurs
    SUB_FOLDER_3=$(echo $FILE_PATH | cut -d'/' -f 3)
    SUB_FOLDER_3_NAME="${SUB_FOLDER_3%\"}"
    SUB_FOLDER_3_NAME="${SUB_FOLDER_3_NAME#\"}"
    
     # Zip file name to be used as upload, in this case its name is the same as sub_folder_2
     ZIP_FILE="${SUB_FOLDER_2_NAME}.tar.bz2"
    
    #Path to upload (PATH WHERE EVENT OCCURS == PATH TO UPLOAD TO)
    EVENT_PATH="s3://$BUCKET/$SUB_FOLDER_1_NAME/$SUB_FOLDER_2_NAME/$SUB_FOLDER_3_NAME/" # Used to download to lambda temp dir aswell

    # Checking if file exists in the lambda temp dir, if exists => exit
    # --bucket tag: Looks for file in specified bucket
    # --key: The path to where the file will be found if it exists
    
    NOT_EXIST=false
    aws s3api head-object --bucket $BUCKET --key $SUB_FOLDER_1_NAME/$SUB_FOLDER_2_NAME/$SUB_FOLDER_3_NAME/$ZIP_FILE || NOT_EXIST=true
    if [ "$NOT_EXIST" = false ]; then
        echo FILE EXISTS, 
        exit 0;
    fi
    
    # Download folder to tmp directory using aws command (filter files to download only those required)    
    # Need to maintain hierarchy of 2nd and 3rd sub-folders hence create similar hierarchy in local temp directory in lambda and download 
    aws s3 cp $EVENT_PATH /tmp/$SUB_FOLDER_2_NAME/$SUB_FOLDER_3_NAME --recursive --exclude "*" --include " # Enter Extensions of required files "
    
    #change into lambda temp directory to access downloaded files for tar process.
    cd /tmp/
    
    #bzip folder
    tar cjvf $ZIP_FILE $SUB_FOLDER_2_NAME
    
    #Upload to S3
    aws s3 cp $ZIP_FILE $EVENT_PATH
    
    # Clean up tmp directory
    rm $ZIP_FILE
    rm -r $SUB_FOLDER_1_NAME
    
    # This is the return value because it's being sent to stderr (>&2)
    echo "{\"success\": true}" >&2
    
}
