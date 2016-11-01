property exportFormat : "PNG" -- "TIFF" "JPEG" "PNG"
property includeSkippedSlides : false
property compressionFactor : 1.0

on ExportImages(destinationPath as POSIX file)
    tell application "Keynote"
        try
            if not (exists document 1) then error number -1702
            
            -- EXPORT THE DOCUMENT
            if exportFormat is "PNG" then
                -- EXPORT THE FRONT DOCUMENT TO PNG IMAGES
                export front document as slide images to file destinationPath with properties ¬
                {image format:PNG, skipped slides:includeSkippedSlides}
                else if exportFormat is "JPEG" then
                -- EXPORT THE FRONT DOCUMENT TO JPEG IMAGES
                export front document as slide images to file destinationPath with properties ¬
                {image format:JPEG, skipped slides:includeSkippedSlides ¬
                , compression factor:compressionFactor}
                else if exportFormat is "TIFF" then
                -- EXPORT THE FRONT DOCUMENT TO TIFF IMAGES
                export front document as slide images to file destinationPath with properties ¬
                {image format:TIFF, skipped slides:includeSkippedSlides ¬
                , compression factor:compressionFactor}
            end if
            on error errorMessage number errorNumber
#            display alert "EXPORT PROBLEM" message errorMessage
            error number -10000
        end try
    end tell
    
end ExportImages
