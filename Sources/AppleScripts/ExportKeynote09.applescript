on ExportKeynote09(destinationPath as POSIX file)
    tell application "Keynote"
        try
            if not (exists document 1) then error number -1702
            
            with timeout of 1200 seconds
                export front document as Keynote 09 to file destinationPath
            end timeout
        
            on error errorMessage number errorNumber
#               display alert "EXPORT PROBLEM" message errorMessage
            error number -10000
        end try
    end tell
end ExportKeynote09
